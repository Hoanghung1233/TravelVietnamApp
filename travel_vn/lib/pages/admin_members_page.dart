import 'package:flutter/material.dart';
import 'package:travel_vn/models/member.dart';
import 'package:travel_vn/repositories/member_repository.dart';
import 'package:travel_vn/pages/admin_member_detail_page.dart';

class AdminMembersPage extends StatefulWidget {
  const AdminMembersPage({super.key});

  @override
  State<AdminMembersPage> createState() => _AdminMembersPageState();
}

class _AdminMembersPageState extends State<AdminMembersPage> {
  List<Member> _members = [];
  List<Member> _filteredMembers = [];
  bool _isLoading = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);

    try {
      final result = await MemberRepository.getMembers();

      if (!mounted) return;

      setState(() {
        _members = result;
        _filterMembers();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải danh sách thành viên: $e')),
      );
    }
  }

  void _filterMembers() {
    final keyword = _searchText.toLowerCase();

    _filteredMembers = _members.where((member) {
      final name =
          '${member.surname ?? ''} ${member.givenName ?? ''}'.toLowerCase();
      final email = (member.email ?? '').toLowerCase();

      return name.contains(keyword) || email.contains(keyword);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
      _filterMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thành viên'),
        actions: [
          IconButton(
            onPressed: _loadMembers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMembers.isEmpty
                    ? const Center(child: Text('Không tìm thấy thành viên'))
                    : RefreshIndicator(
                        onRefresh: _loadMembers,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filteredMembers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final member = _filteredMembers[index];
                            final fullName =
                                '${member.surname ?? ''} ${member.givenName ?? ''}'
                                    .trim();

                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: member.avatar != null &&
                                          member.avatar!.isNotEmpty
                                      ? NetworkImage(member.avatar!)
                                      : null,
                                  child: member.avatar == null ||
                                          member.avatar!.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(
                                  fullName.isEmpty
                                      ? 'Chưa cập nhật tên'
                                      : fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(member.email ?? 'Chưa có email'),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text(member.role),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          member.isEmailVerified
                                              ? Icons.verified
                                              : Icons.warning_amber,
                                          size: 16,
                                          color: member.isEmailVerified
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          member.isEmailVerified
                                              ? 'Đã xác minh'
                                              : 'Chưa xác minh',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AdminMemberDetailPage(member: member),
                                    ),
                                  );
                                  _loadMembers();
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
