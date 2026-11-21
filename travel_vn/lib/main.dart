import 'package:flutter/material.dart';

import 'destination_repository.dart';
import 'destination_admin.dart';
import 'destination_map.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Travel Vietnam',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
    home: const DestinationsPage(),
  );
}

class DestinationsPage extends StatefulWidget {
  const DestinationsPage({super.key});

  @override
  State<DestinationsPage> createState() => _DestinationsPageState();
}

class _DestinationsPageState extends State<DestinationsPage> {
  final _repository = DestinationRepository();
  final _search = TextEditingController();
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
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load(int page) => setState(() {
    _page = page;
    _destinations = _repository.list(page, _category, _keyword);
  });

  Future<void> _signIn() async {
    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AdminLoginPage(repository: _repository),
      ),
    );
    if (mounted && token != null) setState(() => _token = token);
  }

  Future<void> _edit([Destination? item]) async {
    try {
      final categories = await _categories;
      final detail = item == null ? null : await _repository.detail(item.id);
      if (!mounted || _token == null) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => DestinationEditor(
            repository: _repository,
            token: _token!,
            categories: categories,
            item: detail,
          ),
        ),
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
    appBar: AppBar(
      title: const Text('Địa điểm du lịch'),
      actions: [
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
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              _keyword = value;
              _load(1);
            },
            decoration: const InputDecoration(
              labelText: 'Tìm theo tên hoặc tỉnh/thành',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        FutureBuilder(
          future: _categories,
          builder: (context, snapshot) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<int>(
              isExpanded: true,
              value: _category ?? 0,
              items: [
                const DropdownMenuItem(
                  value: 0,
                  child: Text('Tất cả danh mục'),
                ),
                for (final category
                    in snapshot.data ?? <Map<String, dynamic>>[])
                  DropdownMenuItem(
                    value: category['categoryId'] as int,
                    child: Text(category['categoryName'] as String),
                  ),
              ],
              onChanged: (value) {
                _category = value == 0 ? null : value;
                _load(1);
              },
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: _destinations,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: () {
                      _categories = _repository.categories();
                      _load(_page);
                    },
                    child: const Text('Không tải được địa điểm. Thử lại'),
                  ),
                );
              }
              final items = snapshot.data!;
              return Column(
                children: [
                  Expanded(
                    child: items.isEmpty
                        ? const Center(child: Text('Không tìm thấy địa điểm'))
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ListTile(
                                leading: DestinationImage(
                                  repository: _repository,
                                  path: item.text('image'),
                                  width: 72,
                                ),
                                title: Text(item.name),
                                subtitle: Text(item.text('province')),
                                trailing: _token == null
                                    ? const Icon(Icons.chevron_right)
                                    : PopupMenuButton<String>(
                                        onSelected: (action) => action == 'edit'
                                            ? _edit(item)
                                            : _delete(item),
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Sửa'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Xóa'),
                                          ),
                                        ],
                                      ),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => DestinationDetailPage(
                                      repository: _repository,
                                      item: item,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Trang trước',
                          onPressed: _page == 1 ? null : () => _load(_page - 1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('Trang $_page'),
                        IconButton(
                          tooltip: 'Trang sau',
                          onPressed: items.length < 10
                              ? null
                              : () => _load(_page + 1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

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
    appBar: AppBar(title: Text(widget.item.name)),
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
            if (item.text('address').isNotEmpty) Text(item.text('address')),
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
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DestinationMapPage(
                      name: item.name,
                      latitude: item.latitude!,
                      longitude: item.longitude!,
                    ),
                  ),
                ),
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Địa điểm liên quan'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RelatedDestinationsPage(
                    repository: widget.repository,
                    current: item,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class DestinationImage extends StatelessWidget {
  const DestinationImage({
    super.key,
    required this.repository,
    required this.path,
    this.width,
  });

  final DestinationRepository repository;
  final String path;
  final double? width;

  @override
  Widget build(BuildContext context) => path.isEmpty
      ? const Icon(Icons.image_outlined)
      : Image.network(
          repository.imageUrl(path).toString(),
          width: width,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
        );
}

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
