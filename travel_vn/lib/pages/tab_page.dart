import 'package:flutter/material.dart';

import '../widgets/bottom_navbar.dart';

class TabPage extends StatelessWidget {
  const TabPage({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    bottomNavigationBar: const BottomNavbar(),
    body: Center(
      child: action ?? const Text('Chức năng này đang chờ tích hợp.'),
    ),
  );
}
