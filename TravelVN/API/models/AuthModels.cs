
namespace TravelVN.API.Models;

// Đăng ký
public class RegisterModel
{
    public string Surname { get; set; } = null!;
    public string GivenName { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string Password { get; set; } = null!;
    public string? Phone { get; set; }
}

// Xác minh OTP
public class VerifyOtpModel
{
    public string Email { get; set; } = null!;
    public string Code { get; set; } = null!;
}

// Gửi OTP
public class SendOtpModel
{
    public string Email { get; set; } = null!;
}

// Đặt lại mật khẩu
public class ResetPasswordModel
{
    public string Email { get; set; } = null!;
    public string Code { get; set; } = null!;
    public string NewPassword { get; set; } = null!;
}

// Đăng nhập mạng xã hội
public class SocialLoginModel
{
    public string Provider { get; set; } = null!;
    public string AccessToken { get; set; } = null!;
}

// Thiết lập mật khẩu lần đầu
public class SetPasswordModel
{
    public string NewPassword { get; set; } = null!;
}

// Cập nhật email
public class UpdateEmailModel
{
    public string Email { get; set; } = null!;
}

// Cập nhật mật khẩu
public class UpdatePasswordModel
{
    public string CurrentPassword { get; set; } = null!;
    public string NewPassword { get; set; } = null!;
}

// Kết quả xác thực mạng xã hội
public class SocialUser
{
    public string ProviderUserId { get; set; } = null!;
    public string GivenName { get; set; } = "";
    public string Surname { get; set; } = "";
    public string? Email { get; set; }
    public bool IsEmailVerified { get; set; }
    public string? Avatar { get; set; }
}
