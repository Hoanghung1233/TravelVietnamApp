import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:travel_vn/models/category.dart';
import 'package:travel_vn/repositories/category_repository.dart';

class CategoryPage extends StatefulWidget {
  final String title;

  const CategoryPage({
    super.key,
    this.title = 'Danh mục du lịch',
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];

  bool _isLoading = true;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Tải danh sách danh mục
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await CategoryRepository.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = result;
        _filterCategories();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải danh mục: $e'),
        ),
      );
    }
  }

  // Tìm kiếm danh mục
  void _filterCategories() {
    _filteredCategories = _categories.where((category) {
      return category.categoryName
          .toLowerCase()
          .contains(_keyword.toLowerCase());
    }).toList();
  }

  // Tạo URL ảnh từ Backend wwwroot/uploads/categories
  String getImageUrl(String imagePath) {
    imagePath = imagePath.trim();

    // Nếu database đã lưu URL đầy đủ
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    final apiUrl = dotenv.env['API_URL'];

    if (apiUrl == null || apiUrl.isEmpty) {
      debugPrint('Chưa cấu hình API_URL trong file .env');
      return '';
    }

    // Lấy địa chỉ gốc của Backend
    final baseUrl = apiUrl
        .replaceFirst(RegExp(r'/api/?$'), '')
        .replaceFirst(RegExp(r'/$'), '');

    // Chuẩn hóa đường dẫn ảnh
    String fileName = imagePath.replaceAll('\\', '/');

    // Nếu đã có uploads/categories thì chỉ lấy tên file
    fileName = fileName.split('/').last;

    return '$baseUrl/uploads/categories/$fileName';
  }

  // Widget hiển thị ảnh danh mục
  Widget _buildCategoryImage(
    String? imagePath, {
    double? height,
  }) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return _buildImagePlaceholder(height);
    }

    final imageUrl = getImageUrl(imagePath);

    if (imageUrl.isEmpty) {
      return _buildImagePlaceholder(height);
    }

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          height: height,
          color: Colors.teal.shade50,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Lỗi tải ảnh danh mục: $imageUrl');
        debugPrint('Chi tiết lỗi: $error');

        return _buildImagePlaceholder(height);
      },
    );
  }

  // Ảnh thay thế khi không có ảnh hoặc tải ảnh thất bại
  Widget _buildImagePlaceholder(double? height) {
    return Container(
      width: double.infinity,
      height: height,
      color: Colors.teal.shade50,
      child: const Center(
        child: Icon(
          Icons.landscape,
          size: 45,
          color: Colors.teal,
        ),
      ),
    );
  }

  // Xem chi tiết danh mục
  void _showCategoryDetail(Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildCategoryImage(
                      category.image,
                      height: 190,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    category.categoryName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.description ?? 'Chưa có mô tả cho danh mục này.',
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _keyword = value;
                  _filterCategories();
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm danh mục...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Danh sách danh mục
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredCategories.isEmpty
                    ? const Center(
                        child: Text('Chưa có danh mục nào'),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCategories,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: _filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = _filteredCategories[index];

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                _showCategoryDetail(category);
                              },
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                elevation: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: _buildCategoryImage(
                                          category.image,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        category.categoryName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
