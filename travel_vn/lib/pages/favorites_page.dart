import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../repositories/destination_repository.dart';
import '../repositories/favorite_repository.dart';
import 'review_page.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/destination_image.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _destinations = DestinationRepository();
  late Future<List<Destination>>? _items = _load();
  bool _removing = false;

  Future<List<Destination>>? _load() {
    final token = FavoriteRepository.sessionToken;
    return token == null ? null : FavoriteRepository(token).list();
  }

  void _reload() {
    setState(() {
      _items = _load();
    });
  }

  Future<void> _signIn() async {
    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            const ReviewLoginPage(title: 'Đăng nhập để lưu yêu thích'),
      ),
    );
    if (!mounted || token == null) return;

    FavoriteRepository.sessionToken = token;
    _reload();
  }

  Future<void> _open(Destination item) async {
    await Navigator.of(context)
        .pushNamed('/destination-detail', arguments: (_destinations, item));
    if (mounted) _reload();
  }

  Future<void> _remove(int id) async {
    final token = FavoriteRepository.sessionToken;
    if (token == null) {
      _reload();
      return;
    }

    setState(() => _removing = true);
    try {
      await FavoriteRepository(token).remove(id);
      if (mounted) _reload();
    } catch (error) {
      if (!mounted) return;
      if (FavoriteRepository.sessionToken == null) _reload();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Địa điểm yêu thích'),
      actions: [
        if (FavoriteRepository.sessionToken != null)
          IconButton(
            tooltip: 'Thoát tài khoản yêu thích',
            onPressed: _removing
                ? null
                : () {
                    FavoriteRepository.sessionToken = null;
                    _reload();
                  },
            icon: const Icon(Icons.logout),
          ),
      ],
    ),
    bottomNavigationBar: const BottomNavbar(),
    body: FutureBuilder<List<Destination>>(
      future: _items,
      builder: (context, snapshot) {
        if (_items == null ||
            (snapshot.hasError && FavoriteRepository.sessionToken == null)) {
          return Center(
            child: FilledButton(
              onPressed: _signIn,
              child: const Text('Đăng nhập để xem yêu thích'),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: _reload,
              child: const Text('Không tải được danh sách. Thử lại'),
            ),
          );
        }

        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(child: Text('Bạn chưa lưu địa điểm nào.'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: DestinationImage(
                repository: _destinations,
                path: item.text('image'),
                width: 56,
              ),
              title: Text(item.name),
              subtitle: Text(item.text('province')),
              onTap: _removing ? null : () => _open(item),
              trailing: IconButton(
                tooltip: 'Bỏ yêu thích',
                icon: const Icon(Icons.favorite),
                onPressed: _removing ? null : () => _remove(item.id),
              ),
            );
          },
        );
      },
    ),
  );
}
