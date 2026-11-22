import 'package:flutter/material.dart';
import 'package:travel_vn/models/auth_models.dart';
import 'package:travel_vn/repositories/auth_repository.dart';

class UpdateEmailPage extends StatefulWidget {
  const UpdateEmailPage({super.key});

  @override
  State<UpdateEmailPage> createState() => _UpdateEmailPageState();
}

class _UpdateEmailPageState extends State<UpdateEmailPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthRepository.sendEmailVerification(
        UpdateEmailModel(
          email: _emailController.text.trim(),
        ),
      );

      if (!mounted) return;

      setState(() {
        _otpSent = true;
      });

      _showMessage('Đã gửi yêu cầu OTP đến email mới');
    } catch (e) {
      _showMessage('Không thể gửi OTP: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyEmail() async {
    if (_codeController.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập mã OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthRepository.verifyNewEmail(
        VerifyOtpModel(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
        ),
      );

      if (!mounted) return;

      _showMessage('Cập nhật email thành công');

      Navigator.pop(context);
    } catch (e) {
      _showMessage('Xác thực email thất bại: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thay đổi email'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cập nhật địa chỉ email',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nhập địa chỉ email mới. Một mã OTP sẽ được gửi đến '
                  'địa chỉ này để xác thực.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailController,
                  readOnly: _otpSent,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email mới',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập email mới';
                    }
                    if (!value.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (!_otpSent)
                  FilledButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('GỬI MÃ OTP'),
                  ),
                if (_otpSent) ...[
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Mã OTP',
                      prefixIcon: Icon(Icons.verified_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isLoading ? null : _verifyEmail,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('XÁC THỰC EMAIL MỚI'),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _otpSent = false;
                              _codeController.clear();
                            });
                          },
                    child: const Text('Thay đổi địa chỉ email'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
