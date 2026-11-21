import 'package:flutter/material.dart';

import 'admin_booking_page.dart';
import 'booking_page.dart';
import 'session_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TravelBookingApp());
}

class TravelBookingApp extends StatelessWidget {
  const TravelBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF087E75);
    return MaterialApp(
      title: 'TravelVN - Booking',
      debugShowCheckedModeBanner: false,
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
      home: const BookingAppShell(),
    );
  }
}

class BookingAppShell extends StatefulWidget {
  const BookingAppShell({super.key});

  @override
  State<BookingAppShell> createState() => _BookingAppShellState();
}

class _BookingAppShellState extends State<BookingAppShell> {
  int selectedIndex = 0;
  bool hasToken = false;
  String baseUrl = 'http://10.0.2.2:5149';
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
      hasToken = token != null && token.isNotEmpty;
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
                  validator: (v) => (v == null || !v.startsWith('http'))
                      ? 'Nhập URL bắt đầu bằng http:// hoặc https://'
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
                  'Dùng Member Token khi ở màn hình Member; dùng Admin Token khi ở màn hình Admin. Token được lưu an toàn trên thiết bị.',
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
              await SessionHelper.saveBaseUrl(urlController.text.trim());
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
                  const SnackBar(content: Text('Đã lưu cấu hình kết nối.')),
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
    final pages = const [BookingPage(), AdminBookingPage()];
    return Scaffold(
      body: SafeArea(child: selectedIndex == 0 ? pages[0] : pages[1]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Member',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
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
