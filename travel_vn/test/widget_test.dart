import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_vn/destination_repository.dart';
import 'package:travel_vn/main.dart';

void main() {
  testWidgets('Destination screen displays search and paging area', (
    tester,
  ) async {
    await tester.pumpWidget(const TravelBookingApp());
    expect(find.text('Địa điểm du lịch'), findsOneWidget);
    expect(find.text('Tìm theo tên hoặc tỉnh/thành'), findsOneWidget);
  });
  testWidgets('Related list excludes current destination and opens another', (
    tester,
  ) async {
    const current = Destination({
      'destinationId': 1,
      'categoryId': 7,
      'name': 'Địa điểm hiện tại',
      'latitude': 21.03,
      'longitude': 105.85,
    });
    final repository = StubDestinationRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: DestinationDetailPage(repository: repository, item: current),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Xem bản đồ'), findsOneWidget);
    await tester.tap(find.text('Địa điểm liên quan'));
    await tester.pumpAndSettle();
    expect(repository.requestedCategory, 7);
    expect(find.text('Địa điểm hiện tại'), findsNothing);
    await tester.tap(find.text('Địa điểm khác'));
    await tester.pumpAndSettle();
    expect(repository.requestedId, 2);
  });
}

class StubDestinationRepository extends DestinationRepository {
  int? requestedCategory;
  int? requestedId;

  @override
  Future<List<Destination>> list(
    int page,
    int? categoryId,
    String keyword, {
    int pageSize = 10,
  }) async {
    requestedCategory = categoryId;
    return const [
      Destination({
        'destinationId': 1,
        'categoryId': 7,
        'name': 'Địa điểm hiện tại',
      }),
      Destination({
        'destinationId': 2,
        'categoryId': 7,
        'name': 'Địa điểm khác',
      }),
    ];
  }

  @override
  Future<Destination> detail(int id) async {
    requestedId = id;
    return Destination({
      'destinationId': id,
      'categoryId': 7,
      'name': id == 1 ? 'Địa điểm hiện tại' : 'Địa điểm khác',
      'latitude': 21.03,
      'longitude': 105.85,
    });
  }
}
