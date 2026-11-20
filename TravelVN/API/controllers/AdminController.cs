
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using TravelVN.API.Models;

namespace TravelVN.API.Controller;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class AdminController : BaseController
{
    // =========================================
    // LẤY DANH SÁCH MEMBER
    // Chỉ Admin
    // =========================================
    [HttpGet("members")]
    public IActionResult GetMembers()
    {
        return Ok(Provider.Member.GetMembers());
    }

    // =========================================
    // XEM CHI TIẾT MỘT MEMBER
    // Chỉ Admin
    // =========================================
    [HttpGet("members/{id}")]
    public IActionResult GetMember(string id)
    {
        Member? member = Provider.Member.GetMemberById(id);

        if (member == null)
            return NotFound("Member not found");

        return Ok(member);
    }

    // =========================================
    // PHÂN QUYỀN MEMBER / ADMIN
    // Chỉ Admin
    // =========================================
    [HttpPut("update-role")]
    public IActionResult UpdateRole(UpdateRoleModel obj)
    {
        if (string.IsNullOrWhiteSpace(obj.MemberId))
            return BadRequest("MemberId is required");

        if (obj.Role != Role.Admin && obj.Role != Role.Member)
            return BadRequest("Invalid role");

        string? currentAdminId = User.FindFirst(
            ClaimTypes.NameIdentifier)?.Value;

        // Không cho Admin tự hạ quyền của chính mình
        if (currentAdminId == obj.MemberId &&
            obj.Role == Role.Member)
        {
            return BadRequest(
                "You cannot remove your own Admin role");
        }

        Member? member = Provider.Member.GetMemberById(obj.MemberId);

        if (member == null)
            return NotFound("Member not found");

        int result = Provider.Member.UpdateRole(
            new Member
            {
                MemberId = obj.MemberId,
                Role = obj.Role
            });

        if (result <= 0)
            return BadRequest("Update role failed");

        return Ok(new
        {
            Success = true,
            Message = "Role updated successfully",
            MemberId = obj.MemberId,
            Role = obj.Role.ToString()
        });
    }
}
