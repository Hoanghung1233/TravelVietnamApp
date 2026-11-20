namespace TravelVN.API.Models;

public class Member
{
    public string MemberId { get; set; } = null!;

    public string Surname { get; set; } = null!;

    public string GivenName { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string Password { get; set; } = null!;

    public string? Phone { get; set; }

    public string? Avatar { get; set; }

    public Role Role { get; set; }

    public DateTime CreatedAt { get; set; }
}