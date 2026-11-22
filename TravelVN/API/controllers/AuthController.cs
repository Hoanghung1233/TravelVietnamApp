
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TravelVN.API.Models;
using TravelVN.Services;

namespace TravelVN.API.Controller;

[ApiController]
[Route("api/[controller]")]
public class AuthController : BaseController
{
    private readonly IConfiguration configuration;
    private readonly EmailService emailService;
    private readonly SocialAuthService socialAuthService;

    public AuthController(
        IConfiguration configuration,
        EmailService emailService,
        SocialAuthService socialAuthService)
    {
        this.configuration = configuration;
        this.emailService = emailService;
        this.socialAuthService = socialAuthService;
    }

    // =========================================
    // 1. ĐĂNG KÝ EMAIL VÀ MẬT KHẨU
    // =========================================
    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterModel obj)
    {
        if (string.IsNullOrWhiteSpace(obj.Email) ||
            string.IsNullOrWhiteSpace(obj.Password))
            return BadRequest("Email and password are required");

        if (obj.Password.Length < 8)
            return BadRequest("Password must have at least 8 characters");

        if (Provider.Member.GetMemberByEmail(obj.Email) != null)
            return BadRequest("Email already exists");

        Member member = new Member
        {
            MemberId = Guid.NewGuid().ToString("N"),
            Surname = obj.Surname,
            GivenName = obj.GivenName,
            Email = obj.Email.Trim(),
            Password = obj.Password,
            Phone = obj.Phone,
            Role = Role.Member,
            IsEmailVerified = false
        };

        int result = Provider.Member.Add(member);

        if (result <= 0)
            return BadRequest("Register failed");

        string code = Random.Shared.Next(100000, 1000000).ToString();

        Provider.EmailOtp.InvalidateOldOtp(
            member.MemberId,
            "VerifyEmail");

        Provider.EmailOtp.Add(new EmailOtp
        {
            MemberId = member.MemberId,
            Email = member.Email,
            CodeHash = BCrypt.Net.BCrypt.HashPassword(code),
            Purpose = "VerifyEmail",
            ExpiresAt = DateTime.Now.AddMinutes(5)
        });

        await emailService.SendOtp(member.Email, code);

        return Ok(new
        {
            Success = true,
            Message = "Register successful. Please verify your email."
        });
    }

    // =========================================
    // 2. XÁC MINH EMAIL
    // =========================================
    [HttpPost("verify-email")]
    public IActionResult VerifyEmail(VerifyOtpModel obj)
    {
        Member? member = Provider.Member.GetMemberByEmail(obj.Email);

        if (member == null)
            return NotFound("Account not found");

        bool valid = Provider.EmailOtp.Verify(
            member.MemberId,
            obj.Email,
            obj.Code,
            "VerifyEmail");

        if (!valid)
            return BadRequest("OTP invalid or expired");

        Provider.Member.VerifyEmail(member.MemberId);

        return Ok(new
        {
            Success = true,
            Message = "Email verified successfully"
        });
    }

    // =========================================
    // 3. ĐĂNG NHẬP EMAIL VÀ MẬT KHẨU
    // =========================================
    [HttpPost("login")]
    public IActionResult Login(LoginModel obj)
    {
        LoginResult result = Provider.Member.Login(
            obj,
            configuration);

        if (!result.Success)
            return BadRequest(result);

        return Ok(result);
    }

    // =========================================
    // 4. ĐĂNG NHẬP GOOGLE / FACEBOOK / ZALO
    // =========================================
    [HttpPost("social-login")]
    public async Task<IActionResult> SocialLogin(
        SocialLoginModel obj)
    {
        SocialUser? user = await socialAuthService.Login(
            obj.Provider,
            obj.AccessToken);

        if (user == null)
            return Unauthorized("Invalid social token");

        Member member = new Member
        {
            Surname = user.Surname,
            GivenName = user.GivenName,
            Email = user.IsEmailVerified ? user.Email : null,
            Avatar = user.Avatar,
            IsEmailVerified = user.IsEmailVerified,
            Role = Role.Member
        };

        LoginResult result = Provider.Member.SocialLogin(
            member,
            obj.Provider,
            user.ProviderUserId,
            configuration);

        if (!result.Success)
            return Conflict(result);

        return Ok(result);
    }

    // =========================================
    // 5. GỬI OTP QUÊN MẬT KHẨU
    // =========================================
    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword(
        SendOtpModel obj)
    {
        Member? member = Provider.Member.GetMemberByEmail(obj.Email);

        if (member == null || !member.IsEmailVerified)
        {
            // Không tiết lộ email có tồn tại hay không
            return Ok(new
            {
                Success = true,
                Message = "If the account exists, an OTP will be sent."
            });
        }

        string code = Random.Shared.Next(100000, 1000000).ToString();

        Provider.EmailOtp.InvalidateOldOtp(
            member.MemberId,
            "ResetPassword");

        Provider.EmailOtp.Add(new EmailOtp
        {
            MemberId = member.MemberId,
            Email = obj.Email,
            CodeHash = BCrypt.Net.BCrypt.HashPassword(code),
            Purpose = "ResetPassword",
            ExpiresAt = DateTime.Now.AddMinutes(5)
        });

        await emailService.SendOtp(obj.Email, code);

        return Ok(new
        {
            Success = true,
            Message = "OTP sent successfully"
        });
    }

    // =========================================
    // 6. ĐẶT LẠI MẬT KHẨU
    // =========================================
    [HttpPost("reset-password")]
    public IActionResult ResetPassword(
        ResetPasswordModel obj)
    {
        if (obj.NewPassword.Length < 8)
            return BadRequest("Password must have at least 8 characters");

        Member? member = Provider.Member.GetMemberByEmail(obj.Email);

        if (member == null)
            return BadRequest("Invalid request");

        bool valid = Provider.EmailOtp.Verify(
            member.MemberId,
            obj.Email,
            obj.Code,
            "ResetPassword");

        if (!valid)
            return BadRequest("OTP invalid or expired");

        int result = Provider.Member.ResetPassword(
            obj.Email,
            obj.NewPassword);

        if (result <= 0)
            return BadRequest("Reset password failed");

        return Ok(new
        {
            Success = true,
            Message = "Password reset successfully"
        });
    }

    // =========================================
    // 7. ĐỔI MẬT KHẨU
    // =========================================
    [Authorize(Roles = "Admin,Member")]
    [HttpPost("change-password")]
    public IActionResult ChangePassword(
        UpdatePasswordModel obj)
    {
        string memberId = User.FindFirst(
            System.Security.Claims.ClaimTypes.NameIdentifier)?.Value!;

        ChangePasswordModel model = new ChangePasswordModel
        {
            CurrentPassword = obj.CurrentPassword,
            NewPassword = obj.NewPassword
        };

        int result = Provider.Member.ChangePassword(
            memberId,
            model);

        if (result == -1)
            return BadRequest("Current password is incorrect");

        if (result == 0)
            return BadRequest("Account not found or password is not set");

        return Ok("Password changed successfully");
    }

    // =========================================
    // 8. THIẾT LẬP MẬT KHẨU LẦN ĐẦU
    // =========================================
    [Authorize(Roles = "Admin,Member")]
    [HttpPost("set-password")]
    public IActionResult SetPassword(SetPasswordModel obj)
    {
        if (obj.NewPassword.Length < 8)
            return BadRequest("Password must have at least 8 characters");

        string memberId = User.FindFirst(
            System.Security.Claims.ClaimTypes.NameIdentifier)?.Value!;

        int result = Provider.Member.SetPassword(
            memberId,
            obj.NewPassword);

        if (result <= 0)
            return BadRequest("Password already exists or account not found");

        return Ok("Password set successfully");
    }

    // =========================================
    // 9. GỬI OTP THÊM EMAIL CHO TÀI KHOẢN
    // =========================================
    [Authorize(Roles = "Admin,Member")]
    [HttpPost("send-email-verification")]
    public async Task<IActionResult> SendEmailVerification(
        UpdateEmailModel obj)
    {
        string memberId = User.FindFirst(
            System.Security.Claims.ClaimTypes.NameIdentifier)?.Value!;

        Member? member = Provider.Member.GetMemberById(memberId);

        if (member == null)
            return NotFound("Account not found");

        if (string.IsNullOrWhiteSpace(obj.Email))
            return BadRequest("Email is required");

        Member? existing = Provider.Member.GetMemberByEmail(obj.Email);

        if (existing != null && existing.MemberId != memberId)
            return Conflict("Email already belongs to another account");

        string code = Random.Shared.Next(100000, 1000000).ToString();

        Provider.EmailOtp.InvalidateOldOtp(
            memberId,
            "VerifyEmail");

        Provider.EmailOtp.Add(new EmailOtp
        {
            MemberId = memberId,
            Email = obj.Email,
            CodeHash = BCrypt.Net.BCrypt.HashPassword(code),
            Purpose = "VerifyEmail",
            ExpiresAt = DateTime.Now.AddMinutes(5)
        });

        await emailService.SendOtp(obj.Email, code);

        return Ok("OTP sent successfully");
    }

    // =========================================
    // 10. XÁC MINH VÀ CẬP NHẬT EMAIL
    // =========================================
    [Authorize(Roles = "Admin,Member")]
    [HttpPost("verify-new-email")]
    public IActionResult VerifyNewEmail(VerifyOtpModel obj)
    {
        string memberId = User.FindFirst(
            System.Security.Claims.ClaimTypes.NameIdentifier)?.Value!;

        Member? existing = Provider.Member.GetMemberByEmail(obj.Email);

        if (existing != null && existing.MemberId != memberId)
            return Conflict("Email already belongs to another account");

        bool valid = Provider.EmailOtp.Verify(
            memberId,
            obj.Email,
            obj.Code,
            "VerifyEmail");

        if (!valid)
            return BadRequest("OTP invalid or expired");

        int result = Provider.Member.UpdateVerifiedEmail(
            memberId,
            obj.Email);

        if (result <= 0)
            return BadRequest("Update email failed");

        return Ok("Email updated successfully");
    }

    // =========================================
    // 11. ĐĂNG XUẤT
    // =========================================
    [Authorize(Roles = "Admin,Member")]
    [HttpPost("logout")]
    public IActionResult Logout()
    {
        // JWT hiện tại là stateless.
        // Flutter cần xóa token lưu trên thiết bị.
        return Ok(new
        {
            Success = true,
            Message = "Logout successful. Please remove token on client."
        });
    }
}