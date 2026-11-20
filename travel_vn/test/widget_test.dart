import 'package:flutter_test/flutter_test.dart';
import 'package:travel_vn/main.dart';

void main() {
  testWidgets('Destination screen displays search and paging area', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Địa điểm du lịch'), findsOneWidget);
    expect(find.text('Tìm theo tên hoặc tỉnh/thành'), findsOneWidget);
  });
}
