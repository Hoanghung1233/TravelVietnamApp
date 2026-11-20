namespace TravelVN.API.Models;

public class Category
{
    public int CategoryId { get; set; }

    public string CategoryName { get; set; } = null!;

    public string? Description { get; set; }

    public string? Image { get; set; }
}