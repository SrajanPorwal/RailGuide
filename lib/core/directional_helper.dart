// ============================================================
// RailGuide — DirectionalHelper
// core/directional_helper.dart
//
// Handles all spatial math:
//   • Angle between two 2D grid coordinates   (atan2)
//   • Euclidean distance between nodes
//   • Arrow rotation = target angle − compass heading
//   • Natural-language direction labels
//   • Full TTS instruction builder
// ============================================================

import 'dart:math' as math;

class DirectionalHelper {
  // ── Angle (degrees) from [current] toward [target] ────────
  // Uses atan2 on the (x,y) grid. 0° = East, 90° = South,
  // -90° = North, 180°/-180° = West  (standard math coords).
  // We convert to a 0-360 bearing afterward.
  static double angleToDeg(
    double currentX, double currentY,
    double targetX,  double targetY,
  ) {
    final dx = targetX - currentX;
    final dy = targetY - currentY; // positive = South on our grid
    final rad = math.atan2(dy, dx);
    return _radToDeg(rad);
  }

  // ── Arrow rotation = grid angle − compass heading ─────────
  // Returns the rotation (degrees) to apply to the arrow icon.
  // When the result is 0, the arrow already points at the target.
  static double arrowRotation({
    required double currentX,
    required double currentY,
    required double targetX,
    required double targetY,
    required double compassHeadingDeg, // 0-360, 0=North, clockwise
  }) {
    // Grid angle in standard math degrees
    final gridAngle = angleToDeg(currentX, currentY, targetX, targetY);

    // Convert compass heading from "North=0, clockwise" to math coords
    // Compass: N=0, E=90, S=180, W=270
    // Math:    E=0, N=90, W=180, S=270
    // Conversion: mathBearing = 90 - compassHeading
    final mathBearing = 90.0 - compassHeadingDeg;

    // Arrow needs to rotate by (gridAngle - mathBearing) degrees
    double rotation = gridAngle - mathBearing;

    // Normalize to -180 … +180
    rotation = _normalise(rotation);
    return rotation;
  }

  // ── Euclidean distance between two grid nodes ─────────────
  // Our grid units map 1:1 to metres for the station graph,
  // and to actual metres for the campus graph.
  static double distanceMeters(
    double x1, double y1,
    double x2, double y2,
  ) {
    return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
  }

  // ── Cardinal/intercardinal direction label ────────────────
  // Returns one of: N, NE, E, SE, S, SW, W, NW
  // based on the target angle relative to North.
  static String compassLabel({
    required double currentX, required double currentY,
    required double targetX,  required double targetY,
  }) {
    // Convert our grid angle (East=0°) to a North-based compass bearing
    final gridAngle = angleToDeg(currentX, currentY, targetX, targetY);
    // North-based bearing = 90 - gridAngle
    double bearing = _normalise(90 - gridAngle);
    if (bearing < 0) bearing += 360;

    // 8-point compass
    const labels = ['N','NE','E','SE','S','SW','W','NW'];
    final idx = ((bearing + 22.5) % 360 ~/ 45).clamp(0, 7);
    return labels[idx];
  }

  // ── Full spoken direction instruction ────────────────────
  // "Point found. Move forward 45 meters and then turn South-East
  //  toward Platform 2."
  static String buildTtsInstruction({
    required String currentNodeName,
    required String nextNodeName,
    required double currentX, required double currentY,
    required double targetX,  required double targetY,
  }) {
    final dist = distanceMeters(currentX, currentY, targetX, targetY);
    final dir  = compassLabel(
      currentX: currentX, currentY: currentY,
      targetX: targetX,   targetY: targetY,
    );
    final dirFull = _expandDirection(dir);
    final distStr = dist < 1
        ? 'less than one meter'
        : '${dist.toStringAsFixed(0)} meters';

    return 'Point found. '
        'Move forward $distStr '
        'and then turn $dirFull '
        'toward $nextNodeName.';
  }

  // ── Remaining distance HUD string ─────────────────────────
  static String hudDistance(double meters) {
    if (meters < 1)   return '< 1 m';
    if (meters < 100) return '${meters.toStringAsFixed(1)} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  // ── Private helpers ───────────────────────────────────────

  static double _radToDeg(double rad) => rad * 180.0 / math.pi;

  /// Normalise angle to -180 … +180
  static double _normalise(double deg) {
    deg = deg % 360;
    if (deg > 180)  deg -= 360;
    if (deg < -180) deg += 360;
    return deg;
  }

  static String _expandDirection(String short) {
    const map = {
      'N':  'North',
      'NE': 'North-East',
      'E':  'East',
      'SE': 'South-East',
      'S':  'South',
      'SW': 'South-West',
      'W':  'West',
      'NW': 'North-West',
    };
    return map[short] ?? short;
  }
}