import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Authentication và tài khoản
import 'package:travel_vn/pages/category_page.dart';
import 'package:travel_vn/pages/login_page.dart';
import 'package:travel_vn/pages/forgot_password_page.dart';
import 'package:travel_vn/pages/profile_page.dart';
import 'package:travel_vn/pages/register_page.dart';

// Booking
import 'package:travel_vn/pages/admin_booking_page.dart';
import 'package:travel_vn/pages/booking_page.dart';

// Destination
import 'package:travel_vn/models/destination.dart';
import 'package:travel_vn/pages/destination_admin.dart';
import 'package:travel_vn/pages/destination_detail_page.dart';
import 'package:travel_vn/pages/destination_map.dart';
import 'package:travel_vn/pages/favorites_page.dart';
import 'package:travel_vn/pages/home_page.dart';
import 'package:travel_vn/pages/related_destinations_page.dart';
import 'package:travel_vn/services/session_helper.dart';
import 'package:travel_vn/repositories/destination_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await SessionHelper.initialize();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(seedColor: const Color(0xFF087E75));
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.outlineVariant),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TravelVN',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colors,
        scaffoldBackgroundColor: const Color(0xFFF7F9F9),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 46),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 44),
            side: BorderSide(color: colors.outlineVariant),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F9F9),
          foregroundColor: Color(0xFF172B2A),
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: fieldBorder,
          enabledBorder: fieldBorder,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),

      // Trang khởi động
      initialRoute: '/',

      // Các đường dẫn điều hướng
      routes: {
        // Authentication
        '/login': (context) => LoginPage(
              returnToCaller:
                  ModalRoute.of(context)?.settings.arguments == true,
            ),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (_) => const ForgotPasswordPage(),
        '/profile': (context) => const ProfilePage(),
        '/categories': (context) => const CategoryPage(
              title: 'Danh mục du lịch',
            ),

        // Các trang du lịch
        ...destinationRoutes,
      },
    );
  }
}

// Các đường dẫn điều hướng của chức năng du lịch
final destinationRoutes = <String, WidgetBuilder>{
  // Trang chủ du lịch
  '/': (_) => const DestinationsPage(),

  // Tìm kiếm địa điểm
  '/destinations/search': (_) => const DestinationsPage(focusSearch: true),

  // Danh sách yêu thích
  '/favorites': (_) => const FavoritesPage(),

  // Trang đặt vé của người dùng
  '/bookings': (_) => const BookingPage(),

  // Trang cá nhân
  '/account': (_) => const ProfilePage(),

  // Quản trị địa điểm du lịch
  '/destinations/admin': (_) => const DestinationsPage(management: true),

  // Chi tiết địa điểm
  '/destination-detail': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args case (DestinationRepository repository, Destination item)) {
      return DestinationDetailPage(
        repository: repository,
        item: item,
      );
    }

    return const _MissingDestination();
  },

  // Các địa điểm liên quan
  '/related-destinations': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args case (DestinationRepository repository, Destination item)) {
      return RelatedDestinationsPage(
        repository: repository,
        current: item,
      );
    }

    return const _MissingDestination();
  },

  // Bản đồ địa điểm
  '/destination-map': (context) {
    final item = ModalRoute.of(context)?.settings.arguments;

    if (item is Destination &&
        item.latitude != null &&
        item.longitude != null) {
      return DestinationMapPage(
        name: item.name,
        latitude: item.latitude!,
        longitude: item.longitude!,
      );
    }

    return const _MissingDestination();
  },

  // Đăng nhập quản trị địa điểm
  '/destinations/admin/login': (context) {
    final repository = ModalRoute.of(context)?.settings.arguments;

    return AdminLoginPage(
      repository: repository is DestinationRepository
          ? repository
          : DestinationRepository(),
    );
  },

  // Chỉnh sửa địa điểm
  '/destinations/admin/edit': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args
        case (
          DestinationRepository repository,
          String token,
          List<Map<String, dynamic>> categories,
          Destination? item,
        )) {
      return DestinationEditor(
        repository: repository,
        token: token,
        categories: categories,
        item: item,
      );
    }

    return const _MissingDestination();
  },

  // Trang đặt chỗ Member
  '/booking': (_) => const BookingPage(),

  // Trang quản trị đặt chỗ Admin
  '/admin-booking': (_) => const AdminBookingPage(),
};

// Giao diện khi không nhận được dữ liệu địa điểm hợp lệ
class _MissingDestination extends StatelessWidget {
  const _MissingDestination();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Địa điểm du lịch'),
      ),
      body: Center(
        child: TextButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Quay về trang chủ'),
        ),
      ),
    );
  }
}
