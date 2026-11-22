import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Các import của chức năng Booking
import 'pages/admin_booking_page.dart';
import 'pages/booking_page.dart';

// Các import của chức năng Destination
import 'models/destination.dart';
import 'pages/destination_admin.dart';
import 'pages/destination_detail_page.dart';
import 'pages/destination_map.dart';
import 'pages/favorites_page.dart';
import 'pages/home_page.dart';
import 'pages/related_destinations_page.dart';
import 'pages/tab_page.dart';
import 'repositories/destination_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF087E75);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TravelVN',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: const Color(0xFFF7F9F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F9F9),
          foregroundColor: Color(0xFF172B2A),
          centerTitle: false,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: destinationRoutes,
    );
  }
}

// Các đường dẫn điều hướng của toàn bộ ứng dụng
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
  '/account': (context) => TabPage(
    title: 'Cá nhân',
    action: FilledButton.icon(
      onPressed: () => Navigator.of(context).pushNamed('/destinations/admin'),
      icon: const Icon(Icons.admin_panel_settings_outlined),
      label: const Text('Quản trị địa điểm'),
    ),
  ),

  // Quản trị địa điểm du lịch
  '/destinations/admin': (_) => const DestinationsPage(management: true),

  // Chi tiết địa điểm
  '/destination-detail': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args case (DestinationRepository repository, Destination item)) {
      return DestinationDetailPage(repository: repository, item: item);
    }

    return const _MissingDestination();
  },

  // Các địa điểm liên quan
  '/related-destinations': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args case (DestinationRepository repository, Destination item)) {
      return RelatedDestinationsPage(repository: repository, current: item);
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

    if (args case (
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

// Giao diện hiển thị khi không nhận được dữ liệu địa điểm hợp lệ
class _MissingDestination extends StatelessWidget {
  const _MissingDestination();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Địa điểm du lịch')),
    body: Center(
      child: TextButton(
        onPressed: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        child: const Text('Quay về trang chủ'),
      ),
    ),
  );
}
