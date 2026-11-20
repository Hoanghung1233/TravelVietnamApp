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
    MemberSocialLoginRepository? memberSocialLogin;
    public MemberSocialLoginRepository MemberSocialLogin => memberSocialLogin ??= new MemberSocialLoginRepository(Connection);
    private EmailOtpRepository? emailOtp;
    public EmailOtpRepository EmailOtp => emailOtp ??= new EmailOtpRepository(Connection);
}