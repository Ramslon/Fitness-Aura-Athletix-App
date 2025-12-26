import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Widget that displays a local image if previously picked/saved for `id`,
/// otherwise shows a placeholder and allows picking an image from device
/// storage. Optionally falls back to an asset image if provided.
class LocalImagePlaceholder extends StatefulWidget {
  final String id;
  final String? assetPath;
  final BoxFit fit;
  final double? height;

  const LocalImagePlaceholder({required this.id, this.assetPath, this.fit = BoxFit.cover, this.height, super.key});

  @override
  State<LocalImagePlaceholder> createState() => _LocalImagePlaceholderState();
}

class _LocalImagePlaceholderState extends State<LocalImagePlaceholder> {
  File? _file;

  @override
  void initState() {
    super.initState();
    _checkLocalFile();
  }

  Future<Directory> _appDir() async {
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _checkLocalFile() async {
    final dir = await _appDir();
    final possible = ['png', 'jpg', 'jpeg'];
    for (final ext in possible) {
      final f = File('${dir.path}/${widget.id}.$ext');
      if (await f.exists()) {
        setState(() => _file = f);
        return;
      }
    }
    setState(() => _file = null);
  }

  Future<void> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (res == null || res.files.isEmpty) return;
    final picked = res.files.first;
    final dir = await _appDir();
    final ext = picked.extension ?? 'png';
    final target = File('${dir.path}/${widget.id}.$ext');
    final data = picked.path != null ? File(picked.path!).readAsBytesSync() : picked.bytes;
    if (data == null) return;
    await target.writeAsBytes(data);
    setState(() => _file = target);
  }

  @override
  Widget build(BuildContext context) {
    if (_file != null) {
      return Image.file(_file!, height: widget.height, fit: widget.fit);
    }

    if (widget.assetPath != null) {
      // If asset exists, show it as a fallback but still allow picking a local image.
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(widget.assetPath!, height: widget.height, fit: widget.fit, errorBuilder: (c, e, s) => _placeholder(context)),
          Positioned(
            right: 8,
            bottom: 8,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black54),
              onPressed: _pickImage,
              child: const Text('Pick'),
            ),
          ),
        ],
      );
    }

    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      height: widget.height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_file),
              label: const Text('Add image'),
            ),
          ],
        ),
      ),
    );
  }
}
