import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:travel_vn/pages/admin_category_page.dart';
import 'package:travel_vn/pages/admin_members_page.dart';
import 'package:travel_vn/pages/category_page.dart';
import 'package:travel_vn/pages/change_password_page.dart';
import 'package:travel_vn/pages/forgot_password_page.dart';
import 'package:travel_vn/pages/login_page.dart';
import 'package:travel_vn/pages/profile_page.dart';
import 'package:travel_vn/pages/register_page.dart';
import 'package:travel_vn/pages/update_email_page.dart';

// Import các trang TravelVN tại đây

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TravelVN',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/profile': (context) => const ProfilePage(),
        '/categories': (context) => const CategoryPage(
              title: 'Danh mục du lịch',
            ),
      },
    );
  }
}
