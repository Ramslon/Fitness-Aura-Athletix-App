import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/community_service.dart';

import 'package:fitness_aura_athletix/core/models/community_model_plan.dart';
import 'package:fitness_aura_athletix/presentation/widgets/premium_gate.dart';
import 'package:fitness_aura_athletix/services/premium_access_service.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({Key? key}) : super(key: key);

  @override
  _CommunityFeedScreenState createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen>
    with SingleTickerProviderStateMixin {
  final CommunityService _svc = CommunityService();

  late final TabController _tab;
  bool _isPremium = false;

  // Filters
  bool _followingOnly = false;
  bool _nearbyOnly = false;
  bool _sameLevelOnly = false;
  bool _sameGoalsOnly = false;
  final Set<String> _bodyPartFilter = {};

  final Set<String> _expandedPostIds = {};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    await _svc.loadPosts();
    final prem = await PremiumAccessService().isPremiumActive();
    if (!mounted) return;
    setState(() => _isPremium = prem);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _goToPremium() {
    Navigator.of(context).pushNamed('/premium-features');
  }

  Future<void> _openFilters() async {
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: ListView(
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: scheme.primary),
                  const SizedBox(width: 8),
                  const Text('Feed filters', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _followingOnly = false;
                        _nearbyOnly = false;
                        _sameLevelOnly = false;
                        _sameGoalsOnly = false;
                        _bodyPartFilter.clear();
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Reset'),
                  )
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Following only'),
                subtitle: const Text('Less noise, more signal.'),
                value: _followingOnly,
                onChanged: (v) => setState(() => _followingOnly = v),
              ),
              const SizedBox(height: 4),
              PremiumGate(
                isPremium: _isPremium,
                title: 'Advanced filters',
                previewText: 'Unlock Nearby / Same level / Same goals 🔒',
                onUpgrade: _goToPremium,
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Nearby lifters'),
                      value: _nearbyOnly,
                      onChanged: (v) => setState(() => _nearbyOnly = v),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Same training level'),
                      value: _sameLevelOnly,
                      onChanged: (v) => setState(() => _sameLevelOnly = v),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Same goals'),
                      value: _sameGoalsOnly,
                      onChanged: (v) => setState(() => _sameGoalsOnly = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text('Body-part focus', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Legs', 'Back', 'Chest', 'Arms', 'Shoulders', 'Glutes', 'Core', 'Full Body']
                    .map(
                      (bp) => FilterChip(
                        label: Text(bp),
                        selected: _bodyPartFilter.contains(bp),
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _bodyPartFilter.add(bp);
                            } else {
                              _bodyPartFilter.remove(bp);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Apply'),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _composePost() async {
    final scheme = Theme.of(context).colorScheme;
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    CommunityPostType type = CommunityPostType.workoutCompletion;
    String milestone = '30-day consistency';
    String prLift = 'Bench';
    double prWeight = 60;
    String bodyPart = 'Full Body';

    Future<void> submit(BuildContext sheetContext) async {
      final title = titleCtrl.text.trim();
      final body = bodyCtrl.text.trim();
      if (title.isEmpty || body.isEmpty) return;

      final meta = <String, dynamic>{};
      Set<String> parts = {bodyPart};
      switch (type) {
        case CommunityPostType.workoutCompletion:
          meta['kind'] = 'workout';
          break;
        case CommunityPostType.prAchievement:
          meta['lift'] = prLift;
          meta['weightKg'] = prWeight;
          break;
        case CommunityPostType.progressMilestone:
          meta['milestone'] = milestone;
          break;
        case CommunityPostType.aiInsightShare:
          meta['kind'] = 'ai_insight';
          break;
        case CommunityPostType.askCommunity:
          meta['kind'] = 'ask';
          break;
      }

      await _svc.createPost(
        type: type,
        title: title,
        body: body,
        bodyParts: parts,
        meta: meta,
      );
      if (!mounted) return;
      Navigator.of(sheetContext).pop();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(
                children: [
                  Icon(Icons.edit_note, color: scheme.primary),
                  const SizedBox(width: 8),
                  const Text('Create post', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<CommunityPostType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Post type'),
                items: const [
                  DropdownMenuItem(value: CommunityPostType.workoutCompletion, child: Text('🏋️ Workout completion')),
                  DropdownMenuItem(value: CommunityPostType.prAchievement, child: Text('🏆 PR & achievement')),
                  DropdownMenuItem(value: CommunityPostType.progressMilestone, child: Text('📈 Progress milestone')),
                  DropdownMenuItem(value: CommunityPostType.aiInsightShare, child: Text('🧠 AI insight share')),
                  DropdownMenuItem(value: CommunityPostType.askCommunity, child: Text('❓ Ask the community')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setSheetState(() => type = v);
                },
              ),
              const SizedBox(height: 10),

              if (type == CommunityPostType.progressMilestone)
                DropdownButtonFormField<String>(
                  value: milestone,
                  decoration: const InputDecoration(labelText: 'Milestone'),
                  items: const [
                    DropdownMenuItem(value: '30-day consistency', child: Text('30-day consistency')),
                    DropdownMenuItem(value: '100 workouts logged', child: Text('100 workouts logged')),
                    DropdownMenuItem(value: 'Muscle group improvement', child: Text('Muscle group improvement')),
                  ],
                  onChanged: (v) => milestone = v ?? milestone,
                ),

              if (type == CommunityPostType.prAchievement) ...[
                DropdownButtonFormField<String>(
                  value: prLift,
                  decoration: const InputDecoration(labelText: 'Lift'),
                  items: const [
                    DropdownMenuItem(value: 'Bench', child: Text('Bench press')),
                    DropdownMenuItem(value: 'Squat', child: Text('Squat')),
                    DropdownMenuItem(value: 'Deadlift', child: Text('Deadlift')),
                    DropdownMenuItem(value: 'Overhead Press', child: Text('Overhead press')),
                  ],
                  onChanged: (v) => prLift = v ?? prLift,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: prWeight.toStringAsFixed(0),
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => prWeight = double.tryParse(v) ?? prWeight,
                ),
              ],

              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: bodyPart,
                decoration: const InputDecoration(labelText: 'Body part'),
                items: const [
                  DropdownMenuItem(value: 'Full Body', child: Text('Full Body')),
                  DropdownMenuItem(value: 'Legs', child: Text('Legs')),
                  DropdownMenuItem(value: 'Back', child: Text('Back')),
                  DropdownMenuItem(value: 'Chest', child: Text('Chest')),
                  DropdownMenuItem(value: 'Arms', child: Text('Arms')),
                  DropdownMenuItem(value: 'Shoulders', child: Text('Shoulders')),
                  DropdownMenuItem(value: 'Glutes', child: Text('Glutes')),
                  DropdownMenuItem(value: 'Core', child: Text('Core')),
                ],
                onChanged: (v) => bodyPart = v ?? bodyPart,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(labelText: 'Post'),
                minLines: 2,
                maxLines: 6,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => submit(ctx),
                  icon: const Icon(Icons.send),
                  label: const Text('Post'),
                ),
              ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<CommunityPost> _applyFilters(List<CommunityPost> posts) {
    final st = _svc.state;
    final profile = _svc.localProfile;
    final isPremium = _isPremium;

    return posts.where((p) {
      if (st.blockedUserIds.contains(p.authorId)) return false;
      if (_followingOnly && !st.followingUserIds.contains(p.authorId)) return false;
      if (_bodyPartFilter.isNotEmpty && p.bodyParts.intersection(_bodyPartFilter).isEmpty) return false;

      if (!isPremium) {
        // Premium-only filters ignored for free users.
        return true;
      }

      if (_nearbyOnly) {
        final author = _svc.getUserProfile(p.authorId);
        if (author?.locationLabel == null || profile.locationLabel == null) return false;
        if (author!.locationLabel != profile.locationLabel) return false;
      }
      if (_sameLevelOnly && p.authorLevel != profile.trainingLevel) return false;
      if (_sameGoalsOnly && p.goals.intersection(profile.goals).isEmpty) return false;
      return true;
    }).toList();
  }

  List<CommunityPost> _rankPosts(List<CommunityPost> posts) {
    final profile = _svc.localProfile;
    double score(CommunityPost p) {
      var s = 0.0;
      final ageHours = DateTime.now().difference(p.date).inHours.clamp(0, 9999);
      s += (72 - ageHours).clamp(0, 72) * 0.5;

      if (p.goals.intersection(profile.goals).isNotEmpty) s += 12;
      if (p.bodyParts.intersection(profile.focusBodyParts).isNotEmpty) s += 6;
      if (p.authorLevel == profile.trainingLevel) s += 5;

      switch (p.type) {
        case CommunityPostType.askCommunity:
          s += profile.trainingLevel == CommunityTrainingLevel.beginner ? 10 : 6;
          break;
        case CommunityPostType.aiInsightShare:
          s += 8;
          break;
        case CommunityPostType.prAchievement:
          s += 6;
          break;
        case CommunityPostType.workoutCompletion:
          s += 4;
          break;
        case CommunityPostType.progressMilestone:
          s += 5;
          break;
      }
      // Not popularity-based: do not use respect count.
      return s;
    }

    final ranked = posts.toList()..sort((a, b) => score(b).compareTo(score(a)));
    return ranked;
  }

  List<String> _aiFlagsForPost(CommunityPost p) {
    final text = '${p.title}\n${p.body}'.toLowerCase();
    final flags = <String>[];

    final shaming = <String>['lazy', 'fat', 'stupid', 'idiot'];
    final dangerous = <String>['no warmup', 'ignore pain', 'train injured', 'max out daily', 'steroids', 'tren', 'dnp'];
    final spam = <String>['buy now', 'promo', 'dm me', 'telegram', 'whatsapp link'];

    if (shaming.any(text.contains)) flags.add('Shaming');
    if (dangerous.any(text.contains)) flags.add('Dangerous advice');
    if (spam.any(text.contains)) flags.add('Spam');
    return flags;
  }

  bool _shouldHideForKeywordModeration(CommunityPost p) {
    final text = '${p.title}\n${p.body}'.toLowerCase();
    final blocked = <String>['steroids', 'tren', 'dnp'];
    return blocked.any(text.contains);
  }

  Future<void> _openComments(CommunityPost p) async {
    final scheme = Theme.of(context).colorScheme;
    final ctrl = TextEditingController();
    final isBeginner = _svc.localProfile.trainingLevel == CommunityTrainingLevel.beginner;

    List<String> suggestions() {
      if (!isBeginner) return const [];
      return const [
        'Nice progress! How often do you train legs?',
        'Solid work — what rep range are you using?',
        'What’s your weekly plan (days per week)?',
      ];
    }

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: scheme.primary),
                  const SizedBox(width: 8),
                  const Text('Comments', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const Spacer(),
                  Text('${p.comments.length}', style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65))),
                ],
              ),
              const SizedBox(height: 8),
              if (suggestions().isNotEmpty) ...[
                const Text('AI comment suggestions (beginner-friendly)', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suggestions()
                      .map(
                        (s) => ActionChip(
                          label: Text(s),
                          onPressed: () {
                            ctrl.text = s;
                            ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
              ],
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: p.comments.length,
                  itemBuilder: (_, i) {
                    final c = p.comments[i];
                    final coachBadge = c.isCoach
                        ? Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('Coach', style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800, fontSize: 12)),
                          )
                        : null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_circle, size: 20),
                              const SizedBox(width: 8),
                              Text(c.authorName, style: const TextStyle(fontWeight: FontWeight.w800)),
                              if (coachBadge != null) coachBadge,
                              const Spacer(),
                              Text(
                                _shortTime(c.date),
                                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.55), fontSize: 12),
                              )
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(c.message),
                          if (c.aiWarning != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: scheme.errorContainer.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                c.aiWarning!,
                                style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w700),
                              ),
                            )
                          ]
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Add a comment',
                        hintText: 'Keep it helpful and respectful…',
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Send',
                    onPressed: () async {
                      final text = ctrl.text.trim();
                      if (text.isEmpty) return;
                      await _svc.addComment(p.id, message: text);
                      if (!mounted) return;
                      Navigator.of(ctx).pop();
                    },
                    icon: const Icon(Icons.send),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openProfile(String userId) async {
    final scheme = Theme.of(context).colorScheme;
    final profile = _svc.getUserProfile(userId);
    if (profile == null) return;
    final isFollowing = _svc.state.followingUserIds.contains(userId);

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle, size: 42),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(profile.displayName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            if (profile.isVerifiedCoach) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.verified, color: scheme.primary, size: 18),
                            ]
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_levelLabel(profile.trainingLevel)} • Streak: ${profile.workoutStreakDays}d${profile.locationLabel != null ? ' • ${profile.locationLabel}' : ''}',
                          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Strongest lifts', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              if (profile.strongestLiftsKg.isEmpty)
                Text('No lifts shared yet.', style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.strongestLiftsKg.entries
                      .map(
                        (e) => Chip(label: Text('${e.key}: ${e.value.toStringAsFixed(0)} kg')),
                      )
                      .toList(),
                ),
              const SizedBox(height: 12),
              const Text('Recent achievements', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              if (profile.recentAchievements.isEmpty)
                Text('No achievements shared yet.', style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)))
              else
                ...profile.recentAchievements.take(4).map((a) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.emoji_events_outlined, color: scheme.primary),
                      title: Text(a),
                    )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: profile.userId == CommunityService.localUserId
                          ? null
                          : () async {
                              await _svc.toggleFollow(profile.userId);
                              if (!mounted) return;
                              Navigator.of(ctx).pop();
                            },
                      child: Text(profile.userId == CommunityService.localUserId
                          ? 'This is you'
                          : (isFollowing ? 'Unfollow' : 'Follow')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: profile.userId == CommunityService.localUserId
                          ? null
                          : () async {
                              await _svc.blockUser(profile.userId);
                              if (!mounted) return;
                              Navigator.of(ctx).pop();
                            },
                      child: const Text('Block user'),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _postMenu(CommunityPost p) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report post'),
                onTap: () => Navigator.of(ctx).pop('report'),
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block user'),
                onTap: () => Navigator.of(ctx).pop('block'),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(ctx).pop(null),
              ),
            ],
          ),
        );
      },
    );

    if (choice == 'block') {
      await _svc.blockUser(p.authorId);
      return;
    }
    if (choice == 'report') {
      final reason = await showDialog<String>(
        context: context,
        builder: (c) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('Report post'),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(hintText: 'What’s the issue? (spam, unsafe advice, etc.)'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(c).pop(ctrl.text.trim()), child: const Text('Send')),
            ],
          );
        },
      );
      if (reason != null && reason.isNotEmpty) {
        await _svc.reportPost(p.id, reason: reason);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted. Thank you.')));
      }
    }
  }

  Widget _postTypeChip(CommunityPostType t) {
    final label = switch (t) {
      CommunityPostType.workoutCompletion => 'Workout',
      CommunityPostType.prAchievement => 'PR / Achievement',
      CommunityPostType.progressMilestone => 'Milestone',
      CommunityPostType.aiInsightShare => 'AI Insight',
      CommunityPostType.askCommunity => 'Ask',
    };
    return Chip(label: Text(label));
  }

  Widget _buildPostCard(CommunityPost p) {
    final scheme = Theme.of(context).colorScheme;
    final flags = _aiFlagsForPost(p);
    final hide = _shouldHideForKeywordModeration(p);

    final isExpanded = _expandedPostIds.contains(p.id);
    final bodyText = p.body.trim();
    final isLong = bodyText.length > 160;
    final visibleBody = (!isLong || isExpanded)
      ? bodyText
      : '${bodyText.substring(0, 160)}…';

    final isSaved = _svc.state.savedPostIds.contains(p.id);
    final hasRespected = p.respectBy.contains(CommunityService.localUserId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _openProfile(p.authorId),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _levelLabel(p.authorLevel),
                          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.60), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  _shortTime(p.date),
                  style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.55), fontSize: 12),
                ),
                IconButton(
                  tooltip: 'More',
                  onPressed: () => _postMenu(p),
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _postTypeChip(p.type),
                if (p.bodyParts.isNotEmpty) ...p.bodyParts.take(2).map((bp) => Chip(label: Text(bp))),
              ],
            ),
            if (flags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'AI flagged: ${flags.join(', ')}',
                  style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w800),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(p.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 6),
            if (hide)
              Text(
                'Content hidden due to safety rules.',
                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(visibleBody),
                  if (isLong)
                    TextButton(
                      onPressed: () => setState(() {
                        if (isExpanded) {
                          _expandedPostIds.remove(p.id);
                        } else {
                          _expandedPostIds.add(p.id);
                        }
                      }),
                      child: Text(isExpanded ? 'Show less' : 'Show more'),
                    ),
                ],
              ),

            const SizedBox(height: 10),
            PremiumGate(
              isPremium: _isPremium,
              title: 'AI post insights',
              previewText: 'Unlock smart insights + safety notes 🔒',
              onUpgrade: _goToPremium,
              child: _aiPostInsightPanel(p),
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _svc.toggleRespect(p.id, CommunityService.localUserId),
                  icon: Icon(hasRespected ? Icons.thumb_up : Icons.thumb_up_outlined),
                  label: Text('Respect ${p.respectBy.length}'),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: () => _openComments(p),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text('Comments ${p.comments.length}'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: isSaved ? 'Unsave' : 'Save',
                  onPressed: () => _svc.toggleSave(p.id),
                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiPostInsightPanel(CommunityPost p) {
    final scheme = Theme.of(context).colorScheme;
    String headline;
    String detail;
    switch (p.type) {
      case CommunityPostType.prAchievement:
        headline = 'Progress strategy';
        detail = 'Hold this PR for 1–2 weeks, then add +2.5kg or +1 rep (not both).';
        break;
      case CommunityPostType.workoutCompletion:
        headline = 'Recovery note';
        detail = 'If today felt heavy, keep the next session at RPE 7–8 and sleep extra.';
        break;
      case CommunityPostType.progressMilestone:
        headline = 'Consistency > intensity';
        detail = 'Small wins compound. Keep the plan boring and repeatable.';
        break;
      case CommunityPostType.aiInsightShare:
        headline = 'Make it actionable';
        detail = 'Pick 1 back movement and add 1 set weekly for 3 weeks, then deload.';
        break;
      case CommunityPostType.askCommunity:
        headline = 'Ask better';
        detail = 'Include your goal, days/week, and current numbers for higher quality answers.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: scheme.primary),
              const SizedBox(width: 8),
              Text(headline, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          Text(detail, style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.80))),
        ],
      ),
    );
  }

  Widget _buildFeed(List<CommunityPost> items) {
    final filtered = _applyFilters(items);
    final ranked = _rankPosts(filtered);

    if (ranked.isEmpty) {
      return const Center(child: Text('No posts match your filters.'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: ranked.length,
        itemBuilder: (_, i) => _buildPostCard(ranked[i]),
      ),
    );
  }

  Widget _buildChallenges() {
    final scheme = Theme.of(context).colorScheme;
    final joined = _svc.state.joinedChallengeIds;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              const Text('Challenges & events', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          ..._svc.challenges.map(
            (c) {
              final isJoined = joined.contains(c.id);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          ),
                          FilledButton(
                            onPressed: () => _svc.toggleJoinChallenge(c.id),
                            child: Text(isJoined ? 'Leave' : 'Join'),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(c.description),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: c.tags.map((t) => Chip(label: Text(t))).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.track_changes, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isJoined ? 'Progress tracker enabled' : 'Join to track your progress',
                              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Leaderboard (opt-in)'),
                        subtitle: const Text('No follower counts. No toxicity.'),
                        value: _svc.state.leaderboardOptIn,
                        onChanged: (v) => _svc.setLeaderboardOptIn(v),
                      ),
                      const SizedBox(height: 6),
                      PremiumGate(
                        isPremium: _isPremium,
                        title: 'Challenge analytics',
                        previewText: 'Unlock deeper progress analytics 🔒',
                        onUpgrade: _goToPremium,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Analytics: consistency curve, pace to target, and recovery notes.',
                            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.80)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildGroups() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: PremiumGate(
        isPremium: _isPremium,
        title: 'Private groups',
        previewText: 'Unlock private groups 🔒 (train with your circle).',
        onUpgrade: _goToPremium,
        child: const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text('Create or join private groups (coming soon).'),
          ),
        ),
      ),
    );
  }

  static String _levelLabel(CommunityTrainingLevel l) {
    return switch (l) {
      CommunityTrainingLevel.beginner => 'Beginner',
      CommunityTrainingLevel.intermediate => 'Intermediate',
      CommunityTrainingLevel.advanced => 'Advanced',
    };
  }

  static String _shortTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 48) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: _openFilters,
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.dynamic_feed), text: 'Feed'),
            Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Challenges'),
            Tab(icon: Icon(Icons.lock_outline), text: 'Groups'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _composePost,
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
      body: StreamBuilder<List<CommunityPost>>(
        stream: _svc.stream,
        builder: (context, snap) {
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No posts yet — be the first!'));
          }

          return TabBarView(
            controller: _tab,
            children: [
              _buildFeed(items),
              _buildChallenges(),
              _buildGroups(),
            ],
          );
        },
      ),
    );
  }
}
