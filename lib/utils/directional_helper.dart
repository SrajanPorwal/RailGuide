// ============================================================
// RailGuide — DirectionalHelper (Pure Static Production Build)
// lib/utils/directional_helper.dart
// ============================================================

import 'dart:math' as math;

class DirectionalHelper {
  // ── Absolute compass bearing (0-360°) from current → target ──
  static double absoluteBearing({
    required double currentX, required double currentY,
    required double targetX,  required double targetY,
  }) {
    final dx = targetX - currentX;
    final dy = -(targetY - currentY); // flip Y: grid Y↑ = North

    double bearing = 90.0 - (math.atan2(dy, dx) * 180.0 / math.pi);
    return ((bearing % 360) + 360) % 360;
  }

  // ── Arrow rotation angle for Transform.rotate ─────────────
  static double arrowRotationRad({
    required double currentX,
    required double currentY,
    required double targetX,
    required double targetY,
    required double compassHeadingDeg,
  }) {
    final bearing = absoluteBearing(
      currentX: currentX, currentY: currentY,
      targetX: targetX,   targetY: targetY,
    );

    double diff = bearing - compassHeadingDeg;
    diff = ((diff + 180) % 360) - 180; // Normalise to -180..+180
    return diff * math.pi / 180.0;
  }

  // ── Euclidean distance between two nodes ──────────────────
  static double distanceMeters(double x1, double y1, double x2, double y2) {
    return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
  }

  // ── 8-point compass label for the bearing ─────────────────
  static String compassLabel({
    required double currentX, required double currentY,
    required double targetX,  required double targetY,
  }) {
    final bearing = absoluteBearing(
      currentX: currentX, currentY: currentY,
      targetX: targetX,   targetY: targetY,
    );

    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((bearing + 22.5) % 360 ~/ 45).clamp(0, 7);
    return labels[idx];
  }

  // ── Human-readable turn instruction ───────────────────────
  static String turnInstruction({
    required double compassHeadingDeg,
    required double currentX, required double currentY,
    required double targetX,  required double targetY,
  }) {
    final bearing = absoluteBearing(
      currentX: currentX, currentY: currentY,
      targetX: targetX,   targetY: targetY,
    );

    double diff = bearing - compassHeadingDeg;
    diff = ((diff + 180) % 360) - 180;

    if (diff.abs() <= 20)        return 'Continue straight ahead';
    if (diff > 20 && diff <= 60)  return 'Bear right';
    if (diff > 60 && diff <= 120) return 'Turn right';
    if (diff > 120)               return 'Turn sharp right';
    if (diff < -20 && diff >= -60) return 'Bear left';
    if (diff < -60 && diff >= -120) return 'Turn left';
    return 'Turn sharp left';
  }

  // ── HUD distance string ────────────────────────────────────
  static String hudDistance(double meters) {
    if (meters < 1)   return '< 1 m';
    if (meters < 100) return '${meters.toStringAsFixed(1)} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  // ── Full TTS instruction ───────────────────────────────────
  static String buildTtsInstruction({
    required String currentNodeName,
    required String nextNodeName,
    required double currentX, required double currentY,
    required double targetX,  required double targetY,
    double? compassHeadingDeg,
  }) {
    final dist    = distanceMeters(currentX, currentY, targetX, targetY);
    final dir     = compassLabel(currentX: currentX, currentY: currentY, targetX: targetX, targetY: targetY);
    final dirFull = _expandDirection(dir);
    final distStr = dist < 1 ? 'less than one meter' : '${dist.toStringAsFixed(0)} meters';

    String turnStr = '';
    if (compassHeadingDeg != null) {
      final turn = turnInstruction(
        compassHeadingDeg: compassHeadingDeg,
        currentX: currentX, currentY: currentY,
        targetX: targetX,   targetY: targetY,
      );
      turnStr = ' $turn and head $dirFull.';
    } else {
      turnStr = ' Head $dirFull.';
    }

    return 'Point found. Move forward $distStr toward $nextNodeName.$turnStr';
  }

  static String _expandDirection(String short) {
    const map = {
      'N':  'North',     'NE': 'North-East',
      'E':  'East',      'SE': 'South-East',
      'S':  'South',     'SW': 'South-West',
      'W':  'West',      'NW': 'North-West',
    };
    return map[short] ?? short;
  }
}