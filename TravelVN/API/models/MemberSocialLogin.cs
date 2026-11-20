
namespace TravelVN.API.Models;

public class MemberSocialLogin
{
    public int SocialLoginId { get; set; }

    public string MemberId { get; set; } = null!;

    public string Provider { get; set; } = null!;

    public string ProviderUserId { get; set; } = null!;

    public DateTime CreatedAt { get; set; }
}
