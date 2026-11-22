
namespace TravelVN.API.Models;

public class EmailOtp
{
    public long OtpId { get; set; }

    public string MemberId { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string CodeHash { get; set; } = null!;

    public string Purpose { get; set; } = null!;

    public DateTime ExpiresAt { get; set; }

    public bool IsUsed { get; set; }

    public int Attempts { get; set; }

    public DateTime CreatedAt { get; set; }
}
