
using System.Data;
using Dapper;

namespace TravelVN.API.Models;

public class ReviewRepository : BaseRepository
{
    public ReviewRepository(IDbConnection connection) : base(connection)
    {
    }

    public IEnumerable<Review> GetReviews()
    {
        string sql = "SELECT * FROM Review ORDER BY CreatedAt DESC";
        return connection.Query<Review>(sql);
    }

    public Review? GetReview(int id)
    {
        string sql = "SELECT * FROM Review WHERE ReviewId = @Id";
        return connection.QuerySingleOrDefault<Review>(sql, new { id });
    }

    public IEnumerable<Review> GetReviewsByDestination(int destinationId)
    {
        string sql = "SELECT * FROM Review WHERE DestinationId = @DestinationId ORDER BY CreatedAt DESC";
        return connection.Query<Review>(sql, new { destinationId });
    }

    public bool DestinationExists(int destinationId)
    {
        string sql = "SELECT COUNT(1) FROM Destination WHERE DestinationId = @DestinationId";
        return connection.ExecuteScalar<int>(sql, new { destinationId }) > 0;
    }

    public int AddReview(string memberId, CreateReviewRequest obj)
    {
        string sql = @"INSERT INTO Review (MemberId, DestinationId, Rating, Comment, CreatedAt)
                       OUTPUT INSERTED.ReviewId
                       VALUES (@MemberId, @DestinationId, @Rating, @Comment, SYSUTCDATETIME())";

        return connection.ExecuteScalar<int>(sql, new
        {
            memberId,
            obj.DestinationId,
            obj.Rating,
            obj.Comment
        });
    }

    public int UpdateReview(int reviewId, string memberId, UpdateReviewRequest obj)
    {
        string sql = @"UPDATE Review
                       SET Rating = @Rating, Comment = @Comment
                       WHERE ReviewId = @ReviewId AND MemberId = @MemberId";

        return connection.Execute(sql, new
        {
            reviewId,
            memberId,
            obj.Rating,
            obj.Comment
        });
    }

    public int DeleteReview(int reviewId, string memberId)
    {
        string sql = "DELETE FROM Review WHERE ReviewId = @ReviewId AND MemberId = @MemberId";
        return connection.Execute(sql, new { reviewId, memberId });
    }
}
