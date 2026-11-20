
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
    // Thêm đơn đặt vé mới
    [HttpPost]
    public int Add(Booking obj)
    {
        // Lấy UserId từ tài khoản đang đăng nhập
        string? userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!int.TryParse(userId, out int id))
            throw new UnauthorizedAccessException("Không xác định được người dùng.");

        obj.UserId = id;

        // Tạo mã đặt vé
        obj.BookingCode = "BK" + Guid.NewGuid().ToString("N")[..10].ToUpper();

        // Thêm đơn đặt vé vào cơ sở dữ liệu
        return Provider.Booking.Add(obj);
    }

    // Lấy danh sách đơn đặt vé của người dùng
    [HttpGet]
    public IEnumerable<Booking>? GetBookings()
    {
        string? userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (int.TryParse(userId, out int id))
            return Provider.Booking.GetBookings(id);

        return null;
    }

    // Cập nhật trạng thái đơn đặt vé
    [HttpPut("updateStatus")]
    public int UpdateStatus(Booking obj)
    {
        return Provider.Booking.UpdateStatus(
            obj.BookingId,
            obj.Status ?? string.Empty
        );
    }
}
