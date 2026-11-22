import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../widgets/bottom_navbar.dart';

import '../models/destination.dart';
import '../repositories/destination_repository.dart';
import '../repositories/member_repository.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key, required this.repository});
  final DestinationRepository repository;

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await widget.repository.login(
        _email.text.trim(),
        _password.text,
      );
      final member = await MemberRepository.getProfile(token: token);
      if (!mounted) return;
      if (member.role != 'Admin') {
        setState(() {
          _busy = false;
          _error = 'Tài khoản này không có quyền quản trị.';
        });
        return;
      }
      Navigator.pop(context, token);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Không đăng nhập được. Kiểm tra tài khoản và kết nối API.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: const BottomNavbar(),
        appBar: AppBar(title: const Text('Đăng nhập quản trị')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
            ),
            if (_error != null) Text(_error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _login,
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      );
}

class DestinationEditor extends StatefulWidget {
  const DestinationEditor({
    super.key,
    required this.repository,
    required this.token,
    required this.categories,
    this.item,
  });

  final DestinationRepository repository;
  final String token;
  final List<Map<String, dynamic>> categories;
  final Destination? item;

  @override
  State<DestinationEditor> createState() => _DestinationEditorState();
}

class _DestinationEditorState extends State<DestinationEditor> {
  static const _labels = {
    'name': 'Tên địa điểm',
    'province': 'Tỉnh/thành',
    'address': 'Địa chỉ',
    'shortDescription': 'Giới thiệu ngắn',
    'description': 'Mô tả chi tiết',
    'ticketPrice': 'Giá vé',
    'openingHours': 'Giờ mở cửa',
    'latitude': 'Vĩ độ',
    'longitude': 'Kinh độ',
  };
  final _form = GlobalKey<FormState>();
  late final _fields = {
    for (final key in _labels.keys)
      key: TextEditingController(text: widget.item?.text(key) ?? ''),
  };
  late int? _categoryId = widget.item?.data['categoryId'] as int?;
  PlatformFile? _image;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (mounted && files.isNotEmpty) setState(() => _image = files.first);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không mở được bộ chọn ảnh');
    }
  }

  static const _lengthLimits = {
    'name': 150,
    'province': 100,
    'address': 255,
    'shortDescription': 500,
    'openingHours': 100,
  };

  static const _numericLimits = {
    'ticketPrice': (min: 0, max: 9999999999999999.99, decimals: 2),
    'latitude': (min: -90, max: 90, decimals: 7),
    'longitude': (min: -180, max: 180, decimals: 7),
  };

  String? _validate(String key, String value) {
    final input = value.trim();
    if (input.isEmpty) {
      return key == 'name' || key == 'province' ? 'Bắt buộc' : null;
    }

    final length = _lengthLimits[key];
    if (length != null && input.length > length) {
      return 'Tối đa $length ký tự.';
    }

    final limits = _numericLimits[key];
    if (limits == null) return null;
    final number = input.replaceAll(',', '.');
    if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(number)) {
      return 'Nhập số, ví dụ 20.95. Có thể để trống.';
    }
    final parsed = double.tryParse(number);
    if (parsed == null ||
        !parsed.isFinite ||
        parsed < limits.min ||
        parsed > limits.max ||
        (key == 'ticketPrice' &&
            number.split('.').first.replaceFirst(RegExp(r'^0+'), '').length >
                16)) {
      return switch (key) {
        'latitude' => 'Vĩ độ phải từ -90 đến 90.',
        'longitude' => 'Kinh độ phải từ -180 đến 180.',
        _ => 'Giá vé phải không âm và tối đa 16 chữ số trước dấu thập phân.',
      };
    }
    if (number.contains('.') &&
        number.split('.').last.length > limits.decimals) {
      return 'Tối đa ${limits.decimals} chữ số thập phân.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final chosenImage = _image;
    if (_categoryId == null || (widget.item == null && chosenImage == null)) {
      setState(() => _error = 'Chọn danh mục và ảnh cho địa điểm.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final fields = {
        'categoryId': '$_categoryId',
        for (final entry in _fields.entries)
          if (entry.key != 'ticketPrice' || entry.value.text.trim().isNotEmpty)
            entry.key: _numericLimits.containsKey(entry.key)
                ? entry.value.text.trim().replaceAll(',', '.')
                : entry.value.text.trim(),
      };
      await widget.repository.save(
        widget.token,
        widget.item?.id,
        fields,
        filename: chosenImage?.name,
        image: await chosenImage?.readAsBytes(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: const BottomNavbar(),
        appBar: AppBar(
          title: Text(widget.item == null ? 'Thêm địa điểm' : 'Sửa địa điểm'),
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: ((MediaQuery.sizeOf(context).width - 720) / 2)
                  .clamp(16.0, double.infinity),
            ),
            children: [
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                items: [
                  for (final item in widget.categories)
                    DropdownMenuItem(
                      value: item['categoryId'] as int,
                      child: Text(item['categoryName'] as String),
                    ),
                ],
                onChanged: _busy ? null : (value) => _categoryId = value,
              ),
              for (final entry in _labels.entries) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fields[entry.key],
                  decoration: InputDecoration(labelText: entry.value),
                  maxLines: entry.key == 'description' ? 4 : 1,
                  keyboardType: _numericLimits.containsKey(entry.key)
                      ? const TextInputType.numberWithOptions(
                          decimal: true, signed: true)
                      : null,
                  validator: (value) => _validate(entry.key, value ?? ''),
                ),
              ],
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.image_outlined),
                label: Text(_image?.name ?? 'Chọn ảnh'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Lưu'),
              ),
            ],
          ),
        ),
      );
}
