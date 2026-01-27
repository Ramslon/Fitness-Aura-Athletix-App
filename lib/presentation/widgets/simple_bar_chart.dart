import 'dart:math';

import 'package:flutter/material.dart';

class BarChartBar {
  final String label;
  final double value;
  final String? tooltip;
  final Color? color;

  const BarChartBar({
    required this.label,
    required this.value,
    this.tooltip,
    this.color,
  });
}

class SimpleBarChart extends StatefulWidget {
  final List<BarChartBar> bars;
  final double height;
  final int? selectedIndex;
  final ValueChanged<int>? onSelected;

  const SimpleBarChart({
    super.key,
    required this.bars,
    this.height = 210,
    this.selectedIndex,
    this.onSelected,
  });

  @override
  State<SimpleBarChart> createState() => _SimpleBarChartState();
}

class _SimpleBarChartState extends State<SimpleBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant SimpleBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bars != widget.bars) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(Offset local, Size size) {
    if (widget.bars.isEmpty) return;

    final leftPad = 14.0;
    final rightPad = 14.0;
    final topPad = 12.0;
    final bottomPad = 44.0;

    final usableW = max(1.0, size.width - leftPad - rightPad);
    final usableH = max(1.0, size.height - topPad - bottomPad);

    final dx = (local.dx - leftPad).clamp(0.0, usableW);
    if (local.dy < topPad || local.dy > (topPad + usableH)) return;

    final slot = usableW / max(1, widget.bars.length);
    final idx = (dx / slot).floor().clamp(0, widget.bars.length - 1);
    widget.onSelected?.call(idx);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _handleTap(d.localPosition, size),
                onPanDown: (d) => _handleTap(d.localPosition, size),
                onPanUpdate: (d) => _handleTap(d.localPosition, size),
                child: CustomPaint(
                  painter: _BarPainter(
                    bars: widget.bars,
                    selectedIndex: widget.selectedIndex,
                    t: Curves.easeOutCubic.transform(_controller.value),
                    scheme: scheme,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<BarChartBar> bars;
  final int? selectedIndex;
  final double t;
  final ColorScheme scheme;

  _BarPainter({
    required this.bars,
    required this.selectedIndex,
    required this.t,
    required this.scheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = scheme.surfaceContainerHighest.withValues(alpha: 0.25);
    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12));
    canvas.drawRRect(rect, bgPaint);

    if (bars.isEmpty) return;

    final leftPad = 14.0;
    final rightPad = 14.0;
    final topPad = 12.0;
    final bottomPad = 44.0;

    final usableW = max(1.0, size.width - leftPad - rightPad);
    final usableH = max(1.0, size.height - topPad - bottomPad);

    double maxV = 0;
    for (final b in bars) {
      maxV = max(maxV, b.value);
    }
    if (maxV <= 0) maxV = 1;

    final slot = usableW / max(1, bars.length);
    final barW = slot * 0.62;

    for (int i = 0; i < bars.length; i++) {
      final b = bars[i];
      final xCenter = leftPad + (i + 0.5) * slot;
      final h = usableH * (b.value / maxV) * t;
      final top = topPad + (usableH - h);
      final left = xCenter - barW / 2;

      final isSel = selectedIndex == i;
      final baseColor = b.color ?? scheme.primary;

      final fill = Paint()
        ..color = isSel ? baseColor.withValues(alpha: 0.90) : baseColor.withValues(alpha: 0.70)
        ..style = PaintingStyle.fill;

      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barW, h),
        const Radius.circular(10),
      );
      canvas.drawRRect(r, fill);

      final border = Paint()
        ..color = scheme.onSurface.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(r, border);

      // labels
      final tp = TextPainter(
        text: TextSpan(
          text: b.label,
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.70),
            fontSize: 11,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: slot);

      tp.paint(canvas, Offset(xCenter - tp.width / 2, size.height - bottomPad + 6));

      if (isSel) {
        final text = b.tooltip ?? '${b.value.toStringAsFixed(0)}';
        final tip = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final pad = 8.0;
        final bubbleW = tip.width + pad * 2;
        final bubbleH = tip.height + pad * 2;

        final bx = (xCenter - bubbleW / 2).clamp(6.0, size.width - bubbleW - 6.0);
        final by = (top - bubbleH - 10).clamp(6.0, size.height - bubbleH - 6.0);

        final bubbleRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, bubbleW, bubbleH),
          const Radius.circular(10),
        );
        canvas.drawRRect(bubbleRect, Paint()..color = scheme.surface);
        canvas.drawRRect(
          bubbleRect,
          Paint()
            ..color = scheme.onSurface.withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke,
        );
        tip.paint(canvas, Offset(bx + pad, by + pad));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.t != t ||
        oldDelegate.scheme != scheme;
  }
}
