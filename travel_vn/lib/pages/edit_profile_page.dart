import 'package:flutter/material.dart';
import 'package:travel_vn/models/member.dart';
import 'package:travel_vn/repositories/member_repository.dart';

class EditProfilePage extends StatefulWidget {
  final Member member;

  const EditProfilePage({
    super.key,
    required this.member,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _surnameController;
  late final TextEditingController _givenNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _avatarController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _surnameController =
        TextEditingController(text: widget.member.surname ?? '');
    _givenNameController =
        TextEditingController(text: widget.member.givenName ?? '');
    _phoneController = TextEditingController(text: widget.member.phone ?? '');
    _avatarController = TextEditingController(text: widget.member.avatar ?? '');
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedMember = Member(
        memberId: widget.member.memberId,
        surname: _surnameController.text.trim(),
        givenName: _givenNameController.text.trim(),
        email: widget.member.email,
        phone: _phoneController.text.trim(),
        avatar: _avatarController.text.trim(),
        role: widget.member.role,
        isEmailVerified: widget.member.isEmailVerified,
        createdAt: widget.member.createdAt,
      );

      final success = await MemberRepository.updateProfile(updatedMember);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ thành công'),
          ),
        );
        Navigator.pop(context);
      } else {
        _showMessage('Cập nhật hồ sơ thất bại');
      }
    } catch (e) {
      _showMessage('Lỗi cập nhật hồ sơ: $e');
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
    _surnameController.dispose();
    _givenNameController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
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
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: _avatarController.text.isNotEmpty
                        ? NetworkImage(_avatarController.text)
                        : null,
                    child: _avatarController.text.isEmpty
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _surnameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _givenNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _avatarController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Đường dẫn ảnh đại diện',
                    hintText: 'https://example.com/avatar.jpg',
                    prefixIcon: Icon(Icons.image_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: widget.member.email ?? '',
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                    helperText: 'Thay đổi email tại mục Thay đổi email',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('LƯU THAY ĐỔI'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
