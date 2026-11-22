import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../repositories/destination_repository.dart';
import '../widgets/destination_image.dart';
import 'destination_detail_page.dart';

class RelatedDestinationsPage extends StatefulWidget {
  const RelatedDestinationsPage({
    super.key,
    required this.repository,
    required this.current,
  });
  final DestinationRepository repository;
  final Destination current;

  @override
  State<RelatedDestinationsPage> createState() =>
      _RelatedDestinationsPageState();
}

class _RelatedDestinationsPageState extends State<RelatedDestinationsPage> {
  static const _pageSize = 6;
  int _page = 1;
  late Future<List<Destination>> _results = _fetch();

  Future<List<Destination>> _fetch() => widget.repository.list(
    _page,
    widget.current.categoryId,
    '',
    pageSize: _pageSize,
  );

  void _load(int page) => setState(() {
    _page = page;
    _results = _fetch();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Địa điểm liên quan')),
    body: FutureBuilder(
      future: _results,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => _load(_page),
              child: const Text('Thử tải lại'),
            ),
          );
        }
        final page = snapshot.data!;
        final items = page
            .where((item) => item.id != widget.current.id)
            .toList();
        return Column(
          children: [
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text('Không có địa điểm khác ở trang này'),
                    )
                  : ListView(
                      children: [
                        for (final item in items)
                          ListTile(
                            leading: DestinationImage(
                              repository: widget.repository,
                              path: item.text('image'),
                              width: 72,
                            ),
                            title: Text(item.name),
                            subtitle: Text(item.text('province')),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DestinationDetailPage(
                                  repository: widget.repository,
                                  item: item,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Trang trước',
                    onPressed: _page > 1 ? () => _load(_page - 1) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Trang $_page'),
                  IconButton(
                    tooltip: 'Trang sau',
                    onPressed: page.length == _pageSize
                        ? () => _load(_page + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
