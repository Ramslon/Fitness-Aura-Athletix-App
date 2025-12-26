import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

class Reply {
	final String id;
	final String author;
	final String message;
	final DateTime date;

	Reply({required this.id, required this.author, required this.message, required this.date});

	Map<String, dynamic> toMap() => {'id': id, 'author': author, 'message': message, 'date': date.toIso8601String()};
	factory Reply.fromMap(Map<String, dynamic> m) => Reply(id: m['id'] as String, author: m['author'] as String, message: m['message'] as String, date: DateTime.parse(m['date'] as String));
}

class Post {
	final String id;
	final String author;
	final String message;
	final DateTime date;
	final List<Reply> replies;
	final Set<String> likes;

	Post({required this.id, required this.author, required this.message, required this.date, List<Reply>? replies, Set<String>? likes})
			: replies = replies ?? [],
				likes = likes ?? {};

	Map<String, dynamic> toMap() => {
				'id': id,
				'author': author,
				'message': message,
				'date': date.toIso8601String(),
				'replies': replies.map((r) => r.toMap()).toList(),
				'likes': likes.toList(),
			};

	factory Post.fromMap(Map<String, dynamic> m) => Post(
				id: m['id'] as String,
				author: m['author'] as String,
				message: m['message'] as String,
				date: DateTime.parse(m['date'] as String),
				replies: (m['replies'] as List<dynamic>?)?.map((x) => Reply.fromMap(Map<String, dynamic>.from(x))).toList() ?? [],
				likes: ((m['likes'] as List<dynamic>?)?.map((x) => x.toString()).toSet()) ?? {},
			);
}

class CommunityService {
	CommunityService._();
	static final CommunityService _instance = CommunityService._();
	factory CommunityService() => _instance;

	static const _kKey = 'community_posts_v1';

	final _uuid = const Uuid();
	final _controller = StreamController<List<Post>>.broadcast();
	List<Post> _postsCache = [];

	Stream<List<Post>> get stream => _controller.stream;

	Future<void> _load() async {
		final raw = await StorageService().loadStringSetting(_kKey);
		if (raw == null || raw.isEmpty) {
			_postsCache = [];
		} else {
			final list = jsonDecode(raw) as List<dynamic>;
			_postsCache = list.map((e) => Post.fromMap(Map<String, dynamic>.from(e))).toList();
		}
		_controller.add(_postsCache);
	}

	Future<void> _persist() async {
		final raw = jsonEncode(_postsCache.map((p) => p.toMap()).toList());
		await StorageService().saveStringSetting(_kKey, raw);
		_controller.add(_postsCache);
	}

	Future<List<Post>> loadPosts() async {
		await _load();
		return _postsCache;
	}

	Future<void> postMessage(String author, String message) async {
		final p = Post(id: _uuid.v4(), author: author, message: message, date: DateTime.now());
		_postsCache.insert(0, p);
		await _persist();
	}

	Future<void> replyTo(String postId, String author, String message) async {
		final post = _postsCache.firstWhere((p) => p.id == postId, orElse: () => throw Exception('Post not found'));
		post.replies.add(Reply(id: _uuid.v4(), author: author, message: message, date: DateTime.now()));
		await _persist();
	}

	Future<void> toggleLike(String postId, String userId) async {
		final post = _postsCache.firstWhere((p) => p.id == postId, orElse: () => throw Exception('Post not found'));
		if (post.likes.contains(userId)) post.likes.remove(userId); else post.likes.add(userId);
		await _persist();
	}

	void dispose() {
		_controller.close();
	}
}

