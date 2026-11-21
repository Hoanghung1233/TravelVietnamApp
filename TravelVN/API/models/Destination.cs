namespace TravelVN.API.Models;

public class Destination
{
    public int DestinationId { get; set; }
    public int CategoryId { get; set; }
    public string Name { get; set; } = "";
    public string Province { get; set; } = "";
    public string? Address { get; set; }
    public string? ShortDescription { get; set; }
    public string? Description { get; set; }
    public string? Image { get; set; }
    public string? Gallery { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public decimal TicketPrice { get; set; }
    public string? OpeningHours { get; set; }
    public DateTime CreatedAt { get; set; }
}
