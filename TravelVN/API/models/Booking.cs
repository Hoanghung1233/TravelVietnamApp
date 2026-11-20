
namespace TravelVN.API.models;

public class Booking
{
    public int BookingId { get; set; }
    public string? BookingCode { get; set; }
    public int UserId { get; set; }
    public int DestinationId { get; set; }
    public string? ContactName { get; set; }
    public string? ContactPhone { get; set; }
    public DateTime VisitDate { get; set; }
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal TotalPrice { get; set; }
    public string? PaymentMethod { get; set; }
    public string? PaymentStatus { get; set; }
    public string? Status { get; set; }
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; }
}
