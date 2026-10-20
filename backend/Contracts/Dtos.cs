using System.ComponentModel.DataAnnotations;

namespace Inventario.Api.Contracts;

public record CategoryRequest(
    [Required, StringLength(80, MinimumLength = 2), RegularExpression(@".*\S.*", ErrorMessage = "El nombre no puede estar vacío.")] string Name);
public record CategoryResponse(int Id, string Name);

public record ProductRequest(
    [Required, StringLength(120, MinimumLength = 2), RegularExpression(@".*\S.*")] string Name,
    [Required, StringLength(30, MinimumLength = 2), RegularExpression(@"^[A-Za-z0-9-]+$")] string Sku,
    [Range(typeof(decimal), "0", "9999999.99")] decimal Price,
    [Range(0, 1000000)] int Stock,
    [Range(1, int.MaxValue)] int CategoryId);
public record ProductResponse(int Id, string Name, string Sku, decimal Price, int Stock, int CategoryId, string CategoryName);
