import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../repositories/destination_repository.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/destination_image.dart';
import '../widgets/favorite_button.dart';
import 'review_page.dart';

class DestinationDetailPage extends StatefulWidget {
  const DestinationDetailPage({
    super.key,
    required this.repository,
    required this.item,
  });

  final DestinationRepository repository;
  final Destination item;

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  late Future<Destination> _detail = widget.repository.detail(widget.item.id);

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const BottomNavbar(),
    appBar: AppBar(
      title: Text(widget.item.name),
      actions: [FavoriteButton(destinationId: widget.item.id)],
    ),
    body: FutureBuilder(
      future: _detail,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(
                () => _detail = widget.repository.detail(widget.item.id),
              ),
              child: const Text('Không tải được chi tiết. Thử lại'),
            ),
          );
        }

        final item = snapshot.data;
        if (item == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final path in [item.text('image'), ...item.gallery])
              if (path.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DestinationImage(
                    repository: widget.repository,
                    path: path,
                  ),
                ),

            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            Text(item.text('province')),

            if (item.text('address').isNotEmpty)
              Text(item.text('address')),

            if (item.text('openingHours').isNotEmpty)
              Text('Giờ mở cửa: ${item.text('openingHours')}'),

            Text('Giá vé: ${item.text('ticketPrice')} đ'),

            const SizedBox(height: 12),
            Text(item.text('description')),
            const SizedBox(height: 12),

            if (item.latitude != null && item.longitude != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: const Text('Xem bản đồ'),
                onPressed: () =>
                    Navigator.of(context)
                        .pushNamed('/destination-map', arguments: item),
              ),

            OutlinedButton.icon(
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Địa điểm liên quan'),
              onPressed: () => Navigator.of(context).pushNamed(
                '/related-destinations',
                arguments: (widget.repository, item),
              ),
            ),

            // Nút mở chức năng Reviews
            OutlinedButton.icon(
              icon: const Icon(Icons.star_outline),
              label: const Text('Đánh giá & nhận xét'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReviewPage(
                      destinationId: item.id,
                      destinationName: item.name,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    ),
  );
}
