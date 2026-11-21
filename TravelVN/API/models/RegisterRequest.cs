using System.ComponentModel.DataAnnotations;

namespace TravelVN.API.Models;
public sealed class RegisterRequest
{
    [Required, StringLength(60)]
    public string Surname { get; set; } = null!;
    [Required, StringLength(30)]
    public string GivenName { get; set; } = null!;
    [Required, EmailAddress, StringLength(150)]
    public string Email { get; set; } = null!;
    [Required]
    public string Password { get; set; } = null!;
    [StringLength(15)]
    public string? Phone { get; set; }
    [StringLength(255)]
    public string? Avatar { get; set; }
}
