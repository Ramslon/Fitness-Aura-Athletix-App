import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:fitness_aura_athletix/services/storage_service.dart';

import 'package:fitness_aura_athletix/core/models/community_model_plan.dart';

class _V1Reply {
	final String id;
	final String author;
	final String message;
	final DateTime date;

	_V1Reply({required this.id, required this.author, required this.message, required this.date});

	factory _V1Reply.fromMap(Map<String, dynamic> m) => _V1Reply(
			id: (m['id'] ?? '').toString(),
			author: (m['author'] ?? 'Anonymous').toString(),
			message: (m['message'] ?? '').toString(),
			date: DateTime.tryParse((m['date'] ?? '').toString()) ?? DateTime.now(),
		);
}

class _V1Post {
	final String id;
	final String author;
	final String message;
	final DateTime date;
	final List<_V1Reply> replies;
	final Set<String> likes;

	_V1Post({
		required this.id,
		required this.author,
		required this.message,
		required this.date,
		required this.replies,
		required this.likes,
	});

	factory _V1Post.fromMap(Map<String, dynamic> m) => _V1Post(
			id: (m['id'] ?? '').toString(),
			author: (m['author'] ?? 'Anonymous').toString(),
			message: (m['message'] ?? '').toString(),
			date: DateTime.tryParse((m['date'] ?? '').toString()) ?? DateTime.now(),
			replies: (m['replies'] as List<dynamic>?)
					?.map((x) => _V1Reply.fromMap(Map<String, dynamic>.from(x)))
					.toList() ??
				const <_V1Reply>[],
			likes: ((m['likes'] as List<dynamic>?)?.map((x) => x.toString()).toSet()) ?? const <String>{},
		);
}

class CommunityService {
	CommunityService._();
	static final CommunityService _instance = CommunityService._();
	factory CommunityService() => _instance;

	static const String localUserId = 'local_user';

	static const _kPostsV1 = 'community_posts_v1';
	static const _kPostsV2 = 'community_posts_v2';
	static const _kStateV1 = 'community_state_v1';
	static const _kLocalProfileV1 = 'community_local_profile_v1';
	static const _kReportsV1 = 'community_reports_v1';

	final _uuid = const Uuid();
	final _controller = StreamController<List<CommunityPost>>.broadcast();
	List<CommunityPost> _postsCache = [];
	CommunityState _state = CommunityState.empty();
	CommunityUserProfile _localProfile = const CommunityUserProfile(
		userId: localUserId,
		displayName: 'You',
		trainingLevel: CommunityTrainingLevel.beginner,
		workoutStreakDays: 0,
		strongestLiftsKg: <String, double>{},
		recentAchievements: <String>[],
		goals: <CommunityGoal>{CommunityGoal.strength},
		focusBodyParts: <String>{'Full Body'},
		locationLabel: null,
	);
	final Map<String, CommunityUserProfile> _userDirectory = {};

	Stream<List<CommunityPost>> get stream => _controller.stream;
	CommunityState get state => _state;
	CommunityUserProfile get localProfile => _localProfile;

	List<CommunityChallenge> get challenges => const [
		CommunityChallenge(
			id: 'c_30day_consistency',
			title: '30-Day Consistency Challenge',
			description: 'Show up regularly. 1 workout counts as 1 day.',
			tags: {'Consistency'},
			target: 30,
		),
		CommunityChallenge(
			id: 'c_leg_volume_week',
			title: 'Leg Volume Week',
			description: 'Push leg volume for 7 days (smartly).',
			tags: {'Legs', 'Hypertrophy'},
			target: 7,
		),
		CommunityChallenge(
			id: 'c_10k_volume_club',
			title: '10k Volume Club',
			description: 'Hit 10,000 total load units in a month.',
			tags: {'Volume', 'Strength'},
			target: 10000,
		),
	];

	Future<void> _loadAll() async {
		await Future.wait([
			_loadState(),
			_loadLocalProfile(),
			_loadUsers(),
			_loadPosts(),
		]);
		_controller.add(_postsCache);
	}

	Future<void> _loadState() async {
		final raw = await StorageService().loadStringSetting(_kStateV1);
		if (raw == null || raw.isEmpty) {
			_state = CommunityState.empty();
			return;
		}
		_state = CommunityState.fromMap(Map<String, dynamic>.from(jsonDecode(raw) as Map));
	}

	Future<void> _persistState() async {
		await StorageService().saveStringSetting(_kStateV1, jsonEncode(_state.toMap()));
	}

	Future<void> _loadLocalProfile() async {
		final raw = await StorageService().loadStringSetting(_kLocalProfileV1);
		if (raw == null || raw.isEmpty) return;
		_localProfile = CommunityUserProfile.fromMap(Map<String, dynamic>.from(jsonDecode(raw) as Map));
	}

	Future<void> saveLocalProfile(CommunityUserProfile profile) async {
		_localProfile = profile;
		await StorageService().saveStringSetting(_kLocalProfileV1, jsonEncode(profile.toMap()));
		_userDirectory[profile.userId] = profile;
		_controller.add(_postsCache);
	}

	Future<void> _loadUsers() async {
		// Seed a small user directory for profile cards (offline demo).
		_userDirectory[localUserId] = _localProfile;
		_userDirectory.putIfAbsent(
			'u_ken',
			() => const CommunityUserProfile(
				userId: 'u_ken',
				displayName: 'Ken',
				trainingLevel: CommunityTrainingLevel.intermediate,
				workoutStreakDays: 12,
				strongestLiftsKg: {'Bench': 95, 'Squat': 130, 'Deadlift': 160},
				recentAchievements: ['100 workouts logged', 'Back strength +8%'],
				goals: {CommunityGoal.strength, CommunityGoal.bulking},
				focusBodyParts: {'Back', 'Legs'},
				locationLabel: 'Nairobi',
			),
		);
		_userDirectory.putIfAbsent(
			'u_amina',
			() => const CommunityUserProfile(
				userId: 'u_amina',
				displayName: 'Amina',
				trainingLevel: CommunityTrainingLevel.beginner,
				workoutStreakDays: 6,
				strongestLiftsKg: {'Squat': 60, 'Bench': 35},
				recentAchievements: ['30-day consistency'],
				goals: {CommunityGoal.recomposition},
				focusBodyParts: {'Legs', 'Glutes'},
				locationLabel: 'Thika',
			),
		);
		_userDirectory.putIfAbsent(
			'u_coach_jo',
			() => const CommunityUserProfile(
				userId: 'u_coach_jo',
				displayName: 'Coach Jo',
				trainingLevel: CommunityTrainingLevel.advanced,
				workoutStreakDays: 41,
				strongestLiftsKg: {'Bench': 140, 'Squat': 190, 'Deadlift': 220},
				recentAchievements: ['Verified coach'],
				goals: {CommunityGoal.strength},
				focusBodyParts: {'Full Body'},
				isVerifiedCoach: true,
				locationLabel: 'Nairobi',
			),
		);
	}

	Future<void> _loadPosts() async {
		final rawV2 = await StorageService().loadStringSetting(_kPostsV2);
		if (rawV2 != null && rawV2.isNotEmpty) {
			final list = jsonDecode(rawV2) as List<dynamic>;
			_postsCache = list.map((e) => CommunityPost.fromMap(Map<String, dynamic>.from(e as Map))).toList();
			return;
		}

		// Migrate from v1 if present.
		final rawV1 = await StorageService().loadStringSetting(_kPostsV1);
		if (rawV1 != null && rawV1.isNotEmpty) {
			final list = jsonDecode(rawV1) as List<dynamic>;
			final v1 = list.map((e) => _V1Post.fromMap(Map<String, dynamic>.from(e as Map))).toList();
			_postsCache = v1.map(_convertV1ToV2).toList();
			await _persistPosts();
			return;
		}

		_postsCache = _seedSamplePosts();
		await _persistPosts();
	}

	CommunityPost _convertV1ToV2(_V1Post p) {
		return CommunityPost(
			id: p.id,
			type: CommunityPostType.askCommunity,
			authorId: 'u_legacy_${p.author.toLowerCase().replaceAll(' ', '_')}',
			authorName: p.author,
			authorLevel: CommunityTrainingLevel.beginner,
			date: p.date,
			title: 'Community update',
			body: p.message,
			bodyParts: const <String>{},
			goals: const <CommunityGoal>{},
			meta: const <String, dynamic>{'migratedFrom': 'v1'},
			comments: p.replies
					.map(
						(r) => CommunityComment(
							id: r.id,
							authorId: 'u_legacy_${r.author.toLowerCase().replaceAll(' ', '_')}',
							authorName: r.author,
							isCoach: false,
							message: r.message,
							date: r.date,
						),
					)
					.toList(),
			respectBy: p.likes,
		);
	}

	List<CommunityPost> _seedSamplePosts() {
		final now = DateTime.now();
		return [
			CommunityPost(
				id: _uuid.v4(),
				type: CommunityPostType.workoutCompletion,
				authorId: 'u_amina',
				authorName: 'Amina',
				authorLevel: CommunityTrainingLevel.beginner,
				date: now.subtract(const Duration(hours: 6)),
				title: 'Workout complete: Lower Body',
				body: 'Hit squats + lunges today. Felt smooth and controlled.',
				bodyParts: const {'Legs', 'Glutes'},
				goals: const {CommunityGoal.recomposition},
				meta: const {'durationMin': 42, 'totalSets': 14},
				comments: const <CommunityComment>[],
				respectBy: const <String>{},
			),
			CommunityPost(
				id: _uuid.v4(),
				type: CommunityPostType.prAchievement,
				authorId: 'u_ken',
				authorName: 'Ken',
				authorLevel: CommunityTrainingLevel.intermediate,
				date: now.subtract(const Duration(days: 1, hours: 2)),
				title: 'PR: Deadlift 160kg',
				body: 'Clean pull. Form held. Going to hold here for 2 weeks.',
				bodyParts: const {'Back'},
				goals: const {CommunityGoal.strength},
				meta: const {'lift': 'Deadlift', 'weightKg': 160},
				comments: [
					CommunityComment(
						id: 'c1',
						authorId: 'u_coach_jo',
						authorName: 'Coach Jo',
						isCoach: true,
						message: 'Solid. Keep your back-off sets at RPE 7–8 for recovery.',
						date: now,
					),
				],
				respectBy: const <String>{},
			),
			CommunityPost(
				id: _uuid.v4(),
				type: CommunityPostType.aiInsightShare,
				authorId: 'u_ken',
				authorName: 'Ken',
				authorLevel: CommunityTrainingLevel.intermediate,
				date: now.subtract(const Duration(days: 2)),
				title: 'AI insight: Back strength +10%',
				body: 'AI says my back strength improved 10% this month. Anyone else tracking this?',
				bodyParts: const {'Back'},
				goals: const {CommunityGoal.strength},
				meta: const {'deltaPct': 10, 'windowDays': 30},
				comments: const <CommunityComment>[],
				respectBy: const <String>{},
			),
			CommunityPost(
				id: _uuid.v4(),
				type: CommunityPostType.progressMilestone,
				authorId: 'u_amina',
				authorName: 'Amina',
				authorLevel: CommunityTrainingLevel.beginner,
				date: now.subtract(const Duration(days: 3, hours: 4)),
				title: 'Milestone: 30-day consistency',
				body: 'Not perfect workouts. Just showing up. That’s the win.',
				bodyParts: const {'Full Body'},
				goals: const {CommunityGoal.recomposition},
				meta: const {'milestone': '30-day consistency'},
				comments: const <CommunityComment>[],
				respectBy: const <String>{},
			),
		];
	}

	Future<void> _persistPosts() async {
		await StorageService().saveStringSetting(
			_kPostsV2,
			jsonEncode(_postsCache.map((p) => p.toMap()).toList()),
		);
		_controller.add(_postsCache);
	}

	Future<List<CommunityPost>> loadPosts() async {
		await _loadAll();
		return _postsCache;
	}

	CommunityUserProfile? getUserProfile(String userId) => _userDirectory[userId];

	Future<void> createPost({
		required CommunityPostType type,
		required String title,
		required String body,
		Set<String>? bodyParts,
		Set<CommunityGoal>? goals,
		Map<String, dynamic>? meta,
	}) async {
		final p = CommunityPost(
			id: _uuid.v4(),
			type: type,
			authorId: _localProfile.userId,
			authorName: _localProfile.displayName,
			authorLevel: _localProfile.trainingLevel,
			date: DateTime.now(),
			title: title,
			body: body,
			bodyParts: (bodyParts ?? _localProfile.focusBodyParts).toSet(),
			goals: (goals ?? _localProfile.goals).toSet(),
			meta: meta ?? const <String, dynamic>{},
			comments: const <CommunityComment>[],
			respectBy: const <String>{},
		);
		_postsCache.insert(0, p);
		await _persistPosts();
	}

	Future<void> addComment(String postId, {required String message, bool asCoach = false}) async {
		final idx = _postsCache.indexWhere((p) => p.id == postId);
		if (idx < 0) throw Exception('Post not found');

		final warning = _aiWarningForComment(message);
		final comment = CommunityComment(
			id: _uuid.v4(),
			authorId: _localProfile.userId,
			authorName: _localProfile.displayName,
			isCoach: asCoach,
			message: message,
			date: DateTime.now(),
			aiWarning: warning,
		);

		final p = _postsCache[idx];
		final updated = CommunityPost(
			id: p.id,
			type: p.type,
			authorId: p.authorId,
			authorName: p.authorName,
			authorLevel: p.authorLevel,
			date: p.date,
			title: p.title,
			body: p.body,
			bodyParts: p.bodyParts,
			goals: p.goals,
			meta: p.meta,
			comments: [...p.comments, comment],
			respectBy: p.respectBy,
		);

		_postsCache[idx] = updated;
		await _persistPosts();
	}

	Future<void> toggleRespect(String postId, String userId) async {
		final idx = _postsCache.indexWhere((p) => p.id == postId);
		if (idx < 0) throw Exception('Post not found');

		final p = _postsCache[idx];
		final next = p.respectBy.contains(userId)
				? (p.respectBy.toSet()..remove(userId))
				: (p.respectBy.toSet()..add(userId));

		_postsCache[idx] = CommunityPost(
			id: p.id,
			type: p.type,
			authorId: p.authorId,
			authorName: p.authorName,
			authorLevel: p.authorLevel,
			date: p.date,
			title: p.title,
			body: p.body,
			bodyParts: p.bodyParts,
			goals: p.goals,
			meta: p.meta,
			comments: p.comments,
			respectBy: next,
		);
		await _persistPosts();
	}

	Future<void> toggleSave(String postId) async {
		final s = _state.savedPostIds.toSet();
		if (s.contains(postId)) {
			s.remove(postId);
		} else {
			s.add(postId);
		}
		_state = CommunityState(
			blockedUserIds: _state.blockedUserIds,
			followingUserIds: _state.followingUserIds,
			savedPostIds: s,
			joinedChallengeIds: _state.joinedChallengeIds,
			leaderboardOptIn: _state.leaderboardOptIn,
		);
		await _persistState();
		_controller.add(_postsCache);
	}

	Future<void> toggleFollow(String userId) async {
		final f = _state.followingUserIds.toSet();
		if (f.contains(userId)) {
			f.remove(userId);
		} else {
			f.add(userId);
		}
		_state = CommunityState(
			blockedUserIds: _state.blockedUserIds,
			followingUserIds: f,
			savedPostIds: _state.savedPostIds,
			joinedChallengeIds: _state.joinedChallengeIds,
			leaderboardOptIn: _state.leaderboardOptIn,
		);
		await _persistState();
		_controller.add(_postsCache);
	}

	Future<void> blockUser(String userId) async {
		final b = _state.blockedUserIds.toSet()..add(userId);
		final f = _state.followingUserIds.toSet()..remove(userId);
		_state = CommunityState(
			blockedUserIds: b,
			followingUserIds: f,
			savedPostIds: _state.savedPostIds,
			joinedChallengeIds: _state.joinedChallengeIds,
			leaderboardOptIn: _state.leaderboardOptIn,
		);
		await _persistState();
		_controller.add(_postsCache);
	}

	Future<void> reportPost(String postId, {required String reason}) async {
		final raw = await StorageService().loadStringSetting(_kReportsV1);
		final list = (raw == null || raw.isEmpty) ? <dynamic>[] : (jsonDecode(raw) as List<dynamic>);
		list.add({
			'postId': postId,
			'reason': reason,
			'date': DateTime.now().toIso8601String(),
		});
		await StorageService().saveStringSetting(_kReportsV1, jsonEncode(list));
	}

	Future<void> toggleJoinChallenge(String challengeId) async {
		final joined = _state.joinedChallengeIds.toSet();
		if (joined.contains(challengeId)) {
			joined.remove(challengeId);
		} else {
			joined.add(challengeId);
		}
		_state = CommunityState(
			blockedUserIds: _state.blockedUserIds,
			followingUserIds: _state.followingUserIds,
			savedPostIds: _state.savedPostIds,
			joinedChallengeIds: joined,
			leaderboardOptIn: _state.leaderboardOptIn,
		);
		await _persistState();
		_controller.add(_postsCache);
	}

	Future<void> setLeaderboardOptIn(bool v) async {
		_state = CommunityState(
			blockedUserIds: _state.blockedUserIds,
			followingUserIds: _state.followingUserIds,
			savedPostIds: _state.savedPostIds,
			joinedChallengeIds: _state.joinedChallengeIds,
			leaderboardOptIn: v,
		);
		await _persistState();
		_controller.add(_postsCache);
	}

	String? _aiWarningForComment(String text) {
		final t = text.toLowerCase();
		final dangerous = <String>['no warmup', 'max out daily', 'ignore pain', 'train injured', 'steroids', 'tren', 'dnp'];
		if (dangerous.any(t.contains)) {
			return 'AI warning: potentially dangerous advice. Prioritize safety and consult a professional.';
		}
		return null;
	}

	void dispose() {
		_controller.close();
	}
}

