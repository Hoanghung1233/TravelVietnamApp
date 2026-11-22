import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:travel_vn/models/destination.dart';
import 'package:travel_vn/pages/destination_detail_page.dart';
import 'package:travel_vn/repositories/destination_repository.dart';
import 'package:travel_vn/main.dart';
import 'package:travel_vn/service/api_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('API helper reads the bundled dotenv address', () async {
    addTearDown(dotenv.clean);
    await dotenv.load();
    final configured = Uri.parse(dotenv.get('API_BASE_URL'));
    final endpoint = const ApiHelper().endpoint('Destination');
    expect(endpoint.port, configured.port);
    expect(endpoint.path, endsWith('/api/Destination'));
  });

  testWidgets('Destination screen displays search and paging area', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    expect(find.text('Khám phá Việt Nam'), findsOneWidget);
    expect(find.text('Địa điểm du lịch'), findsOneWidget);
    expect(find.text('Tìm theo tên hoặc tỉnh/thành'), findsOneWidget);
    await tester.tap(find.text('Khám phá'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      ModalRoute.of(tester.element(find.text('Khám phá')))?.settings.name,
      '/destinations/search',
    );

    await tester.tap(find.text('Yêu thích'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập để xem yêu thích'), findsOneWidget);

    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    expect(find.text('Tài khoản của tôi'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Quản trị địa điểm'), findsNothing);

    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('Zalo'), findsOneWidget);
    await tester.ensureVisible(find.text('Quên mật khẩu?'));
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    expect(find.text('Quên mật khẩu'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Về trang chủ'));
    await tester.pumpAndSettle();

    expect(find.text('Khám phá Việt Nam'), findsOneWidget);

    await tester.tap(find.text('Đặt chỗ'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng đăng nhập để xem hoặc đặt vé.'), findsOneWidget);

    await tester.tap(find.text('Trang chủ'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Địa điểm du lịch'), findsOneWidget);
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
        routes: {
          ...destinationRoutes,
          '/': (_) =>
              DestinationDetailPage(repository: repository, item: current),
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Xem bản đồ'), findsOneWidget);
    expect(find.byTooltip('Lưu yêu thích'), findsOneWidget);
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
