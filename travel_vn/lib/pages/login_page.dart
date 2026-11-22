import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:travel_vn/models/login_model.dart';
import 'package:travel_vn/services/session_helper.dart';
import 'package:travel_vn/repositories/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage(
      {super.key, this.returnToCaller = false, this.title = 'Đăng nhập'});

  final bool returnToCaller;
  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  ({Uri url, String key})? _socialAttempt;
  String? _socialProvider;

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
        _finishLogin();
      } else {
        _showMessage(result.message);
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

  Future<void> _prepareSocial(String provider) async {
    setState(() {
      _isLoading = true;
      _socialAttempt = null;
      _socialProvider = null;
    });
    try {
      final attempt =
          await AuthRepository.startBrowserLogin(provider.toLowerCase());
      if (!mounted) return;
      setState(() {
        _socialAttempt = attempt;
        _socialProvider = provider;
      });
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openSocialLogin() async {
    final attempt = _socialAttempt;
    if (attempt == null || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final opened = await launchUrl(
        attempt.url,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!opened) {
        _showMessage(
            'Không mở được trình duyệt. Hãy cho phép mở tab mới rồi thử lại.');
        return;
      }
      final deadline = DateTime.now().add(const Duration(minutes: 4));
      while (mounted &&
          _socialAttempt == attempt &&
          DateTime.now().isBefore(deadline)) {
        final result = await AuthRepository.pollBrowserLogin(attempt.key);
        if (!mounted || _socialAttempt != attempt) return;
        if (result != null) {
          final token = result.token;
          if (!result.success || token == null || token.isEmpty) {
            _showMessage(result.message);
            return;
          }
          await SessionHelper.saveToken(token);
          if (mounted) _finishLogin();
          return;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      if (mounted && _socialAttempt == attempt) {
        _showMessage('Phiên đăng nhập đã hết giờ. Vui lòng thử lại.');
      }
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && _socialAttempt == attempt) {
        setState(() {
          _isLoading = false;
          _socialAttempt = null;
          _socialProvider = null;
        });
      }
    }
  }

  void _cancelSocialLogin() => setState(() {
        _isLoading = false;
        _socialAttempt = null;
        _socialProvider = null;
      });

  void _finishLogin() {
    if (widget.returnToCaller) {
      Navigator.of(context).pop(SessionHelper.currentToken);
    } else {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (_) => false),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Về trang chủ'),
          ),
          const SizedBox(width: 12),
        ],
      ),
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
                  Text(
                    widget.title,
                    style: const TextStyle(
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
                          : Text(
                              widget.title,
                              style: const TextStyle(
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

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final provider in const [
                        'Google',
                        'Facebook',
                        'Zalo'
                      ])
                        OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _prepareSocial(provider),
                          child: Text(provider),
                        ),
                    ],
                  ),
                  if (_socialAttempt != null) ...[
                    const SizedBox(height: 12),
                    if (_isLoading)
                      const Text(
                          'Hoàn tất đăng nhập trong tab trình duyệt mới.'),
                    if (!_isLoading)
                      FilledButton(
                        onPressed: _openSocialLogin,
                        child: Text('Mở trang đăng nhập $_socialProvider'),
                      ),
                    TextButton(
                      onPressed: _cancelSocialLogin,
                      child: const Text('Hủy đăng nhập mạng xã hội'),
                    ),
                  ],
                  const SizedBox(height: 25),

                  // ĐĂNG KÝ
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
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
