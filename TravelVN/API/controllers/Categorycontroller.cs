using Microsoft.AspNetCore.Mvc;
using TravelVN.API.Models;

namespace TravelVN.API.Controller;

[ApiController, Route("api/[controller]")]
public class CategoryController : BaseController
{
    [HttpGet]
    public IEnumerable<Category> GetCategories()
    {
        return Provider.Category.GetCategories();
    }

    [HttpGet("{id}")]
    public Category? GetCategory(int id)
    {
        return Provider.Category.GetCategory(id);
    }

    [HttpPut]
    public int Edit(Category obj)
    {
        return Provider.Category.Edit(obj);
    }

    [HttpPost]
    public int Add(Category obj)
    {
        return Provider.Category.Add(obj);
    }

    [HttpDelete("{id}")]
    public int Delete(int id)
    {
        return Provider.Category.Delete(id);
    }
}