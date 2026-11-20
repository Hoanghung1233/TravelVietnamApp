using System.Data;
using Dapper;

namespace TravelVN.API.Models;
public sealed class FavoriteRepository : BaseRepository
{
    public FavoriteRepository(IDbConnection connection) : base(connection)
    {
    }
    public Task<IEnumerable<FavoriteDestination>> GetFavoritesAsync(string memberId)
    {
        const string sql = """
            SELECT f.FavoriteId, f.DestinationId, f.CreatedAt,
                   d.CategoryId, d.Name, d.Province, d.ShortDescription, d.Image, d.TicketPrice
            FROM dbo.Favorite AS f
            INNER JOIN dbo.Destination AS d ON d.DestinationId = f.DestinationId
            WHERE f.MemberId = @MemberId
            ORDER BY f.CreatedAt DESC, f.FavoriteId DESC;
            """;
        return connection.QueryAsync<FavoriteDestination>(sql, new { MemberId = MemberKey(memberId) });
    }
    public Task<bool> IsFavoriteAsync(string memberId, int destinationId)
    {
        const string sql = """
            SELECT CAST(CASE WHEN EXISTS (
                SELECT 1 FROM dbo.Favorite
                WHERE MemberId = @MemberId AND DestinationId = @DestinationId
            ) THEN 1 ELSE 0 END AS bit);
            """;
        return connection.QuerySingleAsync<bool>(sql, new { MemberId = MemberKey(memberId), DestinationId = destinationId });
    }
    public Task<Favorite?> AddAsync(string memberId, int destinationId)
    {
        const string sql = """
            INSERT INTO dbo.Favorite (MemberId, DestinationId)
            OUTPUT inserted.FavoriteId, inserted.DestinationId, inserted.CreatedAt
            SELECT @MemberId, d.DestinationId
            FROM dbo.Destination AS d
            WHERE d.DestinationId = @DestinationId
              AND EXISTS (SELECT 1 FROM dbo.Member WHERE MemberId = @MemberId);
            """;
        return connection.QuerySingleOrDefaultAsync<Favorite>(
            sql, new { MemberId = MemberKey(memberId), DestinationId = destinationId });
    }
    public Task<int> DeleteAsync(string memberId, int destinationId)
    {
        const string sql = """
            DELETE FROM dbo.Favorite
            WHERE MemberId = @MemberId AND DestinationId = @DestinationId;
            """;
        return connection.ExecuteAsync(sql, new { MemberId = MemberKey(memberId), DestinationId = destinationId });
    }
    private static DbString MemberKey(string memberId) =>
        new() { Value = memberId, IsAnsi = true, Length = 32 };
}
