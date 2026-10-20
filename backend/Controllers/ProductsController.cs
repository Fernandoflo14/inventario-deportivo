using Inventario.Api.Contracts;
using Inventario.Api.Models;
using Inventario.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Inventario.Api.Controllers;

[ApiController]
[Route("api/products")]
public class ProductsController(IProductRepository products, IRepository<Category> categories) : ControllerBase
{
    private static ProductResponse Dto(Product p) => new(p.Id, p.Name, p.Sku, p.Price, p.Stock, p.CategoryId, p.Category.Name);

    [HttpGet]
    public async Task<IActionResult> List(CancellationToken ct) => Ok((await products.ListWithCategory(ct)).Select(Dto));

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Get(int id, CancellationToken ct)
    {
        var item = await products.FindWithCategory(id, ct);
        return item is null ? NotFound() : Ok(Dto(item));
    }

    [HttpPost]
    public async Task<IActionResult> Create(ProductRequest input, CancellationToken ct)
    {
        var category = await categories.Find(input.CategoryId, ct);
        if (category is null) return BadRequest(new { error = "La categoría no existe." });
        var item = new Product { Name = input.Name.Trim(), Sku = input.Sku.ToUpperInvariant(),
            Price = input.Price, Stock = input.Stock, CategoryId = category.Id, Category = category };
        await products.Add(item, ct);
        await products.Save(ct);
        return CreatedAtAction(nameof(Get), new { id = item.Id }, Dto(item));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, ProductRequest input, CancellationToken ct)
    {
        var item = await products.FindWithCategory(id, ct);
        if (item is null) return NotFound();
        var category = await categories.Find(input.CategoryId, ct);
        if (category is null) return BadRequest(new { error = "La categoría no existe." });
        item.Name = input.Name.Trim(); item.Sku = input.Sku.ToUpperInvariant();
        item.Price = input.Price; item.Stock = input.Stock; item.CategoryId = category.Id; item.Category = category;
        await products.Save(ct);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id, CancellationToken ct)
    {
        var item = await products.Find(id, ct);
        if (item is null) return NotFound();
        products.Remove(item);
        await products.Save(ct);
        return NoContent();
    }
}
