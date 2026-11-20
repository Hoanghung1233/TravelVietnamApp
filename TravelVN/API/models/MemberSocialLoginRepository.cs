
using System.Data;
using Dapper;

namespace TravelVN.API.Models;

public class MemberSocialLoginRepository : BaseRepository
{
    public MemberSocialLoginRepository(IDbConnection connection)
        : base(connection)
    {
    }

    // Thêm liên kết tài khoản mạng xã hội
    public int Add(MemberSocialLogin obj)
    {
        string sql = @"
            INSERT INTO MemberSocialLogin
            (MemberId, Provider, ProviderUserId)
            VALUES
            (@MemberId, @Provider, @ProviderUserId)";

        return connection.Execute(sql, obj);
    }

    // Tìm tài khoản mạng xã hội
    public MemberSocialLogin? GetByProvider(
        string provider,
        string providerUserId)
    {
        string sql = @"
            SELECT *
            FROM MemberSocialLogin
            WHERE Provider = @Provider
            AND ProviderUserId = @ProviderUserId";

        return connection.QuerySingleOrDefault<MemberSocialLogin>(
            sql,
            new { Provider = provider, ProviderUserId = providerUserId });
    }

    // Lấy các tài khoản mạng xã hội của Member
    public IEnumerable<MemberSocialLogin> GetByMemberId(string memberId)
    {
        string sql = @"
            SELECT *
            FROM MemberSocialLogin
            WHERE MemberId = @MemberId";

        return connection.Query<MemberSocialLogin>(
            sql, new { MemberId = memberId });
    }

    // Kiểm tra tài khoản đã liên kết chưa
    public bool Exists(string provider, string providerUserId)
    {
        string sql = @"
            SELECT COUNT(1)
            FROM MemberSocialLogin
            WHERE Provider = @Provider
            AND ProviderUserId = @ProviderUserId";

        return connection.ExecuteScalar<int>(
            sql,
            new { Provider = provider, ProviderUserId = providerUserId }) > 0;
    }
}
