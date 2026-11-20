using TravelVN.API.models;

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
    BookingRepository? booking;
    public BookingRepository Booking => booking ??= new BookingRepository(Connection);
}