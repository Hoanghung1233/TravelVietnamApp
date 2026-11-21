
using System.ComponentModel.DataAnnotations;

namespace TravelVN.API.Models;

public class UpdateReviewRequest
{
    [Range(1, 5,
        ErrorMessage = "Rating phải từ 1 đến 5")]
    public int Rating { get; set; }

    public string? Comment { get; set; }
}
