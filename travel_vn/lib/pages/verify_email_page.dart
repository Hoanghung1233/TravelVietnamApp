import 'package:flutter/material.dart';
import 'package:travel_vn/models/auth_models.dart';
import 'package:travel_vn/repositories/auth_repository.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;

  const VerifyEmailPage({
    super.key,
    required this.email,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _isLoading = false;

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthRepository.verifyEmail(
        VerifyOtpModel(
          email: widget.email,
          code: _codeController.text.trim(),
        ),
      );

      if (!mounted) return;

      final success = result['success'] == true || result['Success'] == true;

      final message = result['message']?.toString() ??
          result['Message']?.toString() ??
          'Xác thực email thất bại';

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác thực email thành công.'),
          ),
        );

        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        _showMessage(message);
      }
    } catch (e) {
      _showMessage('Xác thực thất bại: $e');
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
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực email'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 76,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Kiểm tra email của bạn',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mã OTP đã được gửi đến:',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Mã OTP',
                      hintText: 'Nhập mã xác thực',
                      prefixIcon: Icon(Icons.password),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập mã OTP';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isLoading ? null : _verifyEmail,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('XÁC NHẬN'),
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
