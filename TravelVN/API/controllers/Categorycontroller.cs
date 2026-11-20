using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TravelVN.API.Models;

namespace TravelVN.API.Controller;

[ApiController, Route("api/[controller]")]
public class CategoryController : BaseController
{
    [AllowAnonymous]
    [HttpGet]
    public IEnumerable<Category> GetCategories()
    {
        return Provider.Category.GetCategories();
    }
    [AllowAnonymous]
    [HttpGet("{id}")]
    public Category? GetCategory(int id)
    {
        return Provider.Category.GetCategory(id);
    }
    [Authorize(Roles = "Admin")]
    [HttpPut]
    public int Edit(Category obj)
    {
        return Provider.Category.Edit(obj);
    }
    [Authorize(Roles = "Admin")]
    [HttpPost]
    public int Add(Category obj)
    {
        return Provider.Category.Add(obj);
    }
    [Authorize(Roles = "Admin")]
    [HttpDelete("{id}")]
    public int Delete(int id)
    {
        return Provider.Category.Delete(id);
    }
}