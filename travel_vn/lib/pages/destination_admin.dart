import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../repositories/destination_repository.dart';

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
      if (mounted) Navigator.pop(context, token);
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

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
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
            entry.key: entry.value.text.trim(),
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
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.item == null ? 'Thêm địa điểm' : 'Sửa địa điểm'),
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
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
          for (final entry in _labels.entries)
            TextFormField(
              controller: _fields[entry.key],
              decoration: InputDecoration(labelText: entry.value),
              maxLines: entry.key == 'description' ? 4 : 1,
              validator: (value) {
                if ((entry.key == 'name' || entry.key == 'province') &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Bắt buộc';
                }
                return null;
              },
            ),
          TextButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.image_outlined),
            label: Text(_image?.name ?? 'Chọn ảnh'),
          ),
          if (_error != null) Text(_error!),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Lưu'),
          ),
        ],
      ),
    ),
  );
}
