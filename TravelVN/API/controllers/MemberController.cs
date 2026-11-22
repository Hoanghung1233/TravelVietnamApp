
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TravelVN.API.Models;

namespace TravelVN.API.Controller;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin,Member")]
public class MemberController : BaseController
{
    // =========================================
    // LẤY THÔNG TIN MEMBER ĐANG ĐĂNG NHẬP
    // Admin và Member
    // =========================================
    [HttpGet("profile")]
    public IActionResult GetProfile()
    {
        string? memberId = User.FindFirst(
            ClaimTypes.NameIdentifier)?.Value;

        if (string.IsNullOrEmpty(memberId))
            return Unauthorized();

        Member? member = Provider.Member.GetMemberById(memberId);

        if (member == null)
            return NotFound("Member not found");

        return Ok(member);
    }

    // =========================================
    // CẬP NHẬT THÔNG TIN CÁ NHÂN
    // Admin và Member
    // =========================================
    [HttpPut("profile")]
    public IActionResult UpdateProfile(Member obj)
    {
        string? memberId = User.FindFirst(
            ClaimTypes.NameIdentifier)?.Value;

        if (string.IsNullOrEmpty(memberId))
            return Unauthorized();

        Member? existing = Provider.Member.GetMemberById(memberId);

        if (existing == null)
            return NotFound("Member not found");

        // Không cho người dùng thay đổi MemberId,
        // Role, Email hoặc Password thông qua API này.
        existing.Surname = obj.Surname;
        existing.GivenName = obj.GivenName;
        existing.Phone = obj.Phone;
        existing.Avatar = obj.Avatar;

        int result = Provider.Member.EditMember(existing);

        if (result <= 0)
            return BadRequest("Update profile failed");

        return Ok("Profile updated successfully");
    }
}
