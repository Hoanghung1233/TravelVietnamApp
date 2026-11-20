using System.ComponentModel.DataAnnotations;
namespace TravelVN.API.Models;
public class Favorite
{
    public int FavoriteId { get; set; }
    public int DestinationId { get; set; }
    public DateTime CreatedAt { get; set; }
}
public sealed class FavoriteDestination : Favorite
{
    public int CategoryId { get; set; }
    public string Name { get; set; } = null!;
    public string Province { get; set; } = null!;
    public string? ShortDescription { get; set; }
    public string? Image { get; set; }
    public decimal TicketPrice { get; set; }
}
public sealed class AddFavoriteRequest
{
    [Range(1, int.MaxValue)]
    public int DestinationId { get; set; }
}
