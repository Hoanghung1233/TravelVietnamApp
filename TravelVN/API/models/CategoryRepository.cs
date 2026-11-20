using System.Data;
using Dapper;
using TravelVN.API.Models;

namespace TravelVN.API.Models;

public class CategoryRepository : BaseRepository
{
    public CategoryRepository(IDbConnection connection) : base(connection)
    {
    }
    public IEnumerable<Category> GetCategories()
    {
        string sql = "SELECT * FROM Category";
        return connection.Query<Category>(sql);
    }
    public Category? GetCategory(int id)
    {
        string sql = "SELECT * FROM Category WHERE CategoryId = @Id";
        return connection.QuerySingleOrDefault<Category>(sql, new { id });
    }
    public int Add(Category obj)
    {
        string sql = "INSERT INTO Category(CategoryName,Description,Image) VALUES( @CategoryName, @Description, @Image)";
        return connection.Execute(sql, obj);
    }
    public int Edit(Category obj)
    {
        string sql = " UPDATE Category SET CategoryName = @CategoryName, Description = @Description, Image = @Image WHERE CategoryId = @CategoryId";
        return connection.Execute(sql, obj);
    }
    public int Delete(int id)
    {
        string sql = "DELETE FROM Category WHERE CategoryId = @Id";

        return connection.Execute(sql, new { Id = id });
    }
}