
namespace TravelVN.API.Models;

public class Member
{
    public string? MemberId { get; set; }

    public string? Surname { get; set; } = null!;

    public string? GivenName { get; set; } = null!;

    public string? Email { get; set; }

    public string? Password { get; set; }

    public string? Phone { get; set; }

    public string? Avatar { get; set; }

    public Role Role { get; set; }

    public bool IsEmailVerified { get; set; }

    public DateTime? CreatedAt { get; set; }
}
