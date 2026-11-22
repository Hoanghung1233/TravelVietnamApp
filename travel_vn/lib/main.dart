import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'models/destination.dart';
import 'pages/destination_admin.dart';
import 'pages/destination_detail_page.dart';
import 'pages/destination_map.dart';
import 'pages/favorites_page.dart';
import 'pages/home_page.dart';
import 'pages/related_destinations_page.dart';
import 'pages/tab_page.dart';
import 'repositories/destination_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'TravelVN',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    initialRoute: '/',
    routes: destinationRoutes,
  );
}

final destinationRoutes = <String, WidgetBuilder>{
  '/': (_) => const DestinationsPage(),
  '/destinations/search': (_) => const DestinationsPage(focusSearch: true),
  '/favorites': (_) => const FavoritesPage(),
  '/bookings': (_) => const TabPage(title: 'Đặt chỗ'),
  '/account': (context) => TabPage(
    title: 'Cá nhân',
    action: FilledButton.icon(
      onPressed: () => Navigator.of(context).pushNamed('/destinations/admin'),
      icon: const Icon(Icons.admin_panel_settings_outlined),
      label: const Text('Quản trị địa điểm'),
    ),
  ),
  '/destinations/admin': (_) => const DestinationsPage(management: true),
  '/destination-detail': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args case (DestinationRepository repository, Destination item)) {
      return DestinationDetailPage(repository: repository, item: item);
    }
    return const _MissingDestination();
  },
  '/related-destinations': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args case (DestinationRepository repository, Destination item)) {
      return RelatedDestinationsPage(repository: repository, current: item);
    }
    return const _MissingDestination();
  },
  '/destination-map': (context) {
    final item = ModalRoute.of(context)?.settings.arguments;
    if (item is Destination &&
        item.latitude != null &&
        item.longitude != null) {
      return DestinationMapPage(
        name: item.name,
        latitude: item.latitude!,
        longitude: item.longitude!,
      );
    }
    return const _MissingDestination();
  },
  '/destinations/admin/login': (context) {
    final repository = ModalRoute.of(context)?.settings.arguments;
    return AdminLoginPage(
      repository: repository is DestinationRepository
          ? repository
          : DestinationRepository(),
    );
  },
  '/destinations/admin/edit': (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args case (
      DestinationRepository repository,
      String token,
      List<Map<String, dynamic>> categories,
      Destination? item,
    )) {
      return DestinationEditor(
        repository: repository,
        token: token,
        categories: categories,
        item: item,
      );
    }
    return const _MissingDestination();
  },
};

class _MissingDestination extends StatelessWidget {
  const _MissingDestination();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Địa điểm du lịch')),
    body: Center(
      child: TextButton(
        onPressed: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        child: const Text('Quay về trang chủ'),
      ),
    ),
  );
}
