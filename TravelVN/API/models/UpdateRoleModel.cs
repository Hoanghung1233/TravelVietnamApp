
namespace TravelVN.API.Models;

public class UpdateRoleModel
{
    public string MemberId { get; set; } = null!;

    public Role Role { get; set; }
}
