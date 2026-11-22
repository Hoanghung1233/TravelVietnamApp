import 'dart:convert';
import 'package:flutter/material.dart';
import 'destination_repository.dart';
import 'package:travel_vn/repositories/review_repository.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.destinationId,
    required this.destinationName,
  });

  final int destinationId;
  final String destinationName;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _repository = ReviewRepository();
  late Future<List<Review>> _reviews;
  String? _token;
  String? _memberId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _reviews = _repository.getByDestination(widget.destinationId);
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  String? _getMemberId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final json = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final id = json['nameid'] ??
          json['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
          json['sub'];
      return id is String ? id : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _signIn() async {
    if (_token != null) return _token;

    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ReviewLoginPage()),
    );

    if (!mounted || token == null) return null;

    final memberId = _getMemberId(token);
    if (memberId == null) {
      _message('Không xác định được tài khoản từ token');
      return null;
    }

    setState(() {
      _token = token;
      _memberId = memberId;
    });
    return token;
  }

  Future<void> _addReview() async {
    final token = await _signIn();
    if (!mounted || token == null) return;

    try {
      final reviews = await _reviews;
      if (!mounted) return;
      if (reviews.any((review) => review.memberId == _memberId)) {
        _message('Bạn đã đánh giá địa điểm này. Hãy chọn Sửa.');
        return;
      }
    } catch (error) {
      if (mounted) _message(error.toString());
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddReviewPage(
          destinationId: widget.destinationId,
          token: token,
        ),
      ),
    );

    if (mounted && saved == true) setState(_load);
  }

  Future<void> _editReview(Review review) async {
    final token = _token;
    if (token == null) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddReviewPage(
          destinationId: widget.destinationId,
          token: token,
          review: review,
        ),
      ),
    );

    if (mounted && saved == true) setState(_load);
  }

  Future<void> _deleteReview(Review review) async {
    final token = _token;
    if (token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa đánh giá?'),
        content: const Text('Bạn có chắc muốn xóa đánh giá này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    try {
      await _repository.delete(token, review.reviewId);
      if (mounted) {
        setState(_load);
        _message('Đã xóa đánh giá');
      }
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  Widget _reviewItem(Review review) {
    final date = review.createdAt;
    final createdAt = '${date.day}/${date.month}/${date.year}';
    final isMine = _memberId != null && review.memberId == _memberId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle_outlined),
                const SizedBox(width: 8),
                Text(
                  isMine ? '${review.reviewerName} (Bạn)' : review.reviewerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              review.comment?.isNotEmpty == true
                  ? review.comment!
                  : 'Không có nhận xét',
            ),
            const SizedBox(height: 8),
            Text(
              'Ngày đánh giá: $createdAt',
              style: const TextStyle(color: Colors.grey),
            ),
            if (isMine)
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa'),
                    onPressed: () => _editReview(review),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa'),
                    onPressed: () => _deleteReview(review),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Đánh giá - ${widget.destinationName}'),
      actions: [
        IconButton(
          tooltip: _token == null ? 'Đăng nhập' : 'Đăng xuất',
          icon: Icon(_token == null ? Icons.login : Icons.logout),
          onPressed: _token == null
              ? () async { await _signIn(); }
              : () => setState(() {
                  _token = null;
                  _memberId = null;
                }),
        ),
        IconButton(
          tooltip: 'Viết đánh giá',
          icon: const Icon(Icons.rate_review_outlined),
          onPressed: _addReview,
        ),
        IconButton(
          tooltip: 'Tải lại',
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(_load),
        ),
      ],
    ),
    body: FutureBuilder<List<Review>>(
      future: _reviews,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(_load),
              child: const Text('Không tải được đánh giá. Thử lại'),
            ),
          );
        }

        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return const Center(
            child: Text('Địa điểm này chưa có đánh giá nào'),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, index) => _reviewItem(reviews[index]),
            ),
          ),
        );
      },
    ),
  );
}

class ReviewLoginPage extends StatefulWidget {
  const ReviewLoginPage({super.key});

  @override
  State<ReviewLoginPage> createState() => _ReviewLoginPageState();
}

class _ReviewLoginPageState extends State<ReviewLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final token = await DestinationRepository().login(
        _email.text.trim(),
        _password.text,
      );
      if (mounted) Navigator.pop(context, token);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Không đăng nhập được. Kiểm tra tài khoản và kết nối API.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đăng nhập để đánh giá')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
            ),
            if (_error != null) Text(_error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _login,
              child: Text(_busy ? 'Đang đăng nhập...' : 'Đăng nhập'),
            ),
          ],
        ),
      ),
    ),
  );
}

class AddReviewPage extends StatefulWidget {
  const AddReviewPage({
    super.key,
    required this.destinationId,
    required this.token,
    this.review,
  });

  final int destinationId;
  final String token;
  final Review? review;

  @override
  State<AddReviewPage> createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  final _repository = ReviewRepository();
  final _comment = TextEditingController();
  late int _rating;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rating = widget.review?.rating ?? 5;
    _comment.text = widget.review?.comment ?? '';
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (widget.review == null) {
        await _repository.add(
          widget.token,
          widget.destinationId,
          _rating,
          _comment.text.trim(),
        );
      } else {
        await _repository.edit(
          widget.token,
          widget.review!.reviewId,
          _rating,
          _comment.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.review == null ? 'Viết đánh giá' : 'Sửa đánh giá'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Chọn số sao'),
            Row(
              children: [
                for (int i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _rating = i),
                    icon: Icon(
                      i <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  ),
              ],
            ),
            TextField(
              controller: _comment,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Nhận xét',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) Text(_error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy
                  ? 'Đang lưu...'
                  : widget.review == null
                      ? 'Gửi đánh giá'
                      : 'Lưu thay đổi'),
            ),
          ],
        ),
      ),
    ),
  );
}
