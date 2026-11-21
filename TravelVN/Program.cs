
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using TravelVN.API.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddAuthentication(p =>
{
    p.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    p.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(p =>
{
    p.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateIssuerSigningKey = true,
        ValidateLifetime = true,
        ValidAudience = builder.Configuration["Jwt:Audience"],
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.ASCII.GetBytes(builder.Configuration["Jwt:SecretKey"]
            ?? throw new KeyNotFoundException("Jwt:SecretKey"))
        )
    };
});

builder.Services.AddAuthorization();
builder.Services.AddScoped<SiteProvider>();
builder.Services.AddMvc();
builder.Services.AddCors(options => options.AddPolicy("FlutterLocal", policy =>
    policy.WithOrigins("http://localhost:7357", "http://127.0.0.1:7357")
        .AllowAnyHeader().AllowAnyMethod()));
var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseCors("FlutterLocal");
}

app.UseStaticFiles();
app.UseAuthentication();
app.UseAuthorization();

app.MapDefaultControllerRoute();

app.Run();
