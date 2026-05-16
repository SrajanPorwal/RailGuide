import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class DirectionalHelper {
  final FlutterTts flutterTts = FlutterTts();

  DirectionalHelper() {
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5); // Slightly slower for clear instructions
    await flutterTts.setPitch(1.0);
  }

  /// Calculates the Euclidean distance between two nodes (assumes grid units are meters)
  double calculateDistance(Point<double> current, Point<double> target) {
    return current.distanceTo(target);
  }

  /// Calculates the target bearing in degrees (0 to 360, where 0 is North)
  /// based on standard Cartesian coordinates.
  double calculateBearing(Point<double> current, Point<double> target) {
    double dy = target.y - current.y;
    double dx = target.x - current.x;
    
    // atan2 returns angle in radians from -pi to pi
    double radians = atan2(dy, dx);
    double degrees = vector.degrees(radians);
    
    // Convert math angle to compass bearing: 
    // Math 0° (East) -> Compass 90°
    // Math 90° (North) -> Compass 0°
    return (90 - degrees) % 360;
  }

  /// Determines the relative turn phrase based on current phone heading
  String _getTurnDirection(double currentHeading, double targetBearing) {
    double diff = (targetBearing - currentHeading) % 360;
    if (diff < 0) diff += 360; // Normalize

    if (diff > 345 || diff < 15) return "straight";
    if (diff >= 15 && diff <= 165) return "right";
    if (diff >= 195 && diff <= 345) return "left";
    return "around"; // 165 to 195
  }

  /// Triggers the dynamic Voice Command
  Future<void> speakDirections({
    required double distance,
    required double currentHeading,
    required double targetBearing,
    required String nextNodeName,
  }) async {
    String turnDirection = _getTurnDirection(currentHeading, targetBearing);
    String distStr = distance.toStringAsFixed(1);
    
    String text = "Point found. Move forward $distStr meters and then turn $turnDirection toward $nextNodeName.";
    
    await flutterTts.stop(); // Stop any ongoing speech
    await flutterTts.speak(text);
  }
}