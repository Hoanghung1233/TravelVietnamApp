namespace TravelVN.API.Models;


public class SiteProvider : BaseProvider
{
    public SiteProvider(IConfiguration configuration) : base(configuration)
    {
    }
    CategoryRepository? category;
    public CategoryRepository Category => category ??= new CategoryRepository(Connection);
    MemberRepository? member;
    public MemberRepository Member => member ??= new MemberRepository(Connection);
    DestinationRepository? destination;
    public DestinationRepository Destination => destination ??= new DestinationRepository(Connection);
}