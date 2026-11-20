
using System.Data;
using Dapper;

namespace TravelVN.API.Models;

public class EmailOtpRepository : BaseRepository
{
    public EmailOtpRepository(IDbConnection connection)
        : base(connection)
    {
    }

    // Tạo OTP
    public int Add(EmailOtp obj)
    {
        string sql = @"
            INSERT INTO EmailOtp
            (
                MemberId, Email, CodeHash, Purpose,
                ExpiresAt, IsUsed, Attempts, CreatedAt
            )
            VALUES
            (
                @MemberId, @Email, @CodeHash, @Purpose,
                @ExpiresAt, 0, 0, GETDATE()
            )";

        return connection.Execute(sql, obj);
    }

    // Xác minh OTP và đánh dấu đã sử dụng
    public bool Verify(
        string memberId,
        string email,
        string code,
        string purpose)
    {
        bool wasClosed = connection.State == ConnectionState.Closed;

        if (wasClosed)
            connection.Open();

        using IDbTransaction transaction = connection.BeginTransaction();

        try
        {
            string sql = @"
                SELECT TOP 1 *
                FROM EmailOtp
                WHERE MemberId = @MemberId
                  AND Email = @Email
                  AND Purpose = @Purpose
                  AND IsUsed = 0
                  AND ExpiresAt > GETDATE()
                  AND Attempts < 5
                ORDER BY CreatedAt DESC";

            EmailOtp? otp = connection.QuerySingleOrDefault<EmailOtp>(
                sql,
                new
                {
                    MemberId = memberId,
                    Email = email,
                    Purpose = purpose
                },
                transaction);

            if (otp == null)
            {
                transaction.Commit();
                return false;
            }

            bool isCorrect = BCrypt.Net.BCrypt.Verify(
                code,
                otp.CodeHash);

            if (!isCorrect)
            {
                string updateAttempts = @"
                    UPDATE EmailOtp
                    SET Attempts = Attempts + 1
                    WHERE OtpId = @OtpId";

                connection.Execute(
                    updateAttempts,
                    new { otp.OtpId },
                    transaction);

                transaction.Commit();
                return false;
            }

            string updateUsed = @"
                UPDATE EmailOtp
                SET IsUsed = 1
                WHERE OtpId = @OtpId";

            connection.Execute(
                updateUsed,
                new { otp.OtpId },
                transaction);

            transaction.Commit();
            return true;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
        finally
        {
            if (wasClosed)
                connection.Close();
        }
    }

    // Đánh dấu các OTP cũ đã hết hiệu lực
    public int InvalidateOldOtp(string memberId, string purpose)
    {
        string sql = @"
            UPDATE EmailOtp
            SET IsUsed = 1
            WHERE MemberId = @MemberId
              AND Purpose = @Purpose
              AND IsUsed = 0";

        return connection.Execute(sql, new
        {
            MemberId = memberId,
            Purpose = purpose
        });
    }
}
