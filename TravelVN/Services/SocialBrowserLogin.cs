using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Extensions.Caching.Memory;
using TravelVN.API.Models;

namespace TravelVN.Services;

public sealed class SocialBrowserLogin(IMemoryCache cache, IConfiguration configuration)
{
    public static readonly TimeSpan Lifetime = TimeSpan.FromMinutes(5);

    public sealed record Provider(string Name, string ClientId, string Secret, string RedirectUri);
    public sealed record Attempt(Provider Provider, string Key, string Verifier)
    {
        public bool CallbackStarted { get; set; }
        public bool Consumed { get; set; }
        public LoginResult? Result { get; set; }
    }

    public static bool Supports(string provider) => provider is "google" or "facebook" or "zalo";

    public Provider? Settings(string name)
    {
        var section = configuration.GetSection($"OAuth:{name}");
        string? id = section["ClientId"];
        string? secret = section["ClientSecret"];
        string? redirect = section["RedirectUri"];
        if (string.IsNullOrWhiteSpace(id) || string.IsNullOrWhiteSpace(secret) ||
            !Uri.TryCreate(redirect, UriKind.Absolute, out var uri) ||
            (uri.Scheme != "https" && !(uri.IsLoopback && uri.Scheme == "http")))
            return null;

        return new Provider(name, id, secret, redirect!);
    }

    private static string RandomValue() =>
        WebEncoders.Base64UrlEncode(RandomNumberGenerator.GetBytes(32));

    public (string Url, string Key) Begin(Provider provider)
    {
        var state = RandomValue();
        var attempt = new Attempt(provider, RandomValue(), RandomValue());
        cache.Set(StateKey(state), attempt, Lifetime);
        cache.Set(AttemptKey(attempt.Key), attempt, Lifetime);
        var challenge = WebEncoders.Base64UrlEncode(
            SHA256.HashData(Encoding.ASCII.GetBytes(attempt.Verifier)));
        var query = new Dictionary<string, string?>
        {
            [provider.Name == "zalo" ? "app_id" : "client_id"] = provider.ClientId,
            ["redirect_uri"] = provider.RedirectUri,
            ["state"] = state
        };

        string url;
        if (provider.Name == "zalo")
        {
            url = "https://oauth.zaloapp.com/v4/permission";
            query["code_challenge"] = challenge;
        }
        else
        {
            query["response_type"] = "code";
            if (provider.Name == "google")
            {
                url = "https://accounts.google.com/o/oauth2/v2/auth";
                query["scope"] = "openid email profile";
                query["code_challenge"] = challenge;
                query["code_challenge_method"] = "S256";
            }
            else
            {
                url = "https://www.facebook.com/v27.0/dialog/oauth";
                query["scope"] = "public_profile";
            }
        }
        return (QueryHelpers.AddQueryString(url, query), attempt.Key);
    }

    public Attempt? TakeCallback(string provider, string state)
    {
        if (state.Length != 43 ||
            !cache.TryGetValue<Attempt>(StateKey(state), out var attempt) ||
            attempt is null || attempt.Provider.Name != provider)
            return null;

        lock (attempt)
        {
            if (attempt.CallbackStarted) return null;
            attempt.CallbackStarted = true;
            cache.Remove(StateKey(state));
            return attempt;
        }
    }

    public bool Poll(string key, out LoginResult? result)
    {
        result = null;
        if (key.Length != 43 ||
            !cache.TryGetValue<Attempt>(AttemptKey(key), out var attempt) ||
            attempt is null)
            return false;

        lock (attempt)
        {
            if (attempt.Consumed) return false;
            result = attempt.Result;
            if (result is not null)
            {
                attempt.Consumed = true;
                cache.Remove(AttemptKey(key));
            }
            return true;
        }
    }

    public static void Complete(Attempt attempt, LoginResult result)
    {
        lock (attempt) attempt.Result = result;
    }

    public async Task<string?> ExchangeAsync(
        HttpClient client, Attempt attempt, string code, CancellationToken cancellation)
    {
        var provider = attempt.Provider;
        var values = new Dictionary<string, string>
        {
            ["code"] = code,
            ["grant_type"] = "authorization_code"
        };
        string url;
        if (provider.Name == "zalo")
        {
            url = "https://oauth.zaloapp.com/v4/access_token";
            values["app_id"] = provider.ClientId;
            values["code_verifier"] = attempt.Verifier;
        }
        else
        {
            values["client_id"] = provider.ClientId;
            values["client_secret"] = provider.Secret;
            values["redirect_uri"] = provider.RedirectUri;
            if (provider.Name == "google")
            {
                url = "https://oauth2.googleapis.com/token";
                values["code_verifier"] = attempt.Verifier;
            }
            else
            {
                url = "https://graph.facebook.com/v27.0/oauth/access_token";
            }
        }

        bool facebook = provider.Name == "facebook";
        using var request = new HttpRequestMessage(
            facebook ? HttpMethod.Get : HttpMethod.Post,
            facebook ? QueryHelpers.AddQueryString(
                url, values.Where(pair => pair.Key != "grant_type")
                    .ToDictionary(pair => pair.Key, pair => (string?)pair.Value)) : url);
        if (!facebook) request.Content = new FormUrlEncodedContent(values);
        if (provider.Name == "zalo") request.Headers.Add("secret_key", provider.Secret);

        using var response = await client.SendAsync(request, cancellation);
        if (!response.IsSuccessStatusCode) return null;
        using var body = JsonDocument.Parse(await response.Content.ReadAsStreamAsync(cancellation));
        var field = provider.Name == "google" ? "id_token" : "access_token";
        return body.RootElement.TryGetProperty(field, out var token) &&
               token.ValueKind == JsonValueKind.String ? token.GetString() : null;
    }

    private static string StateKey(string state) => $"oauth-state:{state}";
    private static string AttemptKey(string key) => $"oauth-attempt:{key}";
}
