import 'package:flutter/material.dart';
import 'package:travel_vn/models/category.dart';
import 'package:travel_vn/repositories/category_repository.dart';

class AdminCategoryPage extends StatefulWidget {
  const AdminCategoryPage({super.key});

  @override
  State<AdminCategoryPage> createState() => _AdminCategoryPageState();
}

class _AdminCategoryPageState extends State<AdminCategoryPage> {
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final result = await CategoryRepository.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải danh mục: $e')),
      );
    }
  }

  void _showCategoryForm({Category? category}) {
    final isEditing = category != null;

    final nameController = TextEditingController(
      text: category?.categoryName ?? '',
    );
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    final imageController = TextEditingController(
      text: category?.image ?? '',
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Cập nhật danh mục' : 'Thêm danh mục'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên danh mục',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên danh mục';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: imageController,
                    decoration: const InputDecoration(
                      labelText: 'Đường dẫn hình ảnh',
                      hintText: 'https://example.com/image.jpg',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final newCategory = Category(
                  categoryId: category?.categoryId ?? 0,
                  categoryName: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  image: imageController.text.trim().isEmpty
                      ? null
                      : imageController.text.trim(),
                );

                try {
                  bool success;

                  if (isEditing) {
                    success = await CategoryRepository.edit(newCategory) > 0;
                  } else {
                    success = await CategoryRepository.add(newCategory) > 0;
                  }

                  if (!mounted || !dialogContext.mounted) return;

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? (isEditing
                                ? 'Cập nhật danh mục thành công'
                                : 'Thêm danh mục thành công')
                            : 'Không thể lưu danh mục',
                      ),
                    ),
                  );

                  if (success) {
                    _loadCategories();
                  }
                } catch (e) {
                  if (!dialogContext.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        );
      },
    ).then((_) {
      nameController.dispose();
      descriptionController.dispose();
      imageController.dispose();
    });
  }

  Future<void> _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa danh mục'),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${category.categoryName}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final int result = await CategoryRepository.delete(
        category.categoryId,
      );

      final bool success = result > 0;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Đã xóa danh mục' : 'Không thể xóa danh mục',
          ),
        ),
      );

      if (success) {
        _loadCategories();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xóa danh mục: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý danh mục'),
        actions: [
          IconButton(
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryForm(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm danh mục'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(child: Text('Chưa có danh mục nào'))
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];

                      return Card(
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: category.image != null &&
                                    category.image!.isNotEmpty
                                ? Image.network(
                                    category.image!,
                                    width: 55,
                                    height: 55,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(
                                      width: 55,
                                      height: 55,
                                      child: Icon(Icons.image_not_supported),
                                    ),
                                  )
                                : Container(
                                    width: 55,
                                    height: 55,
                                    color: Colors.teal.shade50,
                                    child: const Icon(
                                      Icons.landscape,
                                      color: Colors.teal,
                                    ),
                                  ),
                          ),
                          title: Text(
                            category.categoryName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            category.description ?? 'Chưa có mô tả',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showCategoryForm(category: category);
                              } else if (value == 'delete') {
                                _deleteCategory(category);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Chỉnh sửa'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Xóa'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
