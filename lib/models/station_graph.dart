// ============================================================
// RailGuide — Station Graph Model
// models/station_graph.dart
// ============================================================

import 'station_node.dart';

/// Holds the complete graph: a map of nodes and an adjacency
/// list of weighted directed edges.
class StationGraph {
  /// All navigable nodes, keyed by their ID
  final Map<String, StationNode> nodes;

  /// Adjacency list: nodeId → list of outgoing edges
  final Map<String, List<StationEdge>> edges;

  const StationGraph({
    required this.nodes,
    required this.edges,
  });

  /// Returns all node IDs suitable for destination selection
  List<String> get destinationIds => nodes.keys.toList();

  /// Returns a node by its QR code payload, or null if not found
  StationNode? nodeByQrCode(String qrCode) {
    for (final node in nodes.values) {
      if (node.qrCode.toLowerCase() == qrCode.toLowerCase()) {
        return node;
      }
    }
    return null;
  }
}