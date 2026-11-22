
using System.Net;
using System.Net.Mail;

namespace TravelVN.Services;

public class EmailService
{
    private readonly IConfiguration configuration;

    private readonly IWebHostEnvironment environment;

    public EmailService(IConfiguration configuration, IWebHostEnvironment environment)
    {
        this.configuration = configuration;
        this.environment = environment;
    }

    private bool ConsoleDelivery => environment.IsDevelopment() &&
        configuration.GetValue<bool>("Email:UseConsoleForDevelopment");

    public bool CanSendOtp => ConsoleDelivery ||
        (!string.IsNullOrWhiteSpace(configuration["Email:Host"]) &&
         !string.IsNullOrWhiteSpace(configuration["Email:Username"]) &&
         !string.IsNullOrWhiteSpace(configuration["Email:Password"]));

    public async Task SendOtp(string email, string code)
    {
        if (ConsoleDelivery)
        {
            Console.WriteLine($"[TravelVN local OTP] {email}: {code}");
            return;
        }

        string host = configuration["Email:Host"]
            ?? throw new Exception("Missing Email:Host");

        int port = int.Parse(
            configuration["Email:Port"] ?? "587");

        string username = configuration["Email:Username"]
            ?? throw new Exception("Missing Email:Username");

        string password = configuration["Email:Password"]
            ?? throw new Exception("Missing Email:Password");

        using SmtpClient client = new SmtpClient(host, port);

        client.Credentials = new NetworkCredential(
            username,
            password);

        client.EnableSsl = true;

        using MailMessage message = new MailMessage();

        message.From = new MailAddress(username, "TravelVN");
        message.To.Add(email);
        message.Subject = "TravelVN - Ma xac thuc OTP";

        message.Body = $@"
            <h2>TravelVN</h2>
            <p>Ma xac thuc cua ban la:</p>
            <h1>{code}</h1>
            <p>Ma OTP co hieu luc trong 5 phut.</p>
            <p>Khong chia se ma nay voi bat ky ai.</p>";

        message.IsBodyHtml = true;

        await client.SendMailAsync(message);
    }
}
