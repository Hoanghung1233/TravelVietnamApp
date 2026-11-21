using System.Data;
using Dapper;

namespace TravelVN.API.Models;

public class DestinationRepository(IDbConnection connection) : BaseRepository(connection)
{
    public IEnumerable<Destination> List(int page, int pageSize, int? categoryId, string? keyword)
    {
        const string sql = """
            SELECT * FROM dbo.Destination
            WHERE (@categoryId IS NULL OR CategoryId = @categoryId)
              AND (@pattern IS NULL OR Name LIKE @pattern OR Province LIKE @pattern)
            ORDER BY CreatedAt DESC, DestinationId DESC
            OFFSET @offset ROWS FETCH NEXT @pageSize ROWS ONLY
            """;
        var pattern = string.IsNullOrWhiteSpace(keyword) ? null : $"%{keyword.Trim()}%";
        return this.connection.Query<Destination>(sql, new
        {
            categoryId, pattern, offset = ((long)page - 1) * pageSize, pageSize
        });
    }

    public Destination? Find(int id) => this.connection.QuerySingleOrDefault<Destination>(
        "SELECT * FROM dbo.Destination WHERE DestinationId = @id", new { id });

    public int Add(Destination item) => this.connection.QuerySingle<int>("""
        INSERT INTO dbo.Destination
        (CategoryId, Name, Province, Address, ShortDescription, Description, Image,
         Latitude, Longitude, TicketPrice, OpeningHours)
        OUTPUT INSERTED.DestinationId
        VALUES (@CategoryId, @Name, @Province, @Address, @ShortDescription, @Description,
                @Image, @Latitude, @Longitude, @TicketPrice, @OpeningHours)
        """, item);

    public int Edit(Destination item, string? previousImage) => this.connection.Execute("""
        UPDATE dbo.Destination SET CategoryId = @CategoryId, Name = @Name,
            Province = @Province, Address = @Address, ShortDescription = @ShortDescription,
            Description = @Description, Image = @Image, Latitude = @Latitude,
            Longitude = @Longitude, TicketPrice = @TicketPrice, OpeningHours = @OpeningHours
        WHERE DestinationId = @DestinationId
          AND (Image = @previousImage OR (Image IS NULL AND @previousImage IS NULL))
        """, new
        {
            item.CategoryId, item.Name, item.Province, item.Address, item.ShortDescription,
            item.Description, item.Image, item.Latitude, item.Longitude, item.TicketPrice,
            item.OpeningHours, item.DestinationId, previousImage
        });

    public Destination? Delete(int id) => this.connection.QuerySingleOrDefault<Destination>("""
        DELETE FROM dbo.Destination OUTPUT DELETED.* WHERE DestinationId = @id
        """, new { id });

    public bool UsesImage(string image) => this.connection.ExecuteScalar<bool>("""
        SELECT CAST(CASE WHEN EXISTS (
            SELECT 1 FROM dbo.Destination WHERE Image = @image
                OR EXISTS (SELECT 1 FROM OPENJSON(CASE WHEN ISJSON(Gallery) = 1 THEN Gallery END)
                           WHERE [value] = @image)
        ) THEN 1 ELSE 0 END AS bit)
        """, new { image });
}
