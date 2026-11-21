using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using TravelVN.API.Models;

namespace TravelVN.API.Controller;

[ApiController]
[Authorize]
[Route("api/favorites")]
public sealed class FavoritesController : BaseController
{
    private string? CurrentMemberId => User.FindFirstValue(ClaimTypes.NameIdentifier);

    [HttpGet]
    public async Task<ActionResult<IEnumerable<FavoriteDestination>>> GetFavorites()
    {
        if (CurrentMemberId is not { Length: > 0 and <= 32 } memberId)
            return Unauthorized();

        return Ok(await Provider.Favorite.GetFavoritesAsync(memberId));
    }

    [HttpGet("{destinationId:int}")]
    public async Task<IActionResult> GetStatus([Range(1, int.MaxValue)] int destinationId)
    {
        if (CurrentMemberId is not { Length: > 0 and <= 32 } memberId)
            return Unauthorized();

        bool isFavorite = await Provider.Favorite.IsFavoriteAsync(memberId, destinationId);
        return Ok(new { isFavorite });
    }

    [HttpPost]
    public async Task<ActionResult<Favorite>> Add(AddFavoriteRequest request)
    {
        if (CurrentMemberId is not { Length: > 0 and <= 32 } memberId)
            return Unauthorized();

        try
        {
            Favorite? favorite = await Provider.Favorite.AddAsync(memberId, request.DestinationId);

            if (favorite is null)
                return NotFound(new { message = "Không tìm thấy địa điểm hoặc tài khoản." });

            return StatusCode(StatusCodes.Status201Created, favorite);
        }
        catch (SqlException ex) when (ex.Number is 2601 or 2627)
        {
            return Conflict(new { message = "Địa điểm đã có trong danh sách yêu thích." });
        }
        catch (SqlException ex) when (ex.Number == 547)
        {
            return NotFound(new { message = "Không tìm thấy địa điểm hoặc tài khoản." });
        }
    }

    [HttpDelete("{destinationId:int}")]
    public async Task<IActionResult> Delete([Range(1, int.MaxValue)] int destinationId)
    {
        if (CurrentMemberId is not { Length: > 0 and <= 32 } memberId)
            return Unauthorized();

        await Provider.Favorite.DeleteAsync(memberId, destinationId);
        return NoContent();
    }
}
