import 'package:flutter/material.dart';
import 'package:fitness_aura_athletix/services/community_service.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({Key? key}) : super(key: key);

  @override
  _CommunityFeedScreenState createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final CommunityService _svc = CommunityService();
  final TextEditingController _composer = TextEditingController();

  @override
  void initState() {
    super.initState();
    _svc.loadPosts();
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  void _post() async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    await _svc.postMessage('Anonymous', text);
    _composer.clear();
    setState(() {});
  }

  Widget _buildPost(Post p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p.author, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${p.date.toLocal()}'.split('.')[0], style: const TextStyle(fontSize: 12))
              ],
            ),
            const SizedBox(height: 8),
            Text(p.message),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                    onPressed: () async {
                      await _svc.toggleLike(p.id, 'local_user');
                      setState(() {});
                    },
                    icon: const Icon(Icons.thumb_up),
                    label: Text(' ${p.likes.length}')),
                TextButton.icon(
                    onPressed: () async {
                      // simple inline reply prompt
                      final reply = await showDialog<String>(context: context, builder: (c) {
                        final ctrl = TextEditingController();
                        return AlertDialog(
                          title: const Text('Reply'),
                          content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Write a reply')),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.of(c).pop(ctrl.text.trim()), child: const Text('Send')),
                          ],
                        );
                      });
                      if (reply != null && reply.isNotEmpty) {
                        await _svc.replyTo(p.id, 'Anonymous', reply);
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.reply),
                    label: Text(' ${p.replies.length}')),
              ],
            ),
            if (p.replies.isNotEmpty) const Divider(),
            ...p.replies.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.account_circle, size: 24),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.author, style: const TextStyle(fontWeight: FontWeight.bold)), Text(r.message)])),
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: StreamBuilder<List<Post>>(
        stream: _svc.stream,
        builder: (context, snap) {
          final items = snap.data ?? [];
          return Column(
            children: [
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No posts yet — be the first!'))
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _svc.loadPosts();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: items.length,
                          itemBuilder: (c, i) => _buildPost(items[i]),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: _composer, decoration: const InputDecoration(hintText: 'Share something...'))),
                    IconButton(icon: const Icon(Icons.send), onPressed: _post)
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
