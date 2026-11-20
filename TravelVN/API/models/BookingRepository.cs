
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
    public IEnumerable<Booking> GetBookings(int userId)
    {
        string sql = @"
            SELECT *
            FROM Booking
            WHERE UserId = @UserId";

        return connection.Query<Booking>(sql, new { userId });
    }

    // Lấy chi tiết đơn đặt vé
    public Booking? GetBooking(int id)
    {
        string sql = @"
            SELECT *
            FROM Booking
            WHERE BookingId = @Id";

        return connection.QueryFirstOrDefault<Booking>(
            sql,
            new { id }
        );
    }

    // Thêm đơn đặt vé
    public int Add(Booking obj)
    {
        string sql = @"
            INSERT INTO Booking
            (
                BookingCode,
                UserId,
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
                @UserId,
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
