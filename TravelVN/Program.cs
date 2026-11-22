
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using TravelVN.API.Models;
using TravelVN.Services;

var builder = WebApplication.CreateBuilder(args);

// =========================================
// JWT AUTHENTICATION
// =========================================
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,

            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],

            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(
                    builder.Configuration["Jwt:SecretKey"]
                    ?? throw new KeyNotFoundException("Missing Jwt:SecretKey")
                )
            ),

            NameClaimType = ClaimTypes.NameIdentifier,
            RoleClaimType = ClaimTypes.Role
        };
    });

// =========================================
// AUTHORIZATION
// =========================================
builder.Services.AddAuthorization();

// =========================================
// DEPENDENCY INJECTION
// =========================================
builder.Services.AddScoped<SiteProvider>();

builder.Services.AddTransient<EmailService>();

builder.Services.AddHttpClient<SocialAuthService>();

// =========================================
// MVC / CONTROLLERS
// =========================================
builder.Services.AddControllers();

// =========================================
// CORS - FLUTTER
// =========================================
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
    {
        policy
            .WithOrigins(
                "http://localhost:7357",
                "http://127.0.0.1:7357"
            )
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

// =========================================
// BUILD APPLICATION
// =========================================
var app = builder.Build();

// =========================================
// MIDDLEWARE
// =========================================
app.UseHttpsRedirection();

app.UseRouting();

app.UseCors("AllowFlutter");

app.UseStaticFiles();

app.UseAuthentication();

app.UseAuthorization();

// =========================================
// ROUTES
// =========================================
app.MapControllers();

app.MapDefaultControllerRoute();

app.Run();
