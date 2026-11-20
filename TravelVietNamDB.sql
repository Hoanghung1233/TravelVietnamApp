CREATE DATABASE TravelVietnamDB;
GO

USE TravelVietnamDB;
GO

-- 1. USERS
CREATE TABLE Member (
    MemberId VARCHAR(32) PRIMARY KEY,
    Surname NVARCHAR(60) NOT NULL,
    GivenName NVARCHAR(30) NOT NULL,
    Email NVARCHAR(150) NOT NULL UNIQUE,
    Password NVARCHAR(255) NOT NULL,
    Phone NVARCHAR(15),
    Avatar NVARCHAR(255),
    Role NVARCHAR(10) NOT NULL ,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE()
);
GO

-- 2. CATEGORIES
CREATE TABLE Category (
    CategoryId INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    Image NVARCHAR(255)
);
GO

-- 3. DESTINATIONS
CREATE TABLE Destination (
    DestinationId INT IDENTITY(1,1) PRIMARY KEY,
    CategoryId INT NOT NULL,
    Name NVARCHAR(150) NOT NULL,
    Province NVARCHAR(100) NOT NULL,
    Address NVARCHAR(255),
    ShortDescription NVARCHAR(500),
    Description NVARCHAR(MAX),
    Image NVARCHAR(255),
    Gallery NVARCHAR(MAX),
    Latitude DECIMAL(10,7),
    Longitude DECIMAL(10,7),
    TicketPrice DECIMAL(18,2) NOT NULL DEFAULT 0,
    OpeningHours NVARCHAR(100),
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),

    FOREIGN KEY (CategoryId)
        REFERENCES Category(CategoryId)
);
GO

-- 4. REVIEWS
CREATE TABLE Review (
    ReviewId INT IDENTITY(1,1) PRIMARY KEY,
    MemberId VARCHAR(32) NOT NULL,
    DestinationId INT NOT NULL,
    Rating INT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Comment NVARCHAR(1000),
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),

    FOREIGN KEY (MemberId) REFERENCES Member(MemberId),
    FOREIGN KEY (DestinationId) REFERENCES Destination(DestinationId),

    CONSTRAINT UQ_Reviews_User_Destination
        UNIQUE (MemberId, DestinationId)
);
GO

-- 5. FAVORITES
CREATE TABLE Favorite (
    FavoriteId INT IDENTITY(1,1) PRIMARY KEY,
    MemberId VARCHAR(32) NOT NULL,
    DestinationId INT NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),

    FOREIGN KEY (MemberId) REFERENCES Member(MemberId),
    FOREIGN KEY (DestinationId) REFERENCES Destination(DestinationId),

    CONSTRAINT UQ_Favorites_User_Destination
        UNIQUE (MemberId, DestinationId)
);
GO

-- 6. BOOKINGS
CREATE TABLE Booking (
    BookingId INT IDENTITY(1,1) PRIMARY KEY,
    BookingCode NVARCHAR(20) NOT NULL UNIQUE,
    MemberId VARCHAR(32) NOT NULL,
    DestinationId INT NOT NULL,
    ContactName NVARCHAR(100) NOT NULL,
    ContactPhone NVARCHAR(15) NOT NULL,
    VisitDate DATE NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(18,2) NOT NULL,
    TotalPrice DECIMAL(18,2) NOT NULL,
    PaymentMethod NVARCHAR(30) NOT NULL DEFAULT 'Cash',
    PaymentStatus NVARCHAR(20) NOT NULL DEFAULT 'Unpaid',
    Status NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    Note NVARCHAR(500),
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),

    FOREIGN KEY (MemberId) REFERENCES Member(MemberId),
    FOREIGN KEY (DestinationId) REFERENCES Destination(DestinationId)
);
GO

-- =============================================
-- 1. INSERT CATEGORY
-- =============================================

INSERT INTO Category (CategoryName, Description, Image)
VALUES
(N'Biển đảo',
 N'Khám phá những bãi biển, hòn đảo và vùng biển tuyệt đẹp của Việt Nam.',
 N'uploads/categories/bien-dao.jpg'),

(N'Núi và cao nguyên',
 N'Khám phá núi non, cao nguyên, ruộng bậc thang và cảnh quan hùng vĩ.',
 N'uploads/categories/nui-cao-nguyen.jpg'),

(N'Di sản văn hóa',
 N'Các địa điểm mang giá trị lịch sử, văn hóa và kiến trúc đặc sắc.',
 N'uploads/categories/di-san-van-hoa.jpg'),

(N'Danh lam thắng cảnh',
 N'Những cảnh quan thiên nhiên nổi tiếng và kỳ thú của Việt Nam.',
 N'uploads/categories/danh-lam-thang-canh.jpg'),

(N'Du lịch tâm linh',
 N'Các ngôi chùa, đền, miếu và địa điểm hành hương nổi tiếng.',
 N'uploads/categories/du-lich-tam-linh.jpg'),

(N'Du lịch sinh thái',
 N'Khám phá rừng, hồ, vườn quốc gia và hệ sinh thái tự nhiên.',
 N'uploads/categories/du-lich-sinh-thai.jpg'),

(N'Đô thị và kiến trúc',
 N'Những công trình kiến trúc, đô thị và điểm tham quan nổi bật.',
 N'uploads/categories/do-thi-kien-truc.jpg'),

(N'Vui chơi giải trí',
 N'Các khu vui chơi, công viên giải trí và tổ hợp du lịch.',
 N'uploads/categories/vui-choi-giai-tri.jpg');
GO


-- =============================================
-- 2. INSERT DESTINATION
-- =============================================

INSERT INTO Destination
(
    CategoryId,
    Name,
    Province,
    Address,
    ShortDescription,
    Description,
    Image,
    Gallery,
    Latitude,
    Longitude,
    TicketPrice,
    OpeningHours
)
SELECT
    C.CategoryId,
    D.Name,
    D.Province,
    D.Address,
    D.ShortDescription,
    D.Description,
    D.Image,
    D.Gallery,
    D.Latitude,
    D.Longitude,
    D.TicketPrice,
    D.OpeningHours
FROM
(
    VALUES

    -- =========================================
    -- MIỀN BẮC
    -- =========================================

    (
      N'Biển đảo',
      N'Vịnh Hạ Long',
      N'Quảng Ninh',
      N'Thành phố Hạ Long, tỉnh Quảng Ninh',
      N'Kỳ quan thiên nhiên nổi tiếng với hàng nghìn đảo đá vôi giữa làn nước xanh.',
      N'Vịnh Hạ Long là một trong những điểm du lịch nổi tiếng nhất Việt Nam, nổi bật với hàng nghìn đảo đá vôi có hình dáng độc đáo, hang động kỳ thú và làn nước biển xanh. Du khách có thể tham quan vịnh bằng tàu, chèo kayak và khám phá các hang động tự nhiên.',
      N'uploads/destinations/vinh-ha-long.jpg',
      N'["uploads/destinations/vinh-ha-long-1.jpg","uploads/destinations/vinh-ha-long-2.jpg"]',
      20.9101, 107.1839, 290000,
      N'Tùy tuyến tàu và lịch tham quan'
    ),

    (
      N'Núi và cao nguyên',
      N'Sa Pa',
      N'Lào Cai',
      N'Thị xã Sa Pa, tỉnh Lào Cai',
      N'Vùng núi nổi tiếng với ruộng bậc thang, khí hậu mát mẻ và bản làng dân tộc.',
      N'Sa Pa hấp dẫn du khách bởi cảnh quan núi non hùng vĩ, những thửa ruộng bậc thang trải dài trên sườn núi và bản sắc văn hóa của các dân tộc thiểu số. Đây là điểm đến phù hợp cho nghỉ dưỡng, trekking và khám phá thiên nhiên.',
      N'uploads/destinations/sa-pa.jpg',
      N'["uploads/destinations/sa-pa-1.jpg","uploads/destinations/sa-pa-2.jpg"]',
      22.3364, 103.8438, 0,
      N'Tham quan tự do'
    ),

    (
      N'Núi và cao nguyên',
      N'Đỉnh Fansipan',
      N'Lào Cai',
      N'Khu du lịch Sun World Fansipan Legend, Sa Pa, Lào Cai',
      N'Nóc nhà Đông Dương với cảnh quan núi rừng hùng vĩ.',
      N'Fansipan là ngọn núi cao nhất Việt Nam và bán đảo Đông Dương. Du khách có thể trải nghiệm hệ thống cáp treo hiện đại, ngắm biển mây, khám phá quần thể tâm linh và chinh phục đỉnh núi ở độ cao 3.143 mét.',
      N'uploads/destinations/fansipan.jpg',
      N'["uploads/destinations/fansipan-1.jpg","uploads/destinations/fansipan-2.jpg"]',
      22.3033, 103.7750, 800000,
      N'Theo lịch hoạt động cáp treo'
    ),

    (
      N'Danh lam thắng cảnh',
      N'Tràng An',
      N'Ninh Bình',
      N'Quần thể danh thắng Tràng An, Ninh Bình',
      N'Quần thể núi đá vôi, hang động và sông nước tuyệt đẹp.',
      N'Tràng An là di sản văn hóa và thiên nhiên thế giới được UNESCO công nhận. Nơi đây nổi bật với hệ thống núi đá vôi, hang động xuyên thủy và dòng sông uốn lượn giữa thung lũng. Du khách thường tham quan bằng thuyền để khám phá cảnh quan.',
      N'uploads/destinations/trang-an.jpg',
      N'["uploads/destinations/trang-an-1.jpg","uploads/destinations/trang-an-2.jpg"]',
      20.2506, 105.9369, 250000,
      N'Tùy tuyến tham quan'
    ),

    (
      N'Đô thị và kiến trúc',
      N'Hồ Hoàn Kiếm',
      N'Hà Nội',
      N'Phường Hoàn Kiếm, thành phố Hà Nội',
      N'Hồ nước lịch sử nằm giữa trung tâm thủ đô Hà Nội.',
      N'Hồ Hoàn Kiếm là biểu tượng văn hóa và lịch sử của Hà Nội. Bao quanh hồ là không gian đi bộ, Tháp Rùa, cầu Thê Húc và đền Ngọc Sơn. Đây là địa điểm lý tưởng để dạo bộ và tìm hiểu lịch sử thủ đô.',
      N'uploads/destinations/ho-hoan-kiem.jpg',
      N'["uploads/destinations/ho-hoan-kiem-1.jpg","uploads/destinations/ho-hoan-kiem-2.jpg"]',
      21.0287, 105.8523, 0,
      N'Tham quan khu vực hồ tự do'
    ),

    (
      N'Di sản văn hóa',
      N'Văn Miếu - Quốc Tử Giám',
      N'Hà Nội',
      N'58 Quốc Tử Giám, Đống Đa, Hà Nội',
      N'Quần thể di tích lịch sử gắn liền với truyền thống hiếu học Việt Nam.',
      N'Văn Miếu - Quốc Tử Giám là trường đại học đầu tiên của Việt Nam, được xây dựng từ thời Lý. Khu di tích lưu giữ nhiều giá trị kiến trúc, văn hóa và giáo dục, trong đó có hệ thống bia tiến sĩ được UNESCO ghi danh.',
      N'uploads/destinations/van-mieu.jpg',
      N'["uploads/destinations/van-mieu-1.jpg","uploads/destinations/van-mieu-2.jpg"]',
      21.0278, 105.8355, 70000,
      N'Tùy lịch hoạt động của di tích'
    ),

    (
      N'Núi và cao nguyên',
      N'Cao nguyên đá Đồng Văn',
      N'Tuyên Quang',
      N'Công viên địa chất toàn cầu Cao nguyên đá Đồng Văn',
      N'Vùng cao nguyên đá độc đáo với núi đá tai mèo và bản làng vùng cao.',
      N'Cao nguyên đá Đồng Văn sở hữu cảnh quan địa chất đặc sắc với những dãy núi đá vôi trùng điệp, cung đường đèo nổi tiếng và các bản làng mang đậm bản sắc văn hóa vùng cao. Đây là điểm đến hấp dẫn cho những chuyến du lịch khám phá.',
      N'uploads/destinations/dong-van.jpg',
      N'["uploads/destinations/dong-van-1.jpg","uploads/destinations/dong-van-2.jpg"]',
      23.2765, 105.3588, 0,
      N'Tham quan tự do'
    ),

    (
      N'Danh lam thắng cảnh',
      N'Thác Bản Giốc',
      N'Cao Bằng',
      N'Xã Đàm Thủy, tỉnh Cao Bằng',
      N'Ngọn thác hùng vĩ nằm giữa khung cảnh núi rừng biên giới.',
      N'Thác Bản Giốc là một trong những thác nước tự nhiên nổi tiếng nhất Việt Nam. Dòng nước đổ xuống qua nhiều tầng đá, tạo nên khung cảnh hùng vĩ giữa núi rừng xanh mát. Đây là điểm tham quan nổi bật của tỉnh Cao Bằng.',
      N'uploads/destinations/thac-ban-gioc.jpg',
      N'["uploads/destinations/thac-ban-gioc-1.jpg","uploads/destinations/thac-ban-gioc-2.jpg"]',
      22.8536, 106.7221, 45000,
      N'Tùy thời gian hoạt động của khu du lịch'
    ),

    (
      N'Du lịch sinh thái',
      N'Hồ Ba Bể',
      N'Thái Nguyên',
      N'Vườn quốc gia Ba Bể, tỉnh Thái Nguyên',
      N'Hồ nước ngọt tự nhiên nằm giữa núi rừng Đông Bắc.',
      N'Hồ Ba Bể là hồ nước ngọt tự nhiên có cảnh quan thơ mộng, được bao quanh bởi núi đá vôi và rừng nguyên sinh. Du khách có thể đi thuyền, khám phá hang động và tìm hiểu đời sống văn hóa của cộng đồng dân tộc địa phương.',
      N'uploads/destinations/ho-ba-be.jpg',
      N'["uploads/destinations/ho-ba-be-1.jpg","uploads/destinations/ho-ba-be-2.jpg"]',
      22.4120, 105.6170, 0,
      N'Theo hoạt động của điểm tham quan'
    ),

    (
      N'Núi và cao nguyên',
      N'Tam Đảo',
      N'Phú Thọ',
      N'Thị trấn Tam Đảo, tỉnh Phú Thọ',
      N'Điểm nghỉ dưỡng trên núi với khí hậu mát mẻ quanh năm.',
      N'Tam Đảo nổi tiếng với khí hậu trong lành, sương mù và cảnh quan núi rừng. Du khách có thể tham quan nhà thờ đá, thác Bạc, quảng trường trung tâm và thưởng thức các món ăn đặc sản địa phương.',
      N'uploads/destinations/tam-dao.jpg',
      N'["uploads/destinations/tam-dao-1.jpg","uploads/destinations/tam-dao-2.jpg"]',
      21.4550, 105.6430, 0,
      N'Tham quan tự do'
    ),

    -- =========================================
    -- MIỀN TRUNG
    -- =========================================

    (
      N'Di sản văn hóa',
      N'Phố cổ Hội An',
      N'Đà Nẵng',
      N'Phường Hội An, thành phố Đà Nẵng',
      N'Đô thị cổ nổi tiếng với nhà cổ, đèn lồng và kiến trúc giao thoa văn hóa.',
      N'Phố cổ Hội An là di sản văn hóa thế giới với những ngôi nhà cổ, hội quán, chùa Cầu và các con phố đèn lồng đặc trưng. Nơi đây lưu giữ dấu ấn giao thương quốc tế trong nhiều thế kỷ và có nền ẩm thực phong phú.',
      N'uploads/destinations/pho-co-hoi-an.jpg',
      N'["uploads/destinations/hoi-an-1.jpg","uploads/destinations/hoi-an-2.jpg"]',
      15.8801, 108.3380, 80000,
      N'Tùy khu vực và chương trình tham quan'
    ),

    (
      N'Di sản văn hóa',
      N'Đại Nội Huế',
      N'Huế',
      N'Đường 23 Tháng 8, phường Phú Xuân, thành phố Huế',
      N'Hoàng thành lịch sử gắn liền với triều đại nhà Nguyễn.',
      N'Đại Nội Huế là trung tâm quyền lực của triều Nguyễn, bao gồm Hoàng Thành và Tử Cấm Thành. Công trình nổi bật với kiến trúc cung đình, cổng thành, điện Thái Hòa và nhiều di tích có giá trị lịch sử.',
      N'uploads/destinations/dai-noi-hue.jpg',
      N'["uploads/destinations/dai-noi-hue-1.jpg","uploads/destinations/dai-noi-hue-2.jpg"]',
      16.4698, 107.5770, 200000,
      N'Tùy lịch mở cửa di tích'
    ),

    (
      N'Vui chơi giải trí',
      N'Bà Nà Hills',
      N'Đà Nẵng',
      N'Khu du lịch Sun World Bà Nà Hills, Đà Nẵng',
      N'Tổ hợp du lịch trên núi nổi bật với Cầu Vàng và hệ thống cáp treo.',
      N'Bà Nà Hills là khu du lịch nghỉ dưỡng và giải trí nổi tiếng của Đà Nẵng. Nơi đây có Cầu Vàng, Làng Pháp, vườn hoa, khu vui chơi trong nhà và hệ thống cáp treo đưa du khách lên độ cao lớn để ngắm cảnh núi rừng.',
      N'uploads/destinations/ba-na-hills.jpg',
      N'["uploads/destinations/ba-na-1.jpg","uploads/destinations/ba-na-2.jpg"]',
      15.9977, 107.9880, 950000,
      N'Theo lịch hoạt động của khu du lịch'
    ),

    (
      N'Danh lam thắng cảnh',
      N'Ngũ Hành Sơn',
      N'Đà Nẵng',
      N'Phường Ngũ Hành Sơn, thành phố Đà Nẵng',
      N'Quần thể núi đá vôi với hang động, chùa chiền và cảnh quan độc đáo.',
      N'Ngũ Hành Sơn gồm năm ngọn núi đá vôi mang tên Kim, Mộc, Thủy, Hỏa và Thổ. Nơi đây nổi bật với các hang động tự nhiên, chùa cổ và làng nghề đá mỹ nghệ truyền thống.',
      N'uploads/destinations/ngu-hanh-son.jpg',
      N'["uploads/destinations/ngu-hanh-son-1.jpg","uploads/destinations/ngu-hanh-son-2.jpg"]',
      16.0039, 108.2630, 40000,
      N'Tùy khu vực tham quan'
    ),

    (
      N'Biển đảo',
      N'Biển Mỹ Khê',
      N'Đà Nẵng',
      N'Đường Võ Nguyên Giáp, thành phố Đà Nẵng',
      N'Bãi biển nổi tiếng với bờ cát trắng và làn nước trong xanh.',
      N'Biển Mỹ Khê là một trong những bãi biển nổi bật của Đà Nẵng. Nơi đây có bờ cát dài, không gian thoáng đãng và nhiều hoạt động như tắm biển, thể thao dưới nước và thưởng thức hải sản.',
      N'uploads/destinations/bien-my-khe.jpg',
      N'["uploads/destinations/my-khe-1.jpg","uploads/destinations/my-khe-2.jpg"]',
      16.0544, 108.2470, 0,
      N'Tham quan tự do'
    ),

    (
      N'Danh lam thắng cảnh',
      N'Phong Nha - Kẻ Bàng',
      N'Quảng Trị',
      N'Vườn quốc gia Phong Nha - Kẻ Bàng, tỉnh Quảng Trị',
      N'Vườn quốc gia nổi tiếng với hệ thống hang động và núi đá vôi.',
      N'Phong Nha - Kẻ Bàng sở hữu hệ sinh thái rừng nhiệt đới và hệ thống hang động kỳ vĩ. Du khách có thể khám phá động Phong Nha, động Thiên Đường và nhiều tuyến du lịch sinh thái, mạo hiểm.',
      N'uploads/destinations/phong-nha.jpg',
      N'["uploads/destinations/phong-nha-1.jpg","uploads/destinations/phong-nha-2.jpg"]',
      17.5900, 106.2830, 150000,
      N'Tùy tuyến tham quan'
    ),

    (
      N'Biển đảo',
      N'Cù Lao Chàm',
      N'Đà Nẵng',
      N'Xã đảo Tân Hiệp, thành phố Đà Nẵng',
      N'Quần đảo nổi tiếng với biển xanh và hệ sinh thái san hô.',
      N'Cù Lao Chàm là cụm đảo có cảnh quan biển đảo đẹp và hệ sinh thái đa dạng. Du khách có thể đi cano, lặn ngắm san hô, tham quan làng chài và thưởng thức hải sản địa phương.',
      N'uploads/destinations/cu-lao-cham.jpg',
      N'["uploads/destinations/cu-lao-cham-1.jpg","uploads/destinations/cu-lao-cham-2.jpg"]',
      15.9500, 108.5160, 0,
      N'Theo lịch tàu và tour'
    ),

    (
      N'Di sản văn hóa',
      N'Thánh địa Mỹ Sơn',
      N'Đà Nẵng',
      N'Xã Duy Phú, thành phố Đà Nẵng',
      N'Quần thể đền tháp Chăm Pa cổ được UNESCO công nhận.',
      N'Thánh địa Mỹ Sơn là quần thể kiến trúc tôn giáo của vương quốc Chăm Pa cổ. Những ngôi tháp gạch đỏ với hoa văn điêu khắc tinh xảo phản ánh trình độ kiến trúc và nghệ thuật độc đáo của người Chăm.',
      N'uploads/destinations/thanh-dia-my-son.jpg',
      N'["uploads/destinations/my-son-1.jpg","uploads/destinations/my-son-2.jpg"]',
      15.7640, 108.1240, 150000,
      N'Tùy lịch tham quan di tích'
    ),

    (
      N'Biển đảo',
      N'Vịnh Lăng Cô',
      N'Huế',
      N'Thị trấn Lăng Cô, thành phố Huế',
      N'Vịnh biển nổi bật với bãi cát trắng và núi non bao quanh.',
      N'Vịnh Lăng Cô nằm giữa dãy núi Bạch Mã và biển Đông, nổi bật với bãi cát trắng, đầm nước và cảnh quan thiên nhiên thơ mộng. Đây là điểm dừng chân hấp dẫn trên cung đường du lịch miền Trung.',
      N'uploads/destinations/lang-co.jpg',
      N'["uploads/destinations/lang-co-1.jpg","uploads/destinations/lang-co-2.jpg"]',
      16.2000, 108.0870, 0,
      N'Tham quan tự do'
    ),

    (
      N'Danh lam thắng cảnh',
      N'Ghềnh Đá Đĩa',
      N'Đắk Lắk',
      N'Xã Tuy An Đông, tỉnh Đắk Lắk',
      N'Kỳ quan địa chất với các khối đá bazan xếp chồng như những chiếc đĩa.',
      N'Ghềnh Đá Đĩa gây ấn tượng bởi hàng nghìn cột đá bazan hình lăng trụ được tạo thành từ hoạt động núi lửa cổ. Các khối đá xếp sát nhau tạo nên cảnh quan độc đáo bên bờ biển.',
      N'uploads/destinations/ghenh-da-dia.jpg',
      N'["uploads/destinations/ghenh-da-dia-1.jpg","uploads/destinations/ghenh-da-dia-2.jpg"]',
      13.3660, 109.2910, 40000,
      N'Tùy thời gian hoạt động của điểm tham quan'
    ),

    -- =========================================
    -- MIỀN NAM
    -- =========================================

    (
      N'Di sản văn hóa',
      N'Dinh Độc Lập',
      N'TP. Hồ Chí Minh',
      N'135 Nam Kỳ Khởi Nghĩa, phường Bến Thành, TP. Hồ Chí Minh',
      N'Công trình lịch sử quan trọng gắn liền với ngày thống nhất đất nước.',
      N'Dinh Độc Lập là di tích lịch sử đặc biệt của Việt Nam, gắn liền với sự kiện ngày 30 tháng 4 năm 1975. Công trình có kiến trúc độc đáo, nhiều phòng chức năng được bảo tồn và trưng bày hiện vật lịch sử.',
      N'uploads/destinations/dinh-doc-lap.jpg',
      N'["uploads/destinations/dinh-doc-lap-1.jpg","uploads/destinations/dinh-doc-lap-2.jpg"]',
      10.7770, 106.6953, 40000,
      N'Tùy lịch tham quan di tích'
    ),

    (
      N'Đô thị và kiến trúc',
      N'Nhà thờ Đức Bà',
      N'TP. Hồ Chí Minh',
      N'Công trường Công xã Paris, phường Sài Gòn, TP. Hồ Chí Minh',
      N'Công trình kiến trúc nổi bật mang phong cách Roman và Gothic.',
      N'Nhà thờ Đức Bà là một biểu tượng kiến trúc của TP. Hồ Chí Minh. Công trình nổi bật với hai tháp chuông, mặt tiền gạch đỏ và phong cách kiến trúc châu Âu cổ điển. Lưu ý việc tham quan bên trong phụ thuộc tình trạng trùng tu và lịch hoạt động.',
      N'uploads/destinations/nha-tho-duc-ba.jpg',
      N'["uploads/destinations/duc-ba-1.jpg","uploads/destinations/duc-ba-2.jpg"]',
      10.7798, 106.6990, 0,
      N'Tham quan bên ngoài'
    ),

    (
      N'Di sản văn hóa',
      N'Địa đạo Củ Chi',
      N'TP. Hồ Chí Minh',
      N'Địa đạo Củ Chi, TP. Hồ Chí Minh',
      N'Hệ thống đường hầm lịch sử dưới lòng đất trong thời kỳ kháng chiến.',
      N'Địa đạo Củ Chi là hệ thống đường hầm có giá trị lịch sử đặc biệt, từng được sử dụng làm nơi sinh hoạt, chiến đấu và liên lạc trong thời kỳ kháng chiến. Du khách có thể tìm hiểu cấu trúc địa đạo và các hiện vật lịch sử.',
      N'uploads/destinations/dia-dao-cu-chi.jpg',
      N'["uploads/destinations/cu-chi-1.jpg","uploads/destinations/cu-chi-2.jpg"]',
      11.0510, 106.4930, 35000,
      N'Tùy khu vực tham quan'
    ),

    (
      N'Đô thị và kiến trúc',
      N'Chợ Bến Thành',
      N'TP. Hồ Chí Minh',
      N'Phường Bến Thành, TP. Hồ Chí Minh',
      N'Khu chợ truyền thống nổi tiếng với ẩm thực và hàng hóa đa dạng.',
      N'Chợ Bến Thành là một trong những biểu tượng lâu đời của TP. Hồ Chí Minh. Khu chợ nổi bật với tháp đồng hồ ở cổng chính, các gian hàng thủ công mỹ nghệ, quà lưu niệm, thực phẩm và đặc sản địa phương.',
      N'uploads/destinations/cho-ben-thanh.jpg',
      N'["uploads/destinations/ben-thanh-1.jpg","uploads/destinations/ben-thanh-2.jpg"]',
      10.7725, 106.6980, 0,
      N'Tùy giờ hoạt động của các gian hàng'
    ),

    (
      N'Du lịch tâm linh',
      N'Núi Bà Đen',
      N'Tây Ninh',
      N'Khu du lịch quốc gia Núi Bà Đen, tỉnh Tây Ninh',
      N'Ngọn núi nổi tiếng với quần thể chùa và hệ thống cáp treo.',
      N'Núi Bà Đen là ngọn núi cao nổi bật của Nam Bộ. Nơi đây có cảnh quan thiên nhiên hùng vĩ, quần thể công trình tâm linh và hệ thống cáp treo hiện đại. Du khách có thể ngắm toàn cảnh đồng bằng từ trên cao.',
      N'uploads/destinations/nui-ba-den.jpg',
      N'["uploads/destinations/ba-den-1.jpg","uploads/destinations/ba-den-2.jpg"]',
      11.3830, 106.1680, 0,
      N'Theo lịch hoạt động của cáp treo'
    ),

    (
      N'Du lịch sinh thái',
      N'Chợ nổi Cái Răng',
      N'Cần Thơ',
      N'Quận Cái Răng, thành phố Cần Thơ',
      N'Chợ nổi đặc trưng của văn hóa giao thương miền Tây sông nước.',
      N'Chợ nổi Cái Răng là điểm tham quan tiêu biểu của vùng Đồng bằng sông Cửu Long. Chợ hoạt động trên sông với nhiều ghe thuyền buôn bán nông sản, trái cây và món ăn địa phương. Thời điểm tham quan phổ biến là sáng sớm.',
      N'uploads/destinations/cho-noi-cai-rang.jpg',
      N'["uploads/destinations/cai-rang-1.jpg","uploads/destinations/cai-rang-2.jpg"]',
      10.0050, 105.7510, 0,
      N'Hoạt động nhộn nhịp vào buổi sáng'
    ),

    (
      N'Du lịch sinh thái',
      N'Rừng tràm Trà Sư',
      N'An Giang',
      N'Khu du lịch sinh thái Trà Sư, tỉnh An Giang',
      N'Rừng tràm ngập nước nổi tiếng với thảm bèo xanh và hệ sinh thái chim nước.',
      N'Rừng tràm Trà Sư là khu du lịch sinh thái đặc trưng của miền Tây Nam Bộ. Du khách có thể ngồi xuồng len lỏi qua những con rạch phủ bèo xanh, ngắm rừng tràm và quan sát nhiều loài chim sinh sống trong môi trường tự nhiên.',
      N'uploads/destinations/tra-su.jpg',
      N'["uploads/destinations/tra-su-1.jpg","uploads/destinations/tra-su-2.jpg"]',
      10.5710, 105.0360, 0,
      N'Tùy hoạt động của khu du lịch'
    ),

    (
      N'Biển đảo',
      N'Phú Quốc',
      N'An Giang',
      N'Đặc khu Phú Quốc, tỉnh An Giang',
      N'Đảo du lịch nổi tiếng với bãi biển đẹp, rừng tự nhiên và các khu nghỉ dưỡng.',
      N'Phú Quốc là điểm đến biển đảo nổi tiếng với những bãi biển như Bãi Sao, Bãi Dài, hệ sinh thái rừng và các hoạt động nghỉ dưỡng, lặn biển, khám phá làng chài và thưởng thức hải sản.',
      N'uploads/destinations/phu-quoc.jpg',
      N'["uploads/destinations/phu-quoc-1.jpg","uploads/destinations/phu-quoc-2.jpg"]',
      10.2899, 103.9840, 0,
      N'Tham quan tự do'
    ),

    (
      N'Biển đảo',
      N'Côn Đảo',
      N'TP. Hồ Chí Minh',
      N'Đặc khu Côn Đảo, TP. Hồ Chí Minh',
      N'Quần đảo nổi bật với biển xanh, thiên nhiên hoang sơ và di tích lịch sử.',
      N'Côn Đảo là điểm đến kết hợp du lịch biển, sinh thái và tìm hiểu lịch sử. Nơi đây có các bãi biển hoang sơ, hệ sinh thái biển phong phú và hệ thống di tích nhà tù Côn Đảo.',
      N'uploads/destinations/con-dao.jpg',
      N'["uploads/destinations/con-dao-1.jpg","uploads/destinations/con-dao-2.jpg"]',
      8.6830, 106.6080, 0,
      N'Tùy điểm tham quan'
    ),

    (
      N'Biển đảo',
      N'Mũi Né',
      N'Lâm Đồng',
      N'Phường Mũi Né, tỉnh Lâm Đồng',
      N'Điểm du lịch nổi tiếng với đồi cát, biển xanh và làng chài.',
      N'Mũi Né nổi tiếng với những đồi cát rộng lớn, bãi biển đẹp và các hoạt động thể thao biển. Du khách có thể tham quan Đồi Cát Bay, Suối Tiên, làng chài và thưởng thức hải sản tươi sống.',
      N'uploads/destinations/mui-ne.jpg',
      N'["uploads/destinations/mui-ne-1.jpg","uploads/destinations/mui-ne-2.jpg"]',
      10.9330, 108.2870, 0,
      N'Tham quan tự do'
    )

) AS D
(
    CategoryName,
    Name,
    Province,
    Address,
    ShortDescription,
    Description,
    Image,
    Gallery,
    Latitude,
    Longitude,
    TicketPrice,
    OpeningHours
)
INNER JOIN Category C
    ON C.CategoryName = D.CategoryName;
GO


-- =============================================
-- 3. CHECK DATA
-- =============================================

SELECT
    C.CategoryId,
    C.CategoryName,
    COUNT(D.DestinationId) AS TotalDestinations
FROM Category C
LEFT JOIN Destination D
    ON C.CategoryId = D.CategoryId
GROUP BY C.CategoryId, C.CategoryName
ORDER BY C.CategoryId;

SELECT
    D.DestinationId,
    C.CategoryName,
    D.Name,
    D.Province,
    D.TicketPrice
FROM Destination D
INNER JOIN Category C
    ON D.CategoryId = C.CategoryId
ORDER BY D.DestinationId;
GO

