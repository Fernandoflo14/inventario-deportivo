using Inventario.Api.Contracts;
using Inventario.Api.Models;
using Inventario.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Inventario.Api.Controllers;

[ApiController]
[Route("api/categories")]
public class CategoriesController(IRepository<Category> categories) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List(CancellationToken ct) => Ok((await categories.List(ct)).Select(x => new CategoryResponse(x.Id, x.Name)));

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Get(int id, CancellationToken ct)
    {
        var item = await categories.Find(id, ct);
        return item is null ? NotFound() : Ok(new CategoryResponse(item.Id, item.Name));
    }

    [HttpPost]
    public async Task<IActionResult> Create(CategoryRequest input, CancellationToken ct)
    {
        var item = new Category { Name = input.Name.Trim() };
        await categories.Add(item, ct);
        await categories.Save(ct);
        return CreatedAtAction(nameof(Get), new { id = item.Id }, new CategoryResponse(item.Id, item.Name));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, CategoryRequest input, CancellationToken ct)
    {
        var item = await categories.Find(id, ct);
        if (item is null) return NotFound();
        item.Name = input.Name.Trim();
        await categories.Save(ct);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id, CancellationToken ct)
    {
        var item = await categories.Find(id, ct);
        if (item is null) return NotFound();
        categories.Remove(item);
        await categories.Save(ct);
        return NoContent();
    }
}
