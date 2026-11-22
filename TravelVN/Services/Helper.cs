
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using TravelVN.API.Models;

namespace TravelVN.Services;

public static class Helper
{
    public static string GenerateToken(
        Member obj,
        IConfiguration configuration)
    {
        List<Claim> claims = new List<Claim>
        {
            new Claim( ClaimTypes.NameIdentifier, obj.MemberId),
            new Claim( ClaimTypes.Name, string.IsNullOrEmpty(obj.Surname) ? obj.GivenName : obj.Surname + " " + obj.GivenName),
            new Claim( ClaimTypes.GivenName, obj.GivenName),
            new Claim( ClaimTypes.Role, obj.Role.ToString())
        };
        if (!string.IsNullOrEmpty(obj.Email))
        {
            claims.Add(new Claim(ClaimTypes.Email, obj.Email));
        }
        if (!string.IsNullOrEmpty(obj.Surname))
        {
            claims.Add(new Claim(ClaimTypes.Surname, obj.Surname));
        }
        string secretKey = configuration["Jwt:SecretKey"] ?? throw new KeyNotFoundException("Missing Jwt:SecretKey");
        SymmetricSecurityKey key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        JwtSecurityToken token = new JwtSecurityToken(
            issuer: configuration["Jwt:Issuer"],
            audience: configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddDays(int.Parse(configuration["Jwt:Expires"] ?? "30")),
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256)
        );
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
