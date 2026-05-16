// ============================================================
// RailGuide — Station Map Painter
// widgets/station_map_painter.dart
// ============================================================

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/station_graph.dart';
// removed unused import: station_node.dart
import '../utils/app_theme.dart';

class StationMapPainter extends CustomPainter {
  final StationGraph graph;
  final List<String> highlightedPath;

  const StationMapPainter({
    required this.graph,
    required this.highlightedPath,
  });

  static const int gridSize = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width  / (gridSize + 1);
    final cellH = size.height / (gridSize + 1);

    Offset toCanvas(Offset coord) => Offset(
          (coord.dx + 0.5) * cellW + cellW * 0.5,
          (coord.dy + 0.5) * cellH + cellH * 0.5,
        );

    // ── Grid dots ─────────────────────────────────────────
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;

    for (int r = 0; r <= gridSize; r++) {
      for (int c = 0; c <= gridSize; c++) {
        canvas.drawCircle(
          Offset((c + 0.5) * cellW + cellW * 0.5,
                 (r + 0.5) * cellH + cellH * 0.5),
          2, gridPaint,
        );
      }
    }

    // ── Path edge set ─────────────────────────────────────
    final pathEdges = <String>{};
    for (int i = 0; i < highlightedPath.length - 1; i++) {
      final a = highlightedPath[i];
      final b = highlightedPath[i + 1];
      pathEdges.add('$a|$b');
      pathEdges.add('$b|$a');
    }

    // ── Edges ─────────────────────────────────────────────
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    graph.edges.forEach((fromId, edges) {
      final fromNode = graph.nodes[fromId];
      if (fromNode == null) return;
      for (final edge in edges) {
        final toNode = graph.nodes[edge.toNodeId];
        if (toNode == null) continue;
        final key = '$fromId|${edge.toNodeId}';
        final isHighlighted = pathEdges.contains(key);
        edgePaint.strokeWidth = isHighlighted ? 3 : 1.5;
        if (isHighlighted) {
          edgePaint.shader = ui.Gradient.linear(
            toCanvas(fromNode.coordinate),
            toCanvas(toNode.coordinate),
            [AppTheme.safetyYellow, AppTheme.railwayBlueLight],
          );
        } else {
          edgePaint.shader = null;
          edgePaint.color = const Color(0xFFCBD5E1);
        }
        canvas.drawLine(
          toCanvas(fromNode.coordinate),
          toCanvas(toNode.coordinate),
          edgePaint,
        );
      }
    });

    // ── Nodes ─────────────────────────────────────────────
    graph.nodes.forEach((nodeId, node) {
      final pos    = toCanvas(node.coordinate);
      final isOnPath = highlightedPath.contains(nodeId);
      final isStart  = highlightedPath.isNotEmpty && highlightedPath.first == nodeId;
      final isEnd    = highlightedPath.isNotEmpty && highlightedPath.last  == nodeId;
      final r = isStart || isEnd ? 18.0 : isOnPath ? 16.0 : 13.0;

      // Glow ring
      if (isOnPath) {
        canvas.drawCircle(
          pos, r + 8,
          Paint()
            ..color = isStart
                ? AppTheme.safetyYellow.withValues(alpha: 0.25)
                : isEnd
                    ? AppTheme.success.withValues(alpha: 0.20)
                    : AppTheme.railwayBlue.withValues(alpha: 0.10)
            ..style = PaintingStyle.fill,
        );
      }

      // Fill
      canvas.drawCircle(pos, r,
        Paint()
          ..color = isStart
              ? AppTheme.safetyYellow
              : isEnd
                  ? AppTheme.success
                  : isOnPath ? AppTheme.railwayBlue : Colors.white
          ..style = PaintingStyle.fill,
      );

      // Border
      canvas.drawCircle(pos, r,
        Paint()
          ..color = isStart
              ? AppTheme.railwayBlue
              : isEnd
                  ? AppTheme.success
                  : isOnPath ? AppTheme.railwayBlue : const Color(0xFFCBD5E1)
          ..strokeWidth = isOnPath ? 2.5 : 1.5
          ..style = PaintingStyle.stroke,
      );

      // Emoji
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.icon,
          style: TextStyle(fontSize: isStart || isEnd ? 14 : 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        pos - Offset(textPainter.width / 2, textPainter.height / 2),
      );

      // Label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: node.displayName.replaceAll(' ', '\n'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: isOnPath ? FontWeight.bold : FontWeight.normal,
            color: isOnPath ? AppTheme.railwayBlue : AppTheme.textLight,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: cellW * 1.8);
      labelPainter.paint(
          canvas, pos + Offset(-labelPainter.width / 2, r + 3));

      // Step badge
      if (isOnPath && !isStart && !isEnd) {
        final stepIdx = highlightedPath.indexOf(nodeId);
        canvas.drawCircle(
          pos + const Offset(12, -12), 9,
          Paint()..color = AppTheme.railwayBlue..style = PaintingStyle.fill,
        );
        final badgeText = TextPainter(
          text: TextSpan(
            text: '$stepIdx',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        badgeText.paint(
          canvas,
          pos + Offset(12 - badgeText.width / 2, -12 - badgeText.height / 2),
        );
      }
    });

    _drawLegend(canvas, size);
  }

  void _drawLegend(Canvas canvas, Size size) {
    final items = [
      (AppTheme.safetyYellow, 'Start'),
      (AppTheme.success,      'End'),
      (AppTheme.railwayBlue,  'Path'),
    ];
    double x = 8;
    for (final item in items) {
      canvas.drawCircle(Offset(x + 6, size.height - 12), 6,
          Paint()..color = item.$1..style = PaintingStyle.fill);
      final tp = TextPainter(
        text: TextSpan(
          text: item.$2,
          style: const TextStyle(
              fontFamily: 'Inter', fontSize: 9, color: Color(0xFF718096)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + 14, size.height - 12 - tp.height / 2));
      x += 52;
    }
  }

  @override
  bool shouldRepaint(StationMapPainter oldDelegate) =>
      oldDelegate.highlightedPath != highlightedPath;
}