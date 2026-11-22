import 'package:flutter/material.dart';
import 'package:travel_vn/models/member.dart';
import 'package:travel_vn/models/update_role_model.dart';
import 'package:travel_vn/repositories/member_repository.dart';

class AdminMemberDetailPage extends StatefulWidget {
  final Member member;

  const AdminMemberDetailPage({
    super.key,
    required this.member,
  });

  @override
  State<AdminMemberDetailPage> createState() => _AdminMemberDetailPageState();
}

class _AdminMemberDetailPageState extends State<AdminMemberDetailPage> {
  late String _selectedRole;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.member.role;
  }

  Future<void> _updateRole() async {
    if (widget.member.memberId == null || widget.member.memberId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã thành viên')),
      );
      return;
    }

    final newRole = _selectedRole == 'Admin' ? Role.Admin : Role.Member;

    setState(() => _isSaving = true);

    try {
      final result = await MemberRepository.updateRole(
        UpdateRoleModel(
          memberId: widget.member.memberId!,
          role: newRole,
        ),
      );

      if (!mounted) return;

      setState(() => _isSaving = false);

      final success = result['success'] == true || result['Success'] == true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Cập nhật quyền thành công'
                : result['message']?.toString() ??
                    result['Message']?.toString() ??
                    'Không thể cập nhật quyền',
          ),
        ),
      );

      if (success) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật quyền: $e')),
      );
    }
  }

  Widget _infoItem(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
      subtitle: Text(
        value.isEmpty ? 'Chưa cập nhật' : value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final fullName = '${member.surname ?? ''} ${member.givenName ?? ''}'.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thành viên'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundImage:
                  member.avatar != null && member.avatar!.isNotEmpty
                      ? NetworkImage(member.avatar!)
                      : null,
              child: member.avatar == null || member.avatar!.isEmpty
                  ? const Icon(Icons.person, size: 48)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              fullName.isEmpty ? 'Chưa cập nhật tên' : fullName,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                _infoItem(
                  'Mã thành viên',
                  member.memberId ?? '',
                  Icons.badge_outlined,
                ),
                _infoItem(
                  'Họ',
                  member.surname ?? '',
                  Icons.person_outline,
                ),
                _infoItem(
                  'Tên',
                  member.givenName ?? '',
                  Icons.person,
                ),
                _infoItem(
                  'Email',
                  member.email ?? '',
                  Icons.email_outlined,
                ),
                _infoItem(
                  'Số điện thoại',
                  member.phone ?? '',
                  Icons.phone_outlined,
                ),
                _infoItem(
                  'Trạng thái email',
                  member.isEmailVerified ? 'Đã xác minh' : 'Chưa xác minh',
                  Icons.verified_user_outlined,
                ),
                _infoItem(
                  'Ngày tạo tài khoản',
                  member.createdAt?.toLocal().toString() ?? '',
                  Icons.calendar_today_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Phân quyền tài khoản',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'Vai trò',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.admin_panel_settings_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Member',
                child: Text('Member - Thành viên'),
              ),
              DropdownMenuItem(
                value: 'Admin',
                child: Text('Admin - Quản trị viên'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedRole = value);
              }
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving || _selectedRole == member.role
                  ? null
                  : _updateRole,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Đang cập nhật...' : 'Lưu thay đổi'),
            ),
          ),
        ],
      ),
    );
  }
}
