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

  const LocalImagePlaceholder({
    required this.id,
    this.assetPath,
    this.fit = BoxFit.cover,
    this.height,
    super.key,
  });

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
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (res == null || res.files.isEmpty) return;
    final picked = res.files.first;
    final dir = await _appDir();
    final ext = picked.extension ?? 'png';
    final target = File('${dir.path}/${widget.id}.$ext');
    final data = picked.path != null
        ? File(picked.path!).readAsBytesSync()
        : picked.bytes;
    if (data == null) return;
    await target.writeAsBytes(data);
    setState(() => _file = target);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget image;
    if (_file != null) {
      image = Image.file(_file!, height: widget.height, fit: widget.fit);
    } else if (widget.assetPath != null) {
      image = Image.asset(
        widget.assetPath!,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (c, e, s) => _placeholder(context),
      );
    } else {
      image = _placeholder(context);
    }

    // Always render as a stack so "Customize" is consistently available.
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        Positioned(
          right: 10,
          top: 10,
          child: _CustomizePill(
            label: _file == null ? 'Customize' : 'Change',
            onPressed: _pickImage,
            accent: scheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final isTight = maxH > 0 && maxH < 170;
        final isVeryTight = maxH > 0 && maxH < 140;

        final margin = isVeryTight
            ? const EdgeInsets.all(8)
            : (isTight ? const EdgeInsets.all(10) : const EdgeInsets.all(12));
        final padding = isVeryTight
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
            : (isTight
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 14));

        final iconSize = isVeryTight ? 30.0 : (isTight ? 36.0 : 44.0);

        return Container(
          color: Colors.transparent,
          height: widget.height,
          child: Center(
            child: Container(
              margin: margin,
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: SingleChildScrollView(
                // Ensures no RenderFlex overflow even on very small grid tiles.
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: iconSize,
                      color: scheme.onSurface.withValues(alpha: 0.70),
                    ),
                    SizedBox(height: isVeryTight ? 6 : 10),
                    Text(
                      'Add a photo',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.90),
                        fontWeight: FontWeight.w800,
                        fontSize: isVeryTight ? 12.5 : 13.5,
                      ),
                    ),
                    if (!isVeryTight) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Make this exercise yours',
                        textAlign: TextAlign.center,
                        maxLines: isTight ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.70),
                          fontSize: isTight ? 11 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (!isTight) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Add image'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomizePill extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color accent;

  const _CustomizePill({
    required this.label,
    required this.onPressed,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.45),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        elevation: 0,
      ),
      onPressed: onPressed,
      icon: Icon(Icons.tune, size: 16, color: accent.withValues(alpha: 0.95)),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
