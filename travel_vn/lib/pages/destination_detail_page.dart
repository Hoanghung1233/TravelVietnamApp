import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../repositories/destination_repository.dart';
import '../services/session_helper.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/destination_image.dart';
import '../widgets/favorite_button.dart';
import 'booking_create_page.dart';
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
  int _selectedPhoto = 0;

  Future<void> _book(Destination item) async {
    if (SessionHelper.currentToken == null) {
      await Navigator.of(context).pushNamed('/login', arguments: true);
    }
    if (!mounted || SessionHelper.currentToken == null) return;
    await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => BookingCreatePage(destination: item),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: const BottomNavbar(),
        appBar: AppBar(
          title: Text(widget.item.name),
          actions: [
            FavoriteButton(destinationId: widget.item.id),
            const SizedBox(width: 8),
          ],
        ),
        body: FutureBuilder(
          future: _detail,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _selectedPhoto = 0;
                    _detail = widget.repository.detail(widget.item.id);
                  }),
                  child: const Text('Không tải được chi tiết. Thử lại'),
                ),
              );
            }

            final item = snapshot.data;
            if (item == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final photos = [
              item.text('image'),
              ...item.gallery,
            ].where((path) => path.trim().isNotEmpty).toSet().toList();
            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 850;
                final inset = wide ? 24.0 : 16.0;
                final outer =
                    (constraints.maxWidth - 1160).clamp(0.0, double.infinity) /
                        2;
                return ListView(
                  padding:
                      EdgeInsets.fromLTRB(inset + outer, 12, inset + outer, 32),
                  children: [
                    if (photos.isNotEmpty) ...[
                      _gallery(context, photos, wide),
                      const SizedBox(height: 24),
                    ],
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _overview(context, item)),
                          const SizedBox(width: 24),
                          SizedBox(width: 320, child: _actions(context, item)),
                        ],
                      )
                    else ...[
                      _overview(context, item, showDescription: false),
                      const SizedBox(height: 16),
                      _actions(context, item),
                      if (item.text('description').isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _description(context, item),
                      ],
                    ],
                  ],
                );
              },
            );
          },
        ),
      );

  Widget _gallery(BuildContext context, List<String> photos, bool wide) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ColoredBox(
            color: colors.surfaceContainerHighest,
            child: SizedBox(
              width: double.infinity,
              height: wide ? 390 : 230,
              child: DestinationImage(
                repository: widget.repository,
                path: photos[_selectedPhoto],
              ),
            ),
          ),
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 66,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Semantics(
                selected: index == _selectedPhoto,
                child: Material(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: index == _selectedPhoto
                          ? colors.primary
                          : colors.outlineVariant,
                      width: index == _selectedPhoto ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => setState(() => _selectedPhoto = index),
                    child: Tooltip(
                      message: 'Xem ảnh ${index + 1}',
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: SizedBox(
                            width: 90,
                            height: 60,
                            child: DestinationImage(
                              repository: widget.repository,
                              path: photos[index],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _overview(BuildContext context, Destination item,
      {bool showDescription = true}) {
    final theme = Theme.of(context);
    final province = item.text('province');
    final address = item.text('address');
    final location = [province, if (address != province) address]
        .where((value) => value.isNotEmpty)
        .join(' · ');
    final hours = item.text('openingHours');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            )),
        if (location.isNotEmpty) ...[
          const SizedBox(height: 10),
          _fact(context, Icons.place_outlined, location),
        ],
        if (hours.isNotEmpty) ...[
          const SizedBox(height: 8),
          _fact(context, Icons.schedule, 'Giờ mở cửa: $hours'),
        ],
        if (showDescription && item.text('description').isNotEmpty) ...[
          const SizedBox(height: 24),
          _description(context, item),
        ],
      ],
    );
  }

  Widget _fact(BuildContext context, IconData icon, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      );

  Widget _description(BuildContext context, Destination item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Giới thiệu', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(item.text('description'),
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
        ],
      );

  Widget _actions(BuildContext context, Destination item) {
    final theme = Theme.of(context);
    final rawPrice = item.text('ticketPrice');
    final value = num.tryParse(rawPrice);
    final price = switch (value) {
      0 => 'Miễn phí',
      final num amount => '${_formatPrice(amount)} ₫',
      _ => 'Chưa có thông tin',
    };

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Giá vé', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(price,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.event_available_outlined),
              label: const Text('Đặt vé tham quan'),
              onPressed: () => _book(item),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.latitude != null && item.longitude != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Xem bản đồ'),
                    onPressed: () => Navigator.of(context)
                        .pushNamed('/destination-map', arguments: item),
                  ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Đánh giá & nhận xét'),
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ReviewPage(
                        destinationId: item.id, destinationName: item.name),
                  )),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('Địa điểm liên quan'),
                  onPressed: () => Navigator.of(context).pushNamed(
                    '/related-destinations',
                    arguments: (widget.repository, item),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(num amount) {
    final parts = amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2).split('.');
    final whole = parts.first
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return [whole, ...parts.skip(1)].join(',');
  }
}
