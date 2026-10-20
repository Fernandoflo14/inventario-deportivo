using Inventario.Api.Data;
using Inventario.Api.Repositories;
using Microsoft.EntityFrameworkCore;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddProblemDetails();
builder.Services.AddDbContext<InventoryDb>(options => options.UseNpgsql(
    builder.Configuration.GetConnectionString("Inventory") ?? throw new InvalidOperationException("Falta ConnectionStrings__Inventory.")));
builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
builder.Services.AddScoped<IProductRepository, ProductRepository>();
var app = builder.Build();
app.UseExceptionHandler();
app.Use(async (context, next) =>
{
    var requestId = context.Request.Headers["X-Request-ID"].FirstOrDefault() ?? context.TraceIdentifier;
    context.Response.Headers["X-Request-ID"] = requestId;
    using var scope = app.Logger.BeginScope(new Dictionary<string, object> { ["RequestId"] = requestId });
    try { await next(context); }
    catch (DbUpdateException e) when (e.InnerException is PostgresException pg &&
        (pg.SqlState == PostgresErrorCodes.UniqueViolation || pg.SqlState == PostgresErrorCodes.ForeignKeyViolation))
    {
        context.Response.StatusCode = StatusCodes.Status409Conflict;
        await context.Response.WriteAsJsonAsync(new { error = "Registro duplicado o relacionado con otros datos.", requestId });
    }
});
app.UseSwagger();
app.UseSwaggerUI();
app.MapGet("/", () => Results.Redirect("/swagger"));
app.MapGet("/health", async Task<IResult> (InventoryDb db, CancellationToken ct) =>
{
    try
    {
        return await db.Database.CanConnectAsync(ct)
            ? Results.Ok(new { status = "healthy", service = "inventory-api" })
            : Results.StatusCode(503);
    }
    catch { return Results.StatusCode(503); }
});
app.MapControllers();
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<InventoryDb>();
    await db.Database.EnsureCreatedAsync();
}
app.Run();
