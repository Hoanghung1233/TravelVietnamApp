
using System.Collections.ObjectModel;
using System.Data;
using Dapper;
using Microsoft.VisualBasic;
using TravelVN.API.Models;

namespace TravelVN.API.models;

public class BookingRepository : BaseRepository
{
    public BookingRepository(IDbConnection Connection) : base(Connection)
    {
    }

    public IEnumerable<Booking> GetAllBookings()
    {
        string sql = @"
            SELECT *
            FROM Booking
            ORDER BY BookingId DESC";

        return connection.Query<Booking>(sql);
    }

    public IEnumerable<Booking> SearchAllBookings(
        string? keyword, string? status, string? paymentStatus)
    {
        string sql = @"
            SELECT *
            FROM Booking
            WHERE (@Keyword IS NULL OR
                   BookingCode LIKE @Keyword OR
                   ContactName LIKE @Keyword OR
                   ContactPhone LIKE @Keyword)
              AND (@Status IS NULL OR Status = @Status)
              AND (@PaymentStatus IS NULL OR PaymentStatus = @PaymentStatus)
            ORDER BY BookingId DESC";

        return connection.Query<Booking>(sql, new
        {
            Keyword = string.IsNullOrWhiteSpace(keyword) ? null : $"%{keyword}%",
            Status = string.IsNullOrWhiteSpace(status) ? null : status,
            PaymentStatus = string.IsNullOrWhiteSpace(paymentStatus) ? null : paymentStatus
        });
    }

    // Cập nhật trạng thái đơn đặt vé
    public int UpdateStatus(int id, string status)
    {
        string sql = @"
            UPDATE Booking
            SET Status = @Status
            WHERE BookingId = @Id";

        return connection.Execute(sql, new { status, id });
    }

    // Lấy danh sách đơn đặt vé của người dùng
    public IEnumerable<Booking> GetBookings(string memberId)
    {
        string sql = @"
            SELECT *
            FROM Booking
            WHERE MemberId = @MemberId";

        return connection.Query<Booking>(sql, new { memberId });
    }

    public IEnumerable<Booking> SearchBookings(string memberId, string keyword)
    {
        string sql = @"
            SELECT *
            FROM Booking
            WHERE MemberId = @MemberId
              AND (
                  BookingCode LIKE @Keyword
                  OR ContactName LIKE @Keyword
                  OR ContactPhone LIKE @Keyword
              )
            ORDER BY BookingId DESC";

        return connection.Query<Booking>(
            sql,
            new { memberId, Keyword = $"%{keyword}%" }
        );
    }

    // Lấy chi tiết đơn đặt vé của người dùng
    public Booking? GetBooking(int id, string memberId)
    {
        string sql = @"
            SELECT *
            FROM Booking
            WHERE BookingId = @Id AND MemberId = @MemberId";

        return connection.QueryFirstOrDefault<Booking>(
            sql,
            new { id, memberId }
        );
    }

    // Thêm đơn đặt vé
    public int Add(Booking obj)
    {
        string sql = @"
            INSERT INTO Booking
            (
                BookingCode,
                MemberId,
                DestinationId,
                ContactName,
                ContactPhone,
                VisitDate,
                UnitPrice,
                Quantity,
                TotalPrice,
                PaymentMethod,
                PaymentStatus,
                Status,
                Note,
                CreatedAt
            )
            VALUES
            (
                @BookingCode,
                @MemberId,
                @DestinationId,
                @ContactName,
                @ContactPhone,
                @VisitDate,
                @UnitPrice,
                @Quantity,
                @TotalPrice,
                @PaymentMethod,
                @PaymentStatus,
                @Status,
                @Note,
                @CreatedAt
            );

            SELECT CAST(SCOPE_IDENTITY() AS INT);";

        return connection.QuerySingle<int>(sql, obj);
    }
}
