class Category {
  final int categoryId;
  final String categoryName;
  final String? description;
  final String? image;

  Category({
    required this.categoryId,
    required this.categoryName,
    this.description,
    this.image,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      categoryId: (map['categoryId'] as num).toInt(),
      categoryName: map['categoryName']?.toString() ?? '',
      description: map['description']?.toString(),
      image: map['image']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
      'image': image,
    };
  }
}
