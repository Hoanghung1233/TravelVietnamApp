
using System.ComponentModel.DataAnnotations;

namespace TravelVN.API.Models;

public class CreateReviewRequest
{
    [Range(1, int.MaxValue,
        ErrorMessage = "DestinationId phải lớn hơn 0")]
    public int DestinationId { get; set; }

    [Range(1, 5,
        ErrorMessage = "Rating phải từ 1 đến 5")]
    public int Rating { get; set; }

    public string? Comment { get; set; }
}
