import 'package:flutter/material.dart';

import 'destination_repository.dart';
import 'favorite_repository.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    super.key,
    required this.repository,
    required this.onOpen,
    required this.buildImage,
  });

  final FavoriteRepository repository;
  final Future<void> Function(BuildContext context, Destination item) onOpen;
  final Widget Function(Destination item) buildImage;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<Destination>> _items = widget.repository.list();
  int? _removingId;

  void _reload() {
    if (!mounted) return;
    setState(() {
      _items = widget.repository.list();
    });
  }

  Future<void> _open(Destination item) async {
    await widget.onOpen(context, item);
    _reload();
  }

  Future<void> _remove(Destination item) async {
    setState(() => _removingId = item.id);
    try {
      await widget.repository.remove(item.id);
      _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _removingId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Địa điểm yêu thích'),
      actions: [
        IconButton(
          onPressed: _removingId == null ? _reload : null,
          tooltip: 'Tải lại yêu thích',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Destination>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMessage(snapshot.error!),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(onPressed: _reload, child: const Text('Thử lại')),
                ],
              ),
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
            final price = item.text('ticketPrice');
            return ListTile(
              leading: SizedBox(
                width: 72,
                height: 52,
                child: widget.buildImage(item),
              ),
              title: Text(item.name),
              subtitle: Text(
                [
                  item.text('province'),
                  if (price.isNotEmpty) 'Giá vé: $price đ',
                ].where((line) => line.isNotEmpty).join('\n'),
              ),
              onTap: _removingId == null ? () => _open(item) : null,
              trailing: _removingId == item.id
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      onPressed: _removingId == null
                          ? () => _remove(item)
                          : null,
                      icon: const Icon(Icons.favorite),
                      tooltip: 'Bỏ yêu thích ${item.name}',
                    ),
            );
          },
        );
      },
    ),
  );
}

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.repository,
    required this.destinationId,
  });

  final FavoriteRepository repository;
  final int destinationId;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late Future<bool> _status = _load();
  bool _busy = false;

  Future<bool> _load() => widget.repository.contains(widget.destinationId);

  Future<void> _toggle(bool isFavorite) async {
    setState(() => _busy = true);
    try {
      if (isFavorite) {
        await widget.repository.remove(widget.destinationId);
      } else {
        await widget.repository.add(widget.destinationId);
      }
      if (mounted) {
        setState(() {
          _status = Future.value(!isFavorite);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorMessage(error))));
        setState(() {
          _status = _load();
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _status,
    builder: (context, snapshot) {
      if (_busy || snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      if (snapshot.hasError) {
        return IconButton(
          tooltip: 'Thử tải lại trạng thái yêu thích',
          icon: const Icon(Icons.sync_problem),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_errorMessage(snapshot.error!))),
            );
            setState(() {
              _status = _load();
            });
          },
        );
      }

      final isFavorite = snapshot.data!;
      return IconButton(
        tooltip: isFavorite ? 'Bỏ yêu thích' : 'Lưu yêu thích',
        icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
        onPressed: () => _toggle(isFavorite),
      );
    },
  );
}

String _errorMessage(Object error) {
  final text = error.toString();
  if (text.startsWith('Exception: ')) return text.substring(11);
  return 'Không kết nối được hoặc dữ liệu Yêu thích chưa hợp lệ.';
}
