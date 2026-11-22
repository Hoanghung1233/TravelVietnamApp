
using System.Net.Http.Json;
using System.Text.Json;
using Google.Apis.Auth;
using TravelVN.API.Models;

namespace TravelVN.Services;

public class SocialAuthService
{
    private readonly IConfiguration configuration;
    private readonly HttpClient httpClient;

    public SocialAuthService(
        IConfiguration configuration,
        HttpClient httpClient)
    {
        this.configuration = configuration;
        this.httpClient = httpClient;
    }

    // Đăng nhập Google
    public async Task<SocialUser?> GoogleLogin(string token)
    {
        try
        {
            string clientId =
                configuration["Google:ClientId"]
                ?? throw new Exception("Missing Google ClientId");

            GoogleJsonWebSignature.Payload payload =
                await GoogleJsonWebSignature.ValidateAsync(
                    token,
                    new GoogleJsonWebSignature.ValidationSettings
                    {
                        Audience = new[] { clientId }
                    });

            if (payload.EmailVerified != true)
                return null;

            return new SocialUser
            {
                ProviderUserId = payload.Subject,
                Email = payload.Email,
                GivenName = payload.GivenName ?? "",
                Surname = payload.FamilyName ?? "",
                IsEmailVerified = true,
                Avatar = payload.Picture
            };
        }
        catch
        {
            return null;
        }
    }

    // Đăng nhập Facebook
    public async Task<SocialUser?> FacebookLogin(string token)
    {
        try
        {
            string url =
                "https://graph.facebook.com/me" +
                "?fields=id,first_name,last_name,picture" +
                "&access_token=" + Uri.EscapeDataString(token);

            using HttpResponseMessage response =
                await httpClient.GetAsync(url);

            if (!response.IsSuccessStatusCode)
                return null;

            JsonDocument document =
                await response.Content.ReadFromJsonAsync<JsonDocument>()
                ?? throw new Exception("Invalid Facebook response");

            JsonElement root = document.RootElement;

            return new SocialUser
            {
                ProviderUserId = root.GetProperty("id").GetString()!,
                GivenName = root.TryGetProperty("first_name", out var first)
                    ? first.GetString() ?? ""
                    : "",
                Surname = root.TryGetProperty("last_name", out var last)
                    ? last.GetString() ?? ""
                    : "",
                IsEmailVerified = false,
                Avatar = root.TryGetProperty("picture", out var picture)
                    ? picture.GetProperty("data")
                        .GetProperty("url").GetString()
                    : null
            };
        }
        catch
        {
            return null;
        }
    }

    // Đăng nhập Zalo
    public async Task<SocialUser?> ZaloLogin(string token)
    {
        try
        {
            string url =
                "https://graph.zalo.me/v2.0/me" +
                "?fields=id,name,picture" +
                "&access_token=" + Uri.EscapeDataString(token);

            using HttpResponseMessage response =
                await httpClient.GetAsync(url);

            if (!response.IsSuccessStatusCode)
                return null;

            JsonDocument document =
                await response.Content.ReadFromJsonAsync<JsonDocument>()
                ?? throw new Exception("Invalid Zalo response");

            JsonElement root = document.RootElement;

            string name = root.TryGetProperty("name", out var nameElement)
                ? nameElement.GetString() ?? ""
                : "";

            return new SocialUser
            {
                ProviderUserId = root.GetProperty("id").GetString()!,
                GivenName = name,
                IsEmailVerified = false,
                Avatar = root.TryGetProperty("picture", out var picture)
                    ? picture.GetString()
                    : null
            };
        }
        catch
        {
            return null;
        }
    }

    // Chọn nhà cung cấp đăng nhập
    public async Task<SocialUser?> Login(
        string provider,
        string token)
    {
        return provider.ToLower() switch
        {
            "google" => await GoogleLogin(token),
            "facebook" => await FacebookLogin(token),
            "zalo" => await ZaloLogin(token),
            _ => null
        };
    }
}
