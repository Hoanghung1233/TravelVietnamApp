import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:travel_vn/models/login_model.dart';
import 'package:travel_vn/models/auth_models.dart';
import 'package:travel_vn/repositories/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Web Client ID dùng làm serverClientId.
  static const String _googleWebClientId =
      '401710603851-ba988ij1csm8b633m65racuij5rnlf62.apps.googleusercontent.com';

  // Khởi tạo Google Sign-In đúng một lần.
  late final Future<void> _googleInitialization;

  @override
  void initState() {
    super.initState();

    _googleInitialization = GoogleSignIn.instance.initialize(
      serverClientId: _googleWebClientId,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Hiển thị thông báo
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ĐĂNG NHẬP BẰNG EMAIL VÀ MẬT KHẨU
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Vui lòng nhập email và mật khẩu');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthRepository.login(
        LoginModel(
          email: email,
          password: password,
        ),
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.pushReplacementNamed(context, '/profile');
      } else {
        _showMessage(result.message ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      _showMessage('Lỗi đăng nhập: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ĐĂNG NHẬP BẰNG GOOGLE
  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Chờ Google Sign-In khởi tạo hoàn tất.
      await _googleInitialization;

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        _showMessage(
            'Nền tảng này chưa hỗ trợ đăng nhập Google theo cách hiện tại');
        return;
      }

      // Mở màn hình chọn tài khoản Google.
      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();

      // Lấy Google ID Token.
      final String? idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        _showMessage('Không lấy được Google ID Token');
        return;
      }

      // Gửi ID Token đến backend để xác thực.
      final result = await AuthRepository.socialLogin(
        SocialLoginModel(
          provider: 'google',
          accessToken: idToken,
        ),
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.pushReplacementNamed(context, '/profile');
      } else {
        _showMessage(result.message ?? 'Đăng nhập Google thất bại');
      }
    } catch (e, stackTrace) {
      debugPrint('========== GOOGLE LOGIN ERROR ==========');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng nhập Google thất bại: $e'),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // LOGO
                  const Icon(
                    Icons.travel_explore,
                    size: 75,
                    color: Color(0xFF2196F3),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'TravelVN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Khám phá Việt Nam cùng chúng tôi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // TIÊU ĐỀ
                  const Text(
                    'Đăng nhập',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Chào mừng bạn quay trở lại TravelVN!',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 25),

                  // EMAIL
                  const Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Nhập địa chỉ email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // PASSWORD
                  const Text(
                    'Mật khẩu',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Nhập mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // QUÊN MẬT KHẨU
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pushNamed(
                                context,
                                '/forgot-password',
                              );
                            },
                      child: const Text('Quên mật khẩu?'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // NÚT ĐĂNG NHẬP
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 23,
                              height: 23,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'ĐĂNG NHẬP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // HOẶC
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          'HOẶC',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ĐĂNG NHẬP GOOGLE
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Đăng nhập bằng Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ĐĂNG KÝ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Bạn chưa có tài khoản?'),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pushNamed(context, '/register');
                              },
                        child: const Text(
                          'Đăng ký ngay',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
