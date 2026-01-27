import 'dart:math';

import 'package:flutter/material.dart';

class LineChartPoint {
  final String label;
  final double value;
  final String? tooltip;

  const LineChartPoint({required this.label, required this.value, this.tooltip});
}

class SimpleLineChart extends StatefulWidget {
  final List<LineChartPoint> points;
  final double height;
  final ValueChanged<int>? onSelected;
  final int? selectedIndex;

  const SimpleLineChart({
    super.key,
    required this.points,
    this.height = 190,
    this.onSelected,
    this.selectedIndex,
  });

  @override
  State<SimpleLineChart> createState() => _SimpleLineChartState();
}

class _SimpleLineChartState extends State<SimpleLineChart>
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
  void didUpdateWidget(covariant SimpleLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
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
    if (widget.points.isEmpty) return;
    final leftPad = 24.0;
    final rightPad = 12.0;
    final usableW = max(1.0, size.width - leftPad - rightPad);

    final dx = (local.dx - leftPad).clamp(0.0, usableW);
    final t = dx / usableW;

    final idx = (t * (widget.points.length - 1)).round().clamp(0, widget.points.length - 1);
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
                  painter: _LinePainter(
                    points: widget.points,
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

class _LinePainter extends CustomPainter {
  final List<LineChartPoint> points;
  final int? selectedIndex;
  final double t;
  final ColorScheme scheme;

  _LinePainter({
    required this.points,
    required this.selectedIndex,
    required this.t,
    required this.scheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = scheme.surfaceContainerHighest.withValues(alpha: 0.25);

    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12));
    canvas.drawRRect(rect, bgPaint);

    if (points.isEmpty) return;

    final leftPad = 24.0;
    final rightPad = 12.0;
    final topPad = 12.0;
    final bottomPad = 26.0;

    final usableW = max(1.0, size.width - leftPad - rightPad);
    final usableH = max(1.0, size.height - topPad - bottomPad);

    double maxV = 0;
    for (final p in points) {
      maxV = max(maxV, p.value);
    }
    if (maxV <= 0) maxV = 1;

    // Grid
    final gridPaint = Paint()
      ..color = scheme.onSurface.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = topPad + usableH * (i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + usableW, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = scheme.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = leftPad + (i / max(1, points.length - 1)) * usableW;
      final y = topPad + usableH * (1 - (points[i].value / maxV) * t);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    // Points
    final dotPaint = Paint()..color = scheme.primary;
    final selPaint = Paint()..color = scheme.primaryContainer;

    for (int i = 0; i < points.length; i++) {
      final x = leftPad + (i / max(1, points.length - 1)) * usableW;
      final y = topPad + usableH * (1 - (points[i].value / maxV) * t);
      final isSel = selectedIndex == i;
      if (isSel) {
        canvas.drawCircle(Offset(x, y), 7, selPaint);
        canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
      } else {
        canvas.drawCircle(Offset(x, y), 2.8, dotPaint);
      }

      // x labels (first/last + selected)
      final shouldLabel = i == 0 || i == points.length - 1 || isSel;
      if (shouldLabel) {
        final tp = TextPainter(
          text: TextSpan(
            text: points[i].label,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.65),
              fontSize: 11,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 56);

        final dx = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
        tp.paint(canvas, Offset(dx, size.height - bottomPad + 6));
      }
    }

    // Selected tooltip
    if (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < points.length) {
      final idx = selectedIndex!;
      final x = leftPad + (idx / max(1, points.length - 1)) * usableW;
      final y = topPad + usableH * (1 - (points[idx].value / maxV) * t);
      final text = points[idx].tooltip ?? '${points[idx].value.toStringAsFixed(0)}';

      final tp = TextPainter(
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
      final bubbleW = tp.width + pad * 2;
      final bubbleH = tp.height + pad * 2;

      final bx = (x - bubbleW / 2).clamp(6.0, size.width - bubbleW - 6.0);
      final by = (y - bubbleH - 12).clamp(6.0, size.height - bubbleH - 6.0);

      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, bubbleW, bubbleH),
        const Radius.circular(10),
      );

      canvas.drawRRect(
        bubbleRect,
        Paint()..color = scheme.surface,
      );
      canvas.drawRRect(
        bubbleRect,
        Paint()
          ..color = scheme.onSurface.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke,
      );

      tp.paint(canvas, Offset(bx + pad, by + pad));
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.t != t ||
        oldDelegate.scheme != scheme;
  }
}
