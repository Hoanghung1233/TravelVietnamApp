import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Các import của chức năng Booking
import 'pages/admin_booking_page.dart';
import 'pages/booking_page.dart';
import 'services/session_helper.dart';

// Các import của chức năng Destination
import 'models/destination.dart';
import 'pages/destination_admin.dart';
import 'pages/destination_detail_page.dart';
import 'pages/destination_map.dart';
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
        ),
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
  '/favorites': (_) => const TabPage(title: 'Yêu thích'),

  // Chức năng đặt chỗ: mở giao diện Member/Admin
  '/bookings': (_) => const BookingAppShell(),

  // Trang cá nhân
  '/account': (context) => TabPage(
        title: 'Cá nhân',
        action: FilledButton.icon(
          onPressed: () =>
              Navigator.of(context).pushNamed('/destinations/admin'),
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
          Destination? item
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
        appBar: AppBar(
          title: const Text('Địa điểm du lịch'),
        ),
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).popUntil(
              (route) => route.isFirst,
            ),
            child: const Text('Quay về trang chủ'),
          ),
        ),
      );
}

// Giao diện chuyển đổi giữa Member và Admin của chức năng Booking
class BookingAppShell extends StatefulWidget {
  const BookingAppShell({super.key});

  @override
  State<BookingAppShell> createState() => _BookingAppShellState();
}

class _BookingAppShellState extends State<BookingAppShell> {
  int selectedIndex = 0;

  String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5149';

  final tokenController = TextEditingController();
  final urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    tokenController.dispose();
    urlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final token = await SessionHelper.token;
    final url = await SessionHelper.baseUrl;

    if (!mounted) return;

    setState(() {
      baseUrl = url ?? baseUrl;
      urlController.text = baseUrl;
      tokenController.text = token ?? '';
    });
  }

  Future<void> _settings() async {
    final formKey = GlobalKey<FormState>();

    tokenController.text = await SessionHelper.token ?? '';

    urlController.text = await SessionHelper.baseUrl ?? baseUrl;

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kết nối Backend'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ API',
                    hintText: 'http://10.0.2.2:5149',
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: (v) => (v == null ||
                          !(v.startsWith('http://') ||
                              v.startsWith('https://')))
                      ? 'Nhập URL hợp lệ'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tokenController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'JWT Token',
                    hintText: 'Dán token lấy từ API đăng nhập',
                    prefixIcon: Icon(Icons.key),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dùng Member Token khi ở màn hình Member; '
                  'dùng Admin Token khi ở màn hình Admin. '
                  'Token được lưu an toàn trên thiết bị.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await SessionHelper.clearToken();

              if (!dialogContext.mounted) return;

              Navigator.pop(dialogContext);
              await _loadSettings();
            },
            child: const Text('Xóa Token'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              await SessionHelper.saveBaseUrl(
                urlController.text.trim(),
              );

              final token = tokenController.text.trim();

              if (token.isEmpty) {
                await SessionHelper.clearToken();
              } else {
                await SessionHelper.saveToken(token);
              }

              if (!dialogContext.mounted) return;

              Navigator.pop(dialogContext);

              await _loadSettings();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Đã lưu cấu hình kết nối.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Lưu cấu hình'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      BookingPage(),
      AdminBookingPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: selectedIndex == 0 ? pages[0] : pages[1],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.confirmation_number_outlined,
            ),
            selectedIcon: Icon(
              Icons.confirmation_number,
            ),
            label: 'Member',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.admin_panel_settings_outlined,
            ),
            selectedIcon: Icon(
              Icons.admin_panel_settings,
            ),
            label: 'Admin',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Cấu hình API và Token',
        onPressed: _settings,
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}
