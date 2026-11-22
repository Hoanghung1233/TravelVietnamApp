
using System.Data;
using Dapper;
using TravelVN.Services;

namespace TravelVN.API.Models;

public class MemberRepository : BaseRepository
{
    public MemberRepository(IDbConnection connection) : base(connection)
    {
    }

    // =========================================
    // 1. ĐĂNG KÝ MEMBER
    // =========================================
    public int Add(Member obj)
    {
        if (string.IsNullOrEmpty(obj.MemberId))
        {
            obj.MemberId = Guid.NewGuid().ToString().Replace("-", string.Empty);
        }

        // Mã hóa mật khẩu nếu người dùng có nhập
        if (!string.IsNullOrEmpty(obj.Password))
        {
            obj.Password = BCrypt.Net.BCrypt.HashPassword(obj.Password);
        }

        string sql = @"
            INSERT INTO Member
            (
                MemberId, Surname, GivenName, Email,
                Password, Phone, Avatar, Role,
                IsEmailVerified, CreatedAt
            )
            VALUES
            (
                @MemberId, @Surname, @GivenName, @Email,
                @Password, @Phone, @Avatar, @Role,
                @IsEmailVerified, GETDATE()
            )";

        return connection.Execute(sql, new
        {
            obj.MemberId,
            obj.Surname,
            obj.GivenName,
            obj.Email,
            obj.Password,
            obj.Phone,
            obj.Avatar,
            Role = obj.Role.ToString(),
            obj.IsEmailVerified
        });
    }

    // =========================================
    // 2. LẤY MEMBER THEO EMAIL
    // =========================================
    public Member? GetMemberByEmail(string email)
    {
        string sql = "SELECT * FROM Member WHERE Email = @Email";

        return connection.QuerySingleOrDefault<Member>(
            sql,
            new { Email = email }
        );
    }

    // =========================================
    // 3. LẤY MEMBER THEO ID
    // =========================================
    public Member? GetMemberById(string id)
    {
        string sql = @"
            SELECT MemberId, Surname, GivenName, Email,
                   Phone, Avatar, Role, IsEmailVerified, CreatedAt
            FROM Member
            WHERE MemberId = @Id";

        return connection.QuerySingleOrDefault<Member>(
            sql,
            new { Id = id }
        );
    }

    // =========================================
    // 4. ĐĂNG NHẬP EMAIL VÀ MẬT KHẨU
    // =========================================
    public LoginResult Login(LoginModel obj, IConfiguration configuration)
    {
        Member? member = GetMemberByEmail(obj.Email);

        if (member == null)
        {
            return new LoginResult
            {
                Success = false,
                Message = "Email Invalid"
            };
        }

        // Tài khoản chưa thiết lập mật khẩu
        if (string.IsNullOrEmpty(member.Password))
        {
            return new LoginResult
            {
                Success = false,
                Message = "Account has not set a password"
            };
        }

        if (!BCrypt.Net.BCrypt.Verify(obj.Password, member.Password))
        {
            return new LoginResult
            {
                Success = false,
                Message = "Password Invalid"
            };
        }

        return new LoginResult
        {
            Success = true,
            Message = "Login Success",
            Token = Helper.GenerateToken(member, configuration)
        };
    }

    // =========================================
    // 5. ĐĂNG KÝ / ĐĂNG NHẬP GOOGLE, FACEBOOK, ZALO
    // =========================================
    // ProviderUserId phải được lấy từ token đã xác minh
    // bởi Google, Facebook hoặc Zalo ở phía Backend.
    public LoginResult SocialLogin(
        Member obj,
        string provider,
        string providerUserId,
        IConfiguration configuration)
    {
        // Kiểm tra tài khoản mạng xã hội đã liên kết chưa
        string sql = @"
            SELECT M.*
            FROM Member M
            INNER JOIN MemberSocialLogin S
                ON M.MemberId = S.MemberId
            WHERE S.Provider = @Provider
              AND S.ProviderUserId = @ProviderUserId";

        Member? member = connection.QuerySingleOrDefault<Member>(
            sql,
            new
            {
                Provider = provider,
                ProviderUserId = providerUserId
            }
        );

        // Đã liên kết: đăng nhập
        if (member != null)
        {
            return new LoginResult
            {
                Success = true,
                Message = "Social Login Success",
                Token = Helper.GenerateToken(member, configuration)
            };
        }

        // Chưa liên kết: không tự động liên kết theo email
        // nếu email đã thuộc một tài khoản khác.
        if (!string.IsNullOrEmpty(obj.Email))
        {
            Member? oldMember = GetMemberByEmail(obj.Email);

            if (oldMember != null)
            {
                return new LoginResult
                {
                    Success = false,
                    Message = "Email already exists. Please login to your existing account first."
                };
            }
        }

        // Tạo Member mới
        if (string.IsNullOrEmpty(obj.MemberId))
        {
            obj.MemberId = Guid.NewGuid().ToString().Replace("-", string.Empty);
        }

        obj.Password = null;
        obj.Role = Role.Member;

        using IDbTransaction transaction = connection.BeginTransaction();

        try
        {
            string insertMember = @"
                INSERT INTO Member
                (
                    MemberId, Surname, GivenName, Email,
                    Password, Phone, Avatar, Role,
                    IsEmailVerified, CreatedAt
                )
                VALUES
                (
                    @MemberId, @Surname, @GivenName, @Email,
                    NULL, @Phone, @Avatar, @Role,
                    @IsEmailVerified, GETDATE()
                )";

            connection.Execute(insertMember, new
            {
                obj.MemberId,
                obj.Surname,
                obj.GivenName,
                obj.Email,
                obj.Phone,
                obj.Avatar,
                Role = obj.Role.ToString(),
                obj.IsEmailVerified
            }, transaction);

            string insertSocial = @"
                INSERT INTO MemberSocialLogin
                (
                    MemberId, Provider, ProviderUserId
                )
                VALUES
                (
                    @MemberId, @Provider, @ProviderUserId
                )";

            connection.Execute(insertSocial, new
            {
                obj.MemberId,
                Provider = provider,
                ProviderUserId = providerUserId
            }, transaction);

            transaction.Commit();

            return new LoginResult
            {
                Success = true,
                Message = "Social Register Success",
                Token = Helper.GenerateToken(obj, configuration)
            };
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    // =========================================
    // 6. ĐỔI MẬT KHẨU
    // =========================================
    public int ChangePassword(string id, ChangePasswordModel obj)
    {
        string sqlGet = "SELECT Password FROM Member WHERE MemberId = @Id";

        string? oldPassword = connection.QuerySingleOrDefault<string?>(
            sqlGet,
            new { Id = id }
        );

        if (oldPassword == null)
        {
            return 0;
        }

        if (!BCrypt.Net.BCrypt.Verify(obj.CurrentPassword, oldPassword))
        {
            return -1;
        }

        string password = BCrypt.Net.BCrypt.HashPassword(obj.NewPassword);

        string sql = @"
            UPDATE Member
            SET Password = @Password
            WHERE MemberId = @Id";

        return connection.Execute(sql, new
        {
            Id = id,
            Password = password
        });
    }

    // =========================================
    // 7. THIẾT LẬP MẬT KHẨU LẦN ĐẦU
    // Dành cho tài khoản Facebook / Zalo
    // =========================================
    public int SetPassword(string id, string newPassword)
    {
        string password = BCrypt.Net.BCrypt.HashPassword(newPassword);

        string sql = @"
            UPDATE Member
            SET Password = @Password
            WHERE MemberId = @Id
              AND Password IS NULL";

        return connection.Execute(sql, new
        {
            Id = id,
            Password = password
        });
    }

    // =========================================
    // 8. CẬP NHẬT EMAIL SAU KHI XÁC MINH OTP
    // =========================================
    // Chỉ gọi hàm này sau khi EmailOtpRepository
    // đã xác minh OTP thành công.
    public int UpdateVerifiedEmail(string id, string email)
    {
        string sql = @"
            UPDATE Member
            SET Email = @Email,
                IsEmailVerified = 1
            WHERE MemberId = @Id";

        return connection.Execute(sql, new
        {
            Id = id,
            Email = email
        });
    }

    // =========================================
    // 9. ĐÁNH DẤU EMAIL ĐÃ XÁC MINH
    // =========================================
    public int VerifyEmail(string id)
    {
        string sql = @"
            UPDATE Member
            SET IsEmailVerified = 1
            WHERE MemberId = @Id
              AND Email IS NOT NULL";

        return connection.Execute(sql, new { Id = id });
    }

    // =========================================
    // 10. ĐẶT LẠI MẬT KHẨU SAU KHI XÁC MINH OTP
    // =========================================
    // Chỉ gọi sau khi OTP đã được xác minh thành công.
    public int ResetPassword(string email, string newPassword)
    {
        string password = BCrypt.Net.BCrypt.HashPassword(newPassword);

        string sql = @"
            UPDATE Member
            SET Password = @Password
            WHERE Email = @Email
              AND IsEmailVerified = 1";

        return connection.Execute(sql, new
        {
            Email = email,
            Password = password
        });
    }

    // =========================================
    // 11. HIỂN THỊ DANH SÁCH MEMBER
    // Không lấy Password để tránh lộ mật khẩu
    // =========================================
    public IEnumerable<Member> GetMembers()
    {
        string sql = @"
            SELECT MemberId, Surname, GivenName, Email,
                   Phone, Avatar, Role, IsEmailVerified, CreatedAt
            FROM Member";

        return connection.Query<Member>(sql);
    }

    // =========================================
    // 12. CẬP NHẬT THÔNG TIN MEMBER
    // Không cập nhật Password và Role ở đây
    // =========================================
    public int EditMember(Member obj)
    {
        string sql = @"
            UPDATE Member
            SET Surname = @Surname,
                GivenName = @GivenName,
                Phone = @Phone,
                Avatar = @Avatar
            WHERE MemberId = @MemberId";

        return connection.Execute(sql, obj);
    }
    // =========================================
    // 14. PHÂN QUYỀN MEMBER / ADMIN
    // =========================================
    public int UpdateRole(Member obj)
    {
        string sql = @"
            UPDATE Member
            SET Role = @Role
            WHERE MemberId = @MemberId";

        return connection.Execute(sql, new
        {
            obj.MemberId,
            Role = obj.Role.ToString()
        });
    }

    // =========================================
    // 15. KIỂM TRA TÀI KHOẢN ĐÃ LIÊN KẾT MẠNG XÃ HỘI
    // =========================================
    public bool IsSocialLoginExists(string provider, string providerUserId)
    {
        string sql = @"
            SELECT COUNT(1)
            FROM MemberSocialLogin
            WHERE Provider = @Provider
              AND ProviderUserId = @ProviderUserId";

        return connection.ExecuteScalar<int>(sql, new
        {
            Provider = provider,
            ProviderUserId = providerUserId
        }) > 0;
    }
}