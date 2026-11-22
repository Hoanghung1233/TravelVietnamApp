import 'package:flutter/material.dart';

import '../repositories/favorite_repository.dart';
import '../review_page.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({super.key, required this.destinationId});

  final int destinationId;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late Future<bool>? _status = _load();
  bool _busy = false;

  Future<bool>? _load() {
    final token = FavoriteRepository.sessionToken;
    return token == null
        ? null
        : FavoriteRepository(token).isFavorite(widget.destinationId);
  }

  Future<void> _toggle(bool saved) async {
    setState(() => _busy = true);
    try {
      var token = FavoriteRepository.sessionToken;
      if (token == null) {
        token = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) =>
                const ReviewLoginPage(title: 'Đăng nhập để lưu yêu thích'),
          ),
        );
        if (!mounted || token == null) return;
        FavoriteRepository.sessionToken = token;
        saved = false;
      }

      final repository = FavoriteRepository(token);
      if (saved) {
        await repository.remove(widget.destinationId);
      } else {
        await repository.add(widget.destinationId);
      }
      if (mounted) {
        setState(() {
          _status = Future.value(!saved);
        });
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
      setState(() {
        _status = _load();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _status,
    builder: (context, snapshot) {
      if (_busy || snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      if (snapshot.hasError && FavoriteRepository.sessionToken != null) {
        return IconButton(
          tooltip: 'Thử tải lại yêu thích',
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(() {
            _status = _load();
          }),
        );
      }

      final saved = snapshot.data ?? false;
      return IconButton(
        tooltip: saved ? 'Bỏ yêu thích' : 'Lưu yêu thích',
        icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
        onPressed: () => _toggle(saved),
      );
    },
  );
}
