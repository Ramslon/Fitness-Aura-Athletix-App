import 'package:flutter/foundation.dart';

enum CommunityTrainingLevel { beginner, intermediate, advanced }

enum CommunityGoal { bulking, cutting, strength, endurance, recomposition }

enum CommunityPostType {
	workoutCompletion,
	prAchievement,
	progressMilestone,
	aiInsightShare,
	askCommunity,
}

@immutable
class CommunityUserProfile {
	final String userId;
	final String displayName;
	final CommunityTrainingLevel trainingLevel;
	final int workoutStreakDays;
	final Map<String, double> strongestLiftsKg;
	final List<String> recentAchievements;
	final Set<CommunityGoal> goals;
	final Set<String> focusBodyParts;
	final bool isVerifiedCoach;
	final String? locationLabel;

	const CommunityUserProfile({
		required this.userId,
		required this.displayName,
		required this.trainingLevel,
		required this.workoutStreakDays,
		required this.strongestLiftsKg,
		required this.recentAchievements,
		required this.goals,
		required this.focusBodyParts,
		this.isVerifiedCoach = false,
		this.locationLabel,
	});

	Map<String, dynamic> toMap() => {
				'userId': userId,
				'displayName': displayName,
				'trainingLevel': trainingLevel.name,
				'workoutStreakDays': workoutStreakDays,
				'strongestLiftsKg': strongestLiftsKg,
				'recentAchievements': recentAchievements,
				'goals': goals.map((g) => g.name).toList(),
				'focusBodyParts': focusBodyParts.toList(),
				'isVerifiedCoach': isVerifiedCoach,
				'locationLabel': locationLabel,
			};

	factory CommunityUserProfile.fromMap(Map<String, dynamic> m) {
		final goalsRaw = (m['goals'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
		final focusRaw = (m['focusBodyParts'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
		final liftsRaw = (m['strongestLiftsKg'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ??
				const <String, double>{};

		return CommunityUserProfile(
			userId: (m['userId'] ?? '').toString(),
			displayName: (m['displayName'] ?? 'Anonymous').toString(),
			trainingLevel: CommunityTrainingLevel.values.firstWhere(
				(x) => x.name == (m['trainingLevel'] ?? CommunityTrainingLevel.beginner.name),
				orElse: () => CommunityTrainingLevel.beginner,
			),
			workoutStreakDays: (m['workoutStreakDays'] as num?)?.toInt() ?? 0,
			strongestLiftsKg: liftsRaw,
			recentAchievements: (m['recentAchievements'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
			goals: goalsRaw
					.map((s) => CommunityGoal.values.firstWhere((g) => g.name == s, orElse: () => CommunityGoal.strength))
					.toSet(),
			focusBodyParts: focusRaw.toSet(),
			isVerifiedCoach: (m['isVerifiedCoach'] as bool?) ?? false,
			locationLabel: (m['locationLabel'] as String?),
		);
	}
}

@immutable
class CommunityComment {
	final String id;
	final String authorId;
	final String authorName;
	final bool isCoach;
	final String message;
	final DateTime date;
	final String? aiWarning;

	const CommunityComment({
		required this.id,
		required this.authorId,
		required this.authorName,
		required this.isCoach,
		required this.message,
		required this.date,
		this.aiWarning,
	});

	Map<String, dynamic> toMap() => {
				'id': id,
				'authorId': authorId,
				'authorName': authorName,
				'isCoach': isCoach,
				'message': message,
				'date': date.toIso8601String(),
				'aiWarning': aiWarning,
			};

	factory CommunityComment.fromMap(Map<String, dynamic> m) => CommunityComment(
				id: (m['id'] ?? '').toString(),
				authorId: (m['authorId'] ?? 'unknown').toString(),
				authorName: (m['authorName'] ?? 'Anonymous').toString(),
				isCoach: (m['isCoach'] as bool?) ?? false,
				message: (m['message'] ?? '').toString(),
				date: DateTime.tryParse((m['date'] ?? '').toString()) ?? DateTime.now(),
				aiWarning: (m['aiWarning'] as String?),
			);
}

@immutable
class CommunityPost {
	final String id;
	final CommunityPostType type;
	final String authorId;
	final String authorName;
	final CommunityTrainingLevel authorLevel;
	final DateTime date;
	final String title;
	final String body;
	final Set<String> bodyParts;
	final Set<CommunityGoal> goals;
	final Map<String, dynamic> meta;
	final List<CommunityComment> comments;
	final Set<String> respectBy;

	const CommunityPost({
		required this.id,
		required this.type,
		required this.authorId,
		required this.authorName,
		required this.authorLevel,
		required this.date,
		required this.title,
		required this.body,
		required this.bodyParts,
		required this.goals,
		required this.meta,
		required this.comments,
		required this.respectBy,
	});

	Map<String, dynamic> toMap() => {
				'id': id,
				'type': type.name,
				'authorId': authorId,
				'authorName': authorName,
				'authorLevel': authorLevel.name,
				'date': date.toIso8601String(),
				'title': title,
				'body': body,
				'bodyParts': bodyParts.toList(),
				'goals': goals.map((g) => g.name).toList(),
				'meta': meta,
				'comments': comments.map((c) => c.toMap()).toList(),
				'respectBy': respectBy.toList(),
			};

	factory CommunityPost.fromMap(Map<String, dynamic> m) {
		final goalsRaw = (m['goals'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
		final partsRaw = (m['bodyParts'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

		return CommunityPost(
			id: (m['id'] ?? '').toString(),
			type: CommunityPostType.values.firstWhere(
				(x) => x.name == (m['type'] ?? CommunityPostType.workoutCompletion.name),
				orElse: () => CommunityPostType.workoutCompletion,
			),
			authorId: (m['authorId'] ?? 'unknown').toString(),
			authorName: (m['authorName'] ?? 'Anonymous').toString(),
			authorLevel: CommunityTrainingLevel.values.firstWhere(
				(x) => x.name == (m['authorLevel'] ?? CommunityTrainingLevel.beginner.name),
				orElse: () => CommunityTrainingLevel.beginner,
			),
			date: DateTime.tryParse((m['date'] ?? '').toString()) ?? DateTime.now(),
			title: (m['title'] ?? '').toString(),
			body: (m['body'] ?? '').toString(),
			bodyParts: partsRaw.toSet(),
			goals: goalsRaw
					.map((s) => CommunityGoal.values.firstWhere((g) => g.name == s, orElse: () => CommunityGoal.strength))
					.toSet(),
			meta: (m['meta'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? const <String, dynamic>{},
			comments: (m['comments'] as List?)
							?.map((e) => CommunityComment.fromMap(Map<String, dynamic>.from(e as Map)))
							.toList() ??
					const <CommunityComment>[],
			respectBy: ((m['respectBy'] as List?)?.map((e) => e.toString()).toSet()) ?? const <String>{},
		);
	}
}

@immutable
class CommunityChallenge {
	final String id;
	final String title;
	final String description;
	final Set<String> tags;
	final int target;

	const CommunityChallenge({
		required this.id,
		required this.title,
		required this.description,
		required this.tags,
		required this.target,
	});

	Map<String, dynamic> toMap() => {
				'id': id,
				'title': title,
				'description': description,
				'tags': tags.toList(),
				'target': target,
			};

	factory CommunityChallenge.fromMap(Map<String, dynamic> m) => CommunityChallenge(
				id: (m['id'] ?? '').toString(),
				title: (m['title'] ?? '').toString(),
				description: (m['description'] ?? '').toString(),
				tags: ((m['tags'] as List?)?.map((e) => e.toString()).toSet()) ?? const <String>{},
				target: (m['target'] as num?)?.toInt() ?? 0,
			);
}

@immutable
class CommunityState {
	final Set<String> blockedUserIds;
	final Set<String> followingUserIds;
	final Set<String> savedPostIds;
	final Set<String> joinedChallengeIds;
	final bool leaderboardOptIn;

	const CommunityState({
		required this.blockedUserIds,
		required this.followingUserIds,
		required this.savedPostIds,
		required this.joinedChallengeIds,
		required this.leaderboardOptIn,
	});

	factory CommunityState.empty() => const CommunityState(
				blockedUserIds: <String>{},
				followingUserIds: <String>{},
				savedPostIds: <String>{},
				joinedChallengeIds: <String>{},
				leaderboardOptIn: false,
			);

	Map<String, dynamic> toMap() => {
				'blockedUserIds': blockedUserIds.toList(),
				'followingUserIds': followingUserIds.toList(),
				'savedPostIds': savedPostIds.toList(),
				'joinedChallengeIds': joinedChallengeIds.toList(),
				'leaderboardOptIn': leaderboardOptIn,
			};

	factory CommunityState.fromMap(Map<String, dynamic> m) => CommunityState(
				blockedUserIds: ((m['blockedUserIds'] as List?)?.map((e) => e.toString()).toSet()) ?? const <String>{},
				followingUserIds: ((m['followingUserIds'] as List?)?.map((e) => e.toString()).toSet()) ?? const <String>{},
				savedPostIds: ((m['savedPostIds'] as List?)?.map((e) => e.toString()).toSet()) ?? const <String>{},
				joinedChallengeIds: ((m['joinedChallengeIds'] as List?)?.map((e) => e.toString()).toSet()) ?? const <String>{},
				leaderboardOptIn: (m['leaderboardOptIn'] as bool?) ?? false,
			);
}

