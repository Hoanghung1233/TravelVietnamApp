namespace TravelVN.API.Models;


using System.Data;

public abstract class BaseRepository
{
    protected IDbConnection connection;
    public BaseRepository(IDbConnection connection)
    {
        this.connection = connection;
    }
}