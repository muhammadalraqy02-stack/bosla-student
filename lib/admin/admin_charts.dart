// مخططات لوحة المعلومات: المخطط الدائري لتوزيع الأقسام، والمخطط الخطي الشهري — مثل نسخة الويب

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils.dart';
import '../widgets/common.dart';

class DonutPart {
  final String label;
  final num value;
  final Color color;
  const DonutPart(this.label, this.value, this.color);
}

class DonutChart extends StatelessWidget {
  final List<DonutPart> parts;
  const DonutChart({super.key, required this.parts});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final total = parts.fold<num>(0, (a, b) => a + b.value);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CustomPaint(
            painter: _DonutPainter(parts, total, p.border),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('الإجمالي', style: TextStyle(fontSize: 11, color: p.muted)),
                  Text(fmtNum(total), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.text)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final x in parts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: x.color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(x.label, style: TextStyle(fontSize: 12, color: p.text))),
                      Text(
                        '${fmtNum(x.value)} (${total > 0 ? (x.value / total * 100).toStringAsFixed(1) : '0.0'}%)',
                        style: TextStyle(fontSize: 11.5, color: p.muted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutPart> parts;
  final num total;
  final Color track;
  _DonutPainter(this.parts, this.total, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 20.0;
    final r = math.min(size.width, size.height) / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    canvas.drawArc(rect, 0, math.pi * 2, false,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    if (parts.isEmpty) return;
    var start = -math.pi / 2;
    const gap = 0.04;
    for (final x in parts) {
      final frac = total > 0 ? x.value / total : 1 / parts.length;
      final sweep = frac * math.pi * 2;
      if (sweep > gap) {
        canvas.drawArc(rect, start, sweep - (total > 0 ? gap : 0), false,
            Paint()
              ..color = x.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.parts != parts || old.total != total;
}

class LineChart extends StatelessWidget {
  final List<String> labels;
  final List<int> values;
  final String metricLabel;
  const LineChart({super.key, required this.labels, required this.values, required this.metricLabel});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    var peak = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[peak]) peak = i;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (values.isNotEmpty)
          Text(
            'الأعلى: ${labels[peak]} ${DateTime.now().year} — $metricLabel: ${fmtNum(values[peak])}',
            style: TextStyle(fontSize: 11.5, color: p.muted),
          ),
        const SizedBox(height: 8),
        SizedBox(
          height: 190,
          child: CustomPaint(
            painter: _LinePainter(labels, values, p.border, p.muted, const Color(0xFF8B5CF6), peak),
          ),
        ),
      ],
    );
  }
}

int _niceMax(int v) {
  if (v <= 5) return 5;
  final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toInt();
  for (final m in [1, 2, 5, 10]) {
    if (v <= m * mag) return m * mag;
  }
  return v;
}

class _LinePainter extends CustomPainter {
  final List<String> labels;
  final List<int> values;
  final Color grid;
  final Color text;
  final Color line;
  final int peak;
  _LinePainter(this.labels, this.values, this.grid, this.text, this.line, this.peak);

  void _text(Canvas c, String s, Offset at, {TextAlign align = TextAlign.center}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: 10, color: text)),
      textDirection: TextDirection.rtl,
      textAlign: align,
    )..layout();
    final dx = align == TextAlign.center ? at.dx - tp.width / 2 : (align == TextAlign.right ? at.dx - tp.width : at.dx);
    tp.paint(c, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const left = 34.0, top = 8.0;
    final right = size.width - 8;
    final bot = size.height - 22;
    final mv = values.reduce(math.max);
    final maxV = _niceMax(mv < 1 ? 1 : mv);
    double x(int i) => values.length > 1 ? left + (right - left) * i / (values.length - 1) : (left + right) / 2;
    double y(num v) => bot - (bot - top) * (v / maxV);
    final gp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    const rows = 4;
    for (var k = 0; k <= rows; k++) {
      final yy = top + k * (bot - top) / rows;
      canvas.drawLine(Offset(left, yy), Offset(right, yy), gp);
      _text(canvas, '${(maxV - k * maxV / rows).round()}', Offset(left - 6, yy), align: TextAlign.right);
    }
    final pts = [for (var i = 0; i < values.length; i++) Offset(x(i), y(values[i]))];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final mx = (a.dx + b.dx) / 2;
      path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    final area = Path.from(path)
      ..lineTo(pts.last.dx, bot)
      ..lineTo(pts.first.dx, bot)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [line.withValues(alpha: 0.30), line.withValues(alpha: 0.02)],
        ).createShader(Rect.fromLTRB(left, top, right, bot)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    for (var i = 0; i < pts.length; i++) {
      canvas.drawCircle(pts[i], i == peak ? 5.5 : 4, Paint()..color = line);
      canvas.drawCircle(pts[i], i == peak ? 2.5 : 1.8, Paint()..color = Colors.white);
      _text(canvas, labels[i], Offset(pts[i].dx, size.height - 8));
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.values != values;
}
