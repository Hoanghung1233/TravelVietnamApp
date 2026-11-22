using System.Net.Mail;
using System.Security.Cryptography;
using Microsoft.Data.SqlClient;
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
        string email = obj.Email?.Trim() ?? "";
        if (!MailAddress.TryCreate(email, out var address) ||
            address.Address != email || email.Length > 150 ||
            string.IsNullOrWhiteSpace(obj.Password) || obj.Password.Length < 8 ||
            System.Text.Encoding.UTF8.GetByteCount(obj.Password) > 72)
            return BadRequest(new { message = "Nhập email hợp lệ và mật khẩu từ 8 ký tự, tối đa 72 byte UTF-8." });

        if (!emailService.CanSendOtp)
            return StatusCode(503, new { message = "Máy chủ chưa cấu hình gửi mã OTP." });

        var member = Provider.Member.GetMemberByEmail(email);
        if (member is null)
        {
            member = new Member
            {
                MemberId = Guid.NewGuid().ToString("N"),
                Surname = obj.Surname,
                GivenName = obj.GivenName,
                Email = email,
                Password = obj.Password,
                Phone = obj.Phone,
                Role = Role.Member,
                IsEmailVerified = false
            };

            try
            {
                if (Provider.Member.Add(member) <= 0)
                    return BadRequest(new { message = "Không thể tạo tài khoản." });
            }
            catch (SqlException exception) when (exception.Number is 2601 or 2627)
            {
                return Conflict(new { message = "Email đã được đăng ký. Vui lòng thử lại." });
            }
        }
        else if (member.IsEmailVerified || member.Role != Role.Member ||
                 string.IsNullOrEmpty(member.Password) ||
                 !BCrypt.Net.BCrypt.Verify(obj.Password, member.Password))
        {
            return Conflict(new { message = "Email đã được đăng ký. Kiểm tra mật khẩu hoặc dùng Quên mật khẩu." });
        }

        string memberId = member.MemberId ?? throw new InvalidOperationException("Missing member ID.");
        string code = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
        Provider.EmailOtp.InvalidateOldOtp(memberId, "VerifyEmail");
        Provider.EmailOtp.Add(new EmailOtp
        {
            MemberId = memberId,
            Email = email,
            CodeHash = BCrypt.Net.BCrypt.HashPassword(code),
            Purpose = "VerifyEmail",
            ExpiresAt = DateTime.Now.AddMinutes(5)
        });

        try
        {
            await emailService.SendOtp(email, code);
        }
        catch (SmtpException)
        {
            return StatusCode(503, new { message = "Chưa gửi được mã OTP. Hãy thử đăng ký lại với cùng email và mật khẩu." });
        }

        return Ok(new
        {
            Success = true,
            Message = "Đăng ký thành công. Hãy nhập mã xác thực."
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
    public async Task<IActionResult> SocialLogin(SocialLoginModel obj)
    {
        if (string.IsNullOrWhiteSpace(obj.Provider) ||
            string.IsNullOrWhiteSpace(obj.AccessToken))
        {
            return BadRequest("Provider and token are required");
        }

        string provider = obj.Provider.Trim().ToLowerInvariant();

        if (provider != "google")
        {
            return BadRequest("Use the browser sign-in flow for Facebook or Zalo.");
        }

        SocialUser? user = await socialAuthService.Login(
            provider,
            obj.AccessToken);

        if (user == null)
            return Unauthorized("Invalid social token");

        var result = SignInSocial(provider, user);
        return result.Success ? Ok(result) : Conflict(result);
    }

    [AllowAnonymous]
    [HttpPost("oauth/{provider}/start")]
    public IActionResult StartBrowserLogin(string provider, [FromServices] SocialBrowserLogin browser)
    {
        Response.Headers.CacheControl = "no-store";
        if (!SocialBrowserLogin.Supports(provider)) return NotFound();
        var settings = browser.Settings(provider);
        if (settings is null)
            return StatusCode(503, new { message = $"Máy chủ chưa cấu hình đăng nhập {provider}." });

        var (url, key) = browser.Begin(settings);
        return Ok(new { authorizationUrl = url, attemptKey = key });
    }

    [AllowAnonymous]
    [HttpGet("oauth/{provider}/callback")]
    public async Task<IActionResult> BrowserLoginCallback(
        string provider, string? code, string? state, string? error,
        [FromServices] SocialBrowserLogin browser,
        [FromServices] IHttpClientFactory clients,
        [FromServices] ILogger<AuthController> logger)
    {
        Response.Headers.CacheControl = "no-store";
        Response.Headers["Referrer-Policy"] = "no-referrer";
        if (state is null || browser.TakeCallback(provider, state) is not { } attempt)
            return BadRequest("Phiên đăng nhập không hợp lệ hoặc đã hết hạn.");

        var login = new LoginResult { Message = "Đăng nhập bị hủy hoặc không được xác nhận." };
        if (string.IsNullOrEmpty(error) && !string.IsNullOrEmpty(code))
        {
            try
            {
                string? token = await browser.ExchangeAsync(
                    clients.CreateClient("SocialOAuthExchange"), attempt, code, HttpContext.RequestAborted);
                if (token is not null &&
                    await socialAuthService.Login(provider, token, attempt.Provider.ClientId) is { } user)
                    login = SignInSocial(provider, user);
            }
            catch (Exception ex)
            {
                logger.LogWarning("Social sign-in failed for {Provider}: {ErrorType}", provider, ex.GetType().Name);
                login.Message = "Không thể hoàn tất đăng nhập. Vui lòng thử lại.";
            }
        }

        SocialBrowserLogin.Complete(attempt, login);
        return Content(login.Success
            ? "Đăng nhập thành công. Bạn có thể đóng tab này và quay về TravelVN."
            : "Không hoàn tất đăng nhập. Hãy quay lại TravelVN.", "text/plain; charset=utf-8");
    }

    [AllowAnonymous]
    [HttpPost("oauth/result")]
    public IActionResult BrowserLoginResult(
        [FromBody] BrowserLoginRequest request, [FromServices] SocialBrowserLogin browser)
    {
        Response.Headers.CacheControl = "no-store";
        if (!browser.Poll(request.AttemptKey, out var result))
            return NotFound(new { message = "Phiên đăng nhập đã hết hạn. Vui lòng thử lại." });
        return result is null ? Accepted() : Ok(result);
    }

    public sealed record BrowserLoginRequest(string AttemptKey);

    private LoginResult SignInSocial(string provider, SocialUser user)
    {
        var member = new Member
        {
            Surname = user.Surname,
            GivenName = user.GivenName,
            Email = user.IsEmailVerified ? user.Email : null,
            Avatar = user.Avatar,
            IsEmailVerified = user.IsEmailVerified,
            Role = Role.Member
        };
        var providerName = provider switch
        {
            "google" => "Google",
            "facebook" => "Facebook",
            _ => "Zalo"
        };
        return Provider.Member.SocialLogin(member, providerName, user.ProviderUserId, configuration);
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

        string code = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();

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

        string code = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();

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