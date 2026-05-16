// ============================================================
// RailGuide — Station Node Model
// models/station_node.dart
// ============================================================

import 'dart:ui';

/// Represents a navigable location within the railway station.
class StationNode {
  /// Unique identifier (matches QR code string)
  final String id;

  /// Human-readable name shown in the UI
  final String displayName;

  /// 2D grid coordinate (x, y) for map rendering
  final Offset coordinate;

  /// Emoji icon for visual representation
  final String icon;

  /// QR code payload string that maps to this node
  final String qrCode;

  const StationNode({
    required this.id,
    required this.displayName,
    required this.coordinate,
    required this.icon,
    required this.qrCode,
  });
}

// ============================================================
// RailGuide — Station Edge Model
// models/station_node.dart (continued)
// ============================================================

/// Represents a directed weighted edge in the station graph.
class StationEdge {
  /// ID of the destination node
  final String toNodeId;

  /// Cost/distance of traversing this edge
  final double weight;

  const StationEdge({
    required this.toNodeId,
    required this.weight,
  });
}