using Microsoft.AspNetCore.Mvc;
using TravelVN.API.Models;

namespace TravelVN.API.Controller;

public abstract class BaseController : ControllerBase
{
    SiteProvider? provider;
    protected SiteProvider Provider => provider ??= HttpContext.RequestServices.GetRequiredService<SiteProvider>();
}