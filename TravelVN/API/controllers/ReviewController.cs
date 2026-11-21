
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TravelVN.API.Models;
using Microsoft.Data.SqlClient;

namespace TravelVN.API.Controller;

[ApiController, Route("api/[controller]")]
public class ReviewController : BaseController
{
    [AllowAnonymous]
    [HttpGet]
    public IEnumerable<Review> GetReviews()
    {
        return Provider.Review.GetReviews();
    }

    [AllowAnonymous]
    [HttpGet("{id}")]
    public IActionResult GetReview(int id)
    {
        Review? obj = Provider.Review.GetReview(id);
        if (obj == null) return NotFound();
        return Ok(obj);
    }

    [AllowAnonymous]
    [HttpGet("destination/{destinationId}")]
    public IEnumerable<Review> GetReviewsByDestination(int destinationId)
    {
        return Provider.Review.GetReviewsByDestination(destinationId);
    }

    [Authorize(Roles = "Admin,Member")]
    [HttpPost]
    public IActionResult Add(CreateReviewRequest obj)
    {
        string? memberId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(memberId)) return Unauthorized();

        if (!Provider.Review.DestinationExists(obj.DestinationId))
            return BadRequest("Địa điểm không tồn tại");

        try
        {
            int id = Provider.Review.AddReview(memberId, obj);
            return Ok(new { ReviewId = id });
        }
        catch (SqlException ex) when (ex.Number == 2601 || ex.Number == 2627)
        {
            return Conflict("Bạn đã đánh giá địa điểm này rồi");
        }
    }
    [Authorize(Roles = "Admin,Member")]
    [HttpPut("{id}")]
    public IActionResult Edit(int id, UpdateReviewRequest obj)
    {
        string? memberId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(memberId)) return Unauthorized();

        int result = Provider.Review.UpdateReview(id, memberId, obj);
        if (result == 0) return NotFound();

        return Ok(result);
    }

    [Authorize(Roles = "Admin,Member")]
    [HttpDelete("{id}")]
    public IActionResult Delete(int id)
    {
        string? memberId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(memberId)) return Unauthorized();

        int result = Provider.Review.DeleteReview(id, memberId);
        if (result == 0) return NotFound();

        return Ok(result);
    }
}
