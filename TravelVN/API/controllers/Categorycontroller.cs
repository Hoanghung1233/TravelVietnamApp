using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
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
    public ActionResult<int> Delete(int id)
    {
        try
        {
            int deleted = Provider.Category.Delete(id);
            return deleted == 0 ? NotFound() : Ok(deleted);
        }
        catch (SqlException exception) when (exception.Number == 547)
        {
            return Conflict("Danh mục còn địa điểm. Hãy chuyển các địa điểm sang danh mục khác trước khi xóa.");
        }
    }
}