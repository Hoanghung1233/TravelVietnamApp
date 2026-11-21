using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TravelVN.API.Controller;
using TravelVN.API.models;

namespace TravelVN.API.controllers;

[Authorize]
[ApiController, Route("api/[controller]")]
public class BookingController : BaseController
{
    [HttpPost]
    public ActionResult<int> Add(Booking obj)
    {
        string? memberId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(memberId))
            return Unauthorized();

        obj.MemberId = memberId;
        obj.BookingCode = "BK" + Guid.NewGuid().ToString("N")[..10].ToUpper();

        return Ok(Provider.Booking.Add(obj));
    }

    [HttpGet]
    public ActionResult<IEnumerable<Booking>> GetBookings()
    {
        string? memberId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(memberId))
            return Unauthorized();

        return Ok(Provider.Booking.GetBookings(memberId));
    }

    [HttpGet("search")]
    public ActionResult<IEnumerable<Booking>> SearchBookings([FromQuery] string? keyword)
    {
        string? memberId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(memberId))
            return Unauthorized();

        if (string.IsNullOrWhiteSpace(keyword))
            return BadRequest("Vui lòng nhập từ khóa tìm kiếm.");

        return Ok(Provider.Booking.SearchBookings(memberId, keyword.Trim()));
    }

    [HttpGet("{id:int}")]
    public ActionResult<Booking> GetBooking(int id)
    {
        string? memberId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(memberId))
            return Unauthorized();

        Booking? booking = Provider.Booking.GetBooking(id, memberId);
        if (booking == null)
            return NotFound();

        return Ok(booking);
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("admin")]
    public ActionResult<IEnumerable<Booking>> GetAllBookings()
    {
        return Ok(Provider.Booking.GetAllBookings());
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("admin/search")]
    public ActionResult<IEnumerable<Booking>> SearchAllBookings(
        [FromQuery] string? keyword,
        [FromQuery] string? status,
        [FromQuery] string? paymentStatus)
    {
        if (string.IsNullOrWhiteSpace(keyword) &&
            string.IsNullOrWhiteSpace(status) &&
            string.IsNullOrWhiteSpace(paymentStatus))
            return BadRequest("Vui lòng nhập ít nhất một điều kiện tìm kiếm.");

        return Ok(Provider.Booking.SearchAllBookings(
            keyword?.Trim(), status?.Trim(), paymentStatus?.Trim()));
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("updateStatus")]
    public ActionResult<int> UpdateStatus(Booking obj)
    {
        if (obj.BookingId <= 0)
            return BadRequest("BookingId không hợp lệ.");

        if (string.IsNullOrWhiteSpace(obj.Status) || obj.Status.Trim().Length > 20)
            return BadRequest("Trạng thái không hợp lệ.");

        int result = Provider.Booking.UpdateStatus(obj.BookingId, obj.Status.Trim());
        if (result == 0)
            return NotFound();

        return Ok(result);
    }
}
