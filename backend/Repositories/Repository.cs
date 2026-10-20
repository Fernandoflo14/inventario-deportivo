using Inventario.Api.Data;
using Inventario.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Inventario.Api.Repositories;

public interface IRepository<T> where T : class
{
    Task<List<T>> List(CancellationToken ct);
    Task<T?> Find(int id, CancellationToken ct);
    Task Add(T entity, CancellationToken ct);
    void Remove(T entity);
    Task Save(CancellationToken ct);
}

public class Repository<T>(InventoryDb db) : IRepository<T> where T : class
{
    public Task<List<T>> List(CancellationToken ct) => db.Set<T>().OrderBy(x => EF.Property<int>(x, "Id")).Take(1000).ToListAsync(ct);
    public async Task<T?> Find(int id, CancellationToken ct) => await db.Set<T>().FindAsync([id], ct);
    public async Task Add(T entity, CancellationToken ct) => await db.Set<T>().AddAsync(entity, ct);
    public void Remove(T entity) => db.Set<T>().Remove(entity);
    public Task Save(CancellationToken ct) => db.SaveChangesAsync(ct);
}

public interface IProductRepository : IRepository<Product>
{
    Task<List<Product>> ListWithCategory(CancellationToken ct);
    Task<Product?> FindWithCategory(int id, CancellationToken ct);
}

public class ProductRepository(InventoryDb db) : Repository<Product>(db), IProductRepository
{
    public Task<List<Product>> ListWithCategory(CancellationToken ct) => db.Products
        .AsNoTracking().Include(x => x.Category).OrderBy(x => x.Id).Take(1000).ToListAsync(ct);
    public Task<Product?> FindWithCategory(int id, CancellationToken ct) => db.Products
        .Include(x => x.Category).SingleOrDefaultAsync(x => x.Id == id, ct);
}
