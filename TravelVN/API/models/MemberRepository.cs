using System.Data;
using Dapper;
using TravelVN.Services;

namespace TravelVN.API.Models;

public class MemberRepository : BaseRepository
{
    public MemberRepository(IDbConnection connection) : base(connection)
    {
    }
    public int Add(Member obj)
    {
        if (string.IsNullOrEmpty(obj.MemberId))
        {
            obj.MemberId = Guid.NewGuid().ToString().Replace("-", string.Empty);
        }
        obj.Password = BCrypt.Net.BCrypt.HashPassword(obj.Password);
        return connection.Execute("AddMember", obj, commandType: CommandType.StoredProcedure);
    }
    public Member? GetMemberByEmail(string email)
    {
        string sql = "SELECT * FROM Member WHERE Email = @Email";
        return connection.QuerySingleOrDefault<Member>(sql, new { email }
        );
    }
    public LoginResult Login(LoginModel obj, IConfiguration configuration)
    {
        Member? member = GetMemberByEmail(obj.Email);
        if (member != null)
        {
            if (BCrypt.Net.BCrypt.Verify(obj.Password, member.Password))
            {
                return new LoginResult
                {
                    Success = true,
                    Message = "Login Success",
                    Token = Helper.GenerateToken(member, configuration)
                };
            }
            return new LoginResult
            {
                Success = false,
                Message = "Password Invalid"
            };
        }
        return new LoginResult
        {
            Success = false,
            Message = "Email Invalid"
        };
    }
}