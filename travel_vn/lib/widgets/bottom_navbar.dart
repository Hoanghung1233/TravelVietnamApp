import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  const BottomNavbar({super.key});

  static const _tabs = [
    (route: '/', label: 'Trang chủ', icon: Icons.home_outlined),
    (
      route: '/destinations/search',
      label: 'Khám phá',
      icon: Icons.explore_outlined,
    ),
    (route: '/favorites', label: 'Yêu thích', icon: Icons.favorite_border),
    (
      route: '/bookings',
      label: 'Đặt chỗ',
      icon: Icons.event_available_outlined,
    ),
    (route: '/account', label: 'Cá nhân', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    final selected = switch (route) {
      '/destinations/search' ||
      '/destination-detail' ||
      '/destination-map' ||
      '/related-destinations' =>
        '/destinations/search',
      '/favorites' => '/favorites',
      '/bookings' || '/booking' => '/bookings',
      '/account' ||
      '/profile' ||
      '/login' ||
      '/register' ||
      '/admin-booking' ||
      '/destinations/admin' ||
      '/destinations/admin/login' ||
      '/destinations/admin/edit' =>
        '/account',
      _ => '/',
    };

    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 928),
          child: Row(
            children: [
              for (final tab in _tabs)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Semantics(
                      button: true,
                      selected: tab.route == selected,
                      child: Material(
                        color: tab.route == selected
                            ? colors.primaryContainer
                            : colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            if (route == tab.route) return;
                            final navigator = Navigator.of(context);
                            navigator.popUntil((current) => current.isFirst);
                            if (tab.route != '/') {
                              navigator.pushNamed(tab.route);
                            }
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 52),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 2,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    tab.icon,
                                    size: 22,
                                    color: tab.route == selected
                                        ? colors.primary
                                        : colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tab.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tab.route == selected
                                          ? colors.primary
                                          : colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
