import 'package:flutter/material.dart';
import 'package:travel_vn/models/member.dart';
import 'package:travel_vn/repositories/member_repository.dart';
import 'package:travel_vn/repositories/auth_repository.dart';

import 'package:travel_vn/pages/login_page.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';
import 'update_email_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Member? _member;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final member = await MemberRepository.getProfile();

      if (!mounted) return;

      setState(() {
        _member = member;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Không thể tải thông tin tài khoản: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AuthRepository.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng xuất thất bại: $e')),
      );
    }
  }

  void _openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) {
      _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản của tôi'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadProfile,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : _member == null
                  ? const Center(
                      child: Text('Không tìm thấy thông tin tài khoản'),
                    )
                  : _buildProfile(),
    );
  }

  Widget _buildProfile() {
    final member = _member!;

    final fullName = [
      member.surname ?? '',
      member.givenName ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' ');

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Center(
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage:
                  member.avatar != null && member.avatar!.isNotEmpty
                      ? NetworkImage(member.avatar!)
                      : null,
              child: member.avatar == null || member.avatar!.isEmpty
                  ? const Icon(Icons.person, size: 55)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName.isEmpty ? 'Người dùng TravelVN' : fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            member.email ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Thông tin cá nhân'),
          _buildInfoTile(
            icon: Icons.person_outline,
            title: 'Họ và tên',
            value: fullName.isEmpty ? 'Chưa cập nhật' : fullName,
          ),
          _buildInfoTile(
            icon: Icons.email_outlined,
            title: 'Email',
            value: member.email ?? 'Chưa cập nhật',
          ),
          _buildInfoTile(
            icon: Icons.phone_outlined,
            title: 'Số điện thoại',
            value: member.phone?.isNotEmpty == true
                ? member.phone!
                : 'Chưa cập nhật',
          ),
          _buildInfoTile(
            icon: Icons.verified_user_outlined,
            title: 'Vai trò',
            value: member.role,
          ),
          _buildInfoTile(
            icon: Icons.mark_email_read_outlined,
            title: 'Trạng thái email',
            value: member.isEmailVerified ? 'Đã xác thực' : 'Chưa xác thực',
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Quản lý tài khoản'),
          _buildActionTile(
            icon: Icons.edit_outlined,
            title: 'Chỉnh sửa hồ sơ',
            subtitle: 'Cập nhật họ tên, số điện thoại, ảnh đại diện',
            onTap: () => _openPage(
              EditProfilePage(member: member),
            ),
          ),
          _buildActionTile(
            icon: Icons.lock_outline,
            title: 'Mật khẩu',
            subtitle: 'Đổi hoặc thiết lập mật khẩu',
            onTap: () => _openPage(const ChangePasswordPage()),
          ),
          _buildActionTile(
            icon: Icons.email_outlined,
            title: 'Thay đổi email',
            subtitle: 'Cập nhật email và xác thực bằng OTP',
            onTap: () => _openPage(const UpdateEmailPage()),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'ĐĂNG XUẤT',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
