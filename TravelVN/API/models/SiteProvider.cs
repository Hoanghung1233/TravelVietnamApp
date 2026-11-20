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
    ReviewRepository? review;
    public ReviewRepository Review => review ??= new ReviewRepository(Connection);
}