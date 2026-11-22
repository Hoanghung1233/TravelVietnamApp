import 'dart:convert';

class Destination {
  const Destination(this.data);

  final Map<String, dynamic> data;

  int get id => data['destinationId'] as int;
  int get categoryId => data['categoryId'] as int;
  double? get latitude => (data['latitude'] as num?)?.toDouble();
  double? get longitude => (data['longitude'] as num?)?.toDouble();
  String get name => text('name');
  String text(String key) => data[key]?.toString() ?? '';

  List<String> get gallery {
    if (text('gallery').isEmpty) return [];
    try {
      final decoded = jsonDecode(text('gallery'));
      return decoded is List ? decoded.whereType<String>().toList() : [];
    } on FormatException {
      return [];
    }
  }
}
