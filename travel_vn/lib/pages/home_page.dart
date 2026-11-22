import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../repositories/member_repository.dart';
import '../services/session_helper.dart';
import '../repositories/destination_repository.dart';
import '../widgets/destination_card.dart';
import '../widgets/bottom_navbar.dart';

class DestinationsPage extends StatefulWidget {
  const DestinationsPage({
    super.key,
    this.focusSearch = false,
    this.management = false,
  });

  final bool focusSearch;
  final bool management;

  @override
  State<DestinationsPage> createState() => _DestinationsPageState();
}

class _DestinationsPageState extends State<DestinationsPage> {
  final _repository = DestinationRepository();
  final _search = TextEditingController();
  final _scroll = ScrollController();
  late Future<List<Map<String, dynamic>>> _categories;
  late Future<List<Destination>> _destinations;
  int _page = 1;
  int? _category;
  String _keyword = '';
  String? _token;

  @override
  void initState() {
    super.initState();
    _categories = _repository.categories();
    _destinations = _repository.list(_page, _category, _keyword);
    if (widget.management) _loadAdminSession();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _load(int page) => setState(() {
        _page = page;
        _destinations = _repository.list(page, _category, _keyword);
      });

  Future<void> _loadAdminSession() async {
    final token = SessionHelper.currentToken;
    if (token == null) return;
    try {
      final member = await MemberRepository.getProfile();
      if (mounted &&
          _token == null &&
          token == SessionHelper.currentToken &&
          member.role == 'Admin') {
        setState(() => _token = token);
      }
    } catch (_) {
      // The administration page can still prompt for sign-in.
    }
  }

  Future<void> _signIn() async {
    final token = await Navigator.of(context)
        .pushNamed('/destinations/admin/login', arguments: _repository);
    if (mounted && token is String) setState(() => _token = token);
  }

  Future<void> _edit([Destination? item]) async {
    try {
      final categories = await _categories;
      final detail = item == null ? null : await _repository.detail(item.id);
      if (!mounted || _token == null) return;
      final saved = await Navigator.of(context).pushNamed(
        '/destinations/admin/edit',
        arguments: (_repository, _token!, categories, detail),
      );
      if (mounted && saved == true) _load(_page);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _delete(Destination item) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (!mounted || remove != true || _token == null) return;
    try {
      await _repository.delete(_token!, item.id);
      if (mounted) _load(_page);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: const BottomNavbar(),
        appBar: AppBar(
          title: Text(
              widget.management ? 'Quản trị địa điểm' : 'Địa điểm du lịch'),
          actions: widget.management
              ? [
                  if (_token == null)
                    IconButton(
                      onPressed: _signIn,
                      icon: const Icon(Icons.admin_panel_settings),
                      tooltip: 'Đăng nhập quản trị',
                    )
                  else ...[
                    IconButton(
                      onPressed: () => _edit(),
                      icon: const Icon(Icons.add),
                      tooltip: 'Thêm địa điểm',
                    ),
                    IconButton(
                      onPressed: () => setState(() => _token = null),
                      icon: const Icon(Icons.logout),
                      tooltip: 'Thoát quản trị',
                    ),
                  ],
                ]
              : null,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final inset = wide ? 24.0 : 16.0;
            final outerInset =
                (constraints.maxWidth - 1200).clamp(0.0, double.infinity) / 2;
            final padding =
                EdgeInsets.symmetric(horizontal: inset + outerInset);
            return CustomScrollView(
              controller: _scroll,
              slivers: [
                if (!widget.focusSearch && !widget.management)
                  SliverPadding(
                    padding:
                        padding.add(const EdgeInsets.only(top: 8, bottom: 22)),
                    sliver: SliverToBoxAdapter(child: _HomeHero(wide: wide)),
                  ),
                SliverPadding(
                  padding:
                      padding.add(const EdgeInsets.only(top: 8, bottom: 22)),
                  sliver: SliverToBoxAdapter(child: _filters(wide)),
                ),
                SliverPadding(
                  padding: padding.add(const EdgeInsets.only(bottom: 16)),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      _keyword.trim().isEmpty && _category == null
                          ? 'Địa điểm mới nhất'
                          : 'Kết quả tìm kiếm',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                FutureBuilder(
                  future: _destinations,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              _categories = _repository.categories();
                              _load(_page);
                            },
                            child:
                                const Text('Không tải được địa điểm. Thử lại'),
                          ),
                        ),
                      );
                    }

                    final items = snapshot.data!;
                    return SliverMainAxisGroup(
                      slivers: [
                        if (items.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                  child: Text('Không tìm thấy địa điểm')),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: padding,
                            sliver: SliverGrid.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: constraints.maxWidth >= 1024
                                    ? 3
                                    : constraints.maxWidth >= 560
                                        ? 2
                                        : 1,
                                mainAxisExtent: wide ? 255 : 218,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, index) =>
                                  _card(items[index]),
                            ),
                          ),
                        if (items.isNotEmpty || _page > 1)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    tooltip: 'Trang trước',
                                    onPressed: _page == 1
                                        ? null
                                        : () => _changePage(_page - 1),
                                    icon: const Icon(Icons.chevron_left),
                                  ),
                                  Text('Trang $_page'),
                                  IconButton(
                                    tooltip: 'Trang sau',
                                    onPressed: items.length < 10
                                        ? null
                                        : () => _changePage(_page + 1),
                                    icon: const Icon(Icons.chevron_right),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      );

  Widget _filters(bool wide) {
    final search = TextField(
      controller: _search,
      autofocus: widget.focusSearch,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _searchDestinations(),
      decoration: InputDecoration(
        labelText: 'Tìm theo tên hoặc tỉnh/thành',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: 'Tìm địa điểm',
          onPressed: _searchDestinations,
          icon: const Icon(Icons.arrow_forward),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    final categories = FutureBuilder(
      future: _categories,
      builder: (context, snapshot) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _category ?? 0,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: [
                const DropdownMenuItem(
                  value: 0,
                  child: Text('Tất cả danh mục'),
                ),
                for (final category
                    in snapshot.data ?? <Map<String, dynamic>>[])
                  DropdownMenuItem(
                    value: category['categoryId'] as int,
                    child: Text(
                      category['categoryName'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                _category = value == 0 ? null : value;
                _load(1);
              },
            ),
          ),
        ),
      ),
    );

    if (!wide) {
      return Column(children: [search, const SizedBox(height: 12), categories]);
    }
    return Row(
      children: [
        Expanded(child: search),
        const SizedBox(width: 14),
        SizedBox(width: 250, child: categories),
      ],
    );
  }

  void _changePage(int page) {
    _load(page);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _searchDestinations() {
    _keyword = _search.text;
    _load(1);
  }

  Widget _card(Destination item) => DestinationCard(
        item: item,
        repository: _repository,
        onTap: () => Navigator.of(context)
            .pushNamed('/destination-detail', arguments: (_repository, item)),
        menu: _token == null
            ? null
            : PopupMenuButton<String>(
                onSelected: (action) =>
                    action == 'edit' ? _edit(item) : _delete(item),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Sửa')),
                  PopupMenuItem(value: 'delete', child: Text('Xóa')),
                ],
              ),
      );
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: wide ? 380 : 234,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/vinh-ha-long.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.15),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.25, 1],
                    colors: [Colors.transparent, Color(0xE6072630)],
                  ),
                ),
              ),
              Positioned(
                left: wide ? 32 : 18,
                right: wide ? 32 : 18,
                bottom: wide ? 26 : 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Khám phá Việt Nam',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: wide ? 48 : 30,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tìm điểm đến cho chuyến đi tiếp theo của bạn.',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context)
                          .pushNamed('/destinations/search'),
                      icon: const Icon(Icons.search, size: 19),
                      label: const Text('Tìm địa điểm'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF075E59),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
