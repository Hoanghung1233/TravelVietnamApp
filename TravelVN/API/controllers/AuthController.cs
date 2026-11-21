using Microsoft.AspNetCore.Mvc;
using TravelVN.API.Models;

namespace TravelVN.API.Controller;

[ApiController, Route("api/[controller]")]
public class AuthController : BaseController
{
    [HttpPost("register")]
    public int Add(Member obj)
    {
        ModelState.Remove(nameof(obj.MemberId));
        if (ModelState.IsValid)
        {
            obj.Role = Role.Member;
            return Provider.Member.Add(obj);
        }
        return -2;
    }
    [HttpPost("login")]
    public LoginResult Login(LoginModel obj)
    {
        LoginResult result = Provider.Member.Login(obj, HttpContext.RequestServices.GetRequiredService<IConfiguration>());
        return result;
    }
}