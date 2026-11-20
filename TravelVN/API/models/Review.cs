
namespace TravelVN.API.Models;

public class Review
{
    public int ReviewId { get; set; }

    public string MemberId { get; set; } = string.Empty;

    public int DestinationId { get; set; }

    public int Rating { get; set; }

    public string? Comment { get; set; }

    public DateTime CreatedAt { get; set; }
}
