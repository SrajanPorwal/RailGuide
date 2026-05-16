// ============================================================
// RailGuide — DijkstraEngine (Updated for RNSIT Campus)
// core/dijkstra_engine.dart
// ============================================================

import 'dart:math';
import 'dart:ui';
import '../models/station_node.dart';
import '../models/station_graph.dart';

class PathResult {
  final List<String> path;
  final double totalDistance;
  final List<String> instructions;

  bool get found => path.isNotEmpty;

  const PathResult({
    required this.path,
    required this.totalDistance,
    required this.instructions,
  });

  factory PathResult.notFound() => const PathResult(
        path: [],
        totalDistance: double.infinity,
        instructions: ['No path found between selected nodes.'],
      );
}

class DijkstraEngine {
  final StationGraph graph;
  DijkstraEngine({required this.graph});

  PathResult findShortestPath(String startId, String endId) {
    if (startId == endId) {
      final node = graph.nodes[startId];
      return PathResult(
        path: [startId],
        totalDistance: 0,
        instructions: ['You are already at ${node?.displayName ?? startId}.'],
      );
    }

    if (!graph.nodes.containsKey(startId) ||
        !graph.nodes.containsKey(endId)) {
      return PathResult.notFound();
    }

    final Map<String, double> dist = {};
    final Map<String, String?> prev = {};
    final Set<String> visited = {};

    for (final nodeId in graph.nodes.keys) {
      dist[nodeId] = double.infinity;
      prev[nodeId] = null;
    }
    dist[startId] = 0;

    while (true) {
      String? u;
      double minDist = double.infinity;
      for (final nodeId in graph.nodes.keys) {
        if (!visited.contains(nodeId) && dist[nodeId]! < minDist) {
          minDist = dist[nodeId]!;
          u = nodeId;
        }
      }
      if (u == null || u == endId) break;
      visited.add(u);

      for (final edge in (graph.edges[u] ?? [])) {
        if (visited.contains(edge.toNodeId)) continue;
        final newDist = dist[u]! + edge.weight;
        if (newDist < dist[edge.toNodeId]!) {
          dist[edge.toNodeId] = newDist;
          prev[edge.toNodeId] = u;
        }
      }
    }

    if (dist[endId] == double.infinity) return PathResult.notFound();

    final List<String> path = [];
    String? current = endId;
    while (current != null) {
      path.insert(0, current);
      current = prev[current];
    }

    return PathResult(
      path: path,
      totalDistance: dist[endId]!,
      instructions: _buildInstructions(path),
    );
  }

  List<String> _buildInstructions(List<String> path) {
    if (path.isEmpty) return [];
    final instructions = <String>[];
    final startNode = graph.nodes[path.first];
    instructions.add('📍 Start at ${startNode?.displayName ?? path.first}');

    for (int i = 0; i < path.length - 1; i++) {
      final from = graph.nodes[path[i]];
      final to   = graph.nodes[path[i + 1]];

      // Custom instruction for bridge crossing (Station Mode)
      if ((path[i] == 'bridge_start' && path[i + 1] == 'bridge_end') ||
          (path[i] == 'bridge_end'   && path[i + 1] == 'bridge_start')) {
        instructions.add('🌉 Cross the foot-over bridge');
      } else {
        final dir  = _getDirection(from?.coordinate, to?.coordinate);
        final icon = to?.icon ?? '➡️';
        final name = to?.displayName ?? path[i + 1];
        instructions.add('$icon Head $dir to $name');
      }
    }

    final endNode = graph.nodes[path.last];
    instructions.add('✅ Arrived at ${endNode?.displayName ?? path.last}');
    return instructions;
  }

  String _getDirection(Offset? from, Offset? to) {
    if (from == null || to == null) return '';
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    if (dx.abs() > dy.abs()) return dx > 0 ? 'East' : 'West';
    if (dy.abs() > dx.abs()) return dy > 0 ? 'South' : 'North';
    if (dx > 0 && dy > 0) return 'South-East';
    if (dx > 0 && dy < 0) return 'North-East';
    if (dx < 0 && dy > 0) return 'South-West';
    return 'North-West';
  }
}

// ──────────────────────────────────────────────────────────
// Campus Graph Factory — RNSIT
// ──────────────────────────────────────────────────────────
class StationGraphFactory {

  // ── CAMPUS MODE (RNSIT) ───────────────────────────────
  static StationGraph buildCampusGraph() {

    // ── Nodes ─────────────────────────────────────────
    // FIX 1: Renamed food_court_b (102,221) → library
    //        The node at (67,221) is Food Court
    //        The node at (102,221) is Library (not a second food court)
    final nodes = {
      'main_gate': const StationNode(
        id: 'main_gate',
        displayName: 'Main Gate',
        coordinate: Offset(0, 0),
        icon: '⛩️',
        qrCode: 'rnsit_gate',
      ),
      'parking': const StationNode(
        id: 'parking',
        displayName: 'Parking',
        coordinate: Offset(0, -5),
        icon: '🅿️',
        qrCode: 'rnsit_parking',
      ),
      'temple': const StationNode(
        id: 'temple',
        displayName: 'Temple',
        coordinate: Offset(5, 5),
        icon: '🛕',
        qrCode: 'rnsit_temple',
      ),
      'mba_block': const StationNode(
        id: 'mba_block',
        displayName: 'MBA Block',
        coordinate: Offset(22, 10),
        icon: '🏢',
        qrCode: 'rnsit_mba',
      ),
      // FIX 1a: (67,221) → Food Court (single food court node)
      'food_court': const StationNode(
        id: 'food_court',
        displayName: 'Food Court',
        coordinate: Offset(67, 221),
        icon: '🍽️',
        qrCode: 'rnsit_food',
      ),
      // FIX 1b: (102,221) → Library (was incorrectly named food_court_b)
      'library': const StationNode(
        id: 'library',
        displayName: 'Library',
        coordinate: Offset(102, 221),
        icon: '📚',
        qrCode: 'rnsit_library',
      ),
      'cse_block': const StationNode(
        id: 'cse_block',
        displayName: 'CSE Block',
        coordinate: Offset(12, 18),
        icon: '💻',
        qrCode: 'rnsit_cse',
      ),
    };

    // ── Edges ─────────────────────────────────────────
    final edges = <String, List<StationEdge>>{};

    void addEdge(String a, String b) {
      final w = sqrt(
        pow(nodes[a]!.coordinate.dx - nodes[b]!.coordinate.dx, 2) +
        pow(nodes[a]!.coordinate.dy - nodes[b]!.coordinate.dy, 2),
      );
      edges.putIfAbsent(a, () => [])
          .add(StationEdge(toNodeId: b, weight: w));
      edges.putIfAbsent(b, () => [])
          .add(StationEdge(toNodeId: a, weight: w));
    }

    // ── Gate / Parking / Temple cluster ───────────────
    addEdge('main_gate', 'parking');
    addEdge('main_gate', 'temple');
    addEdge('parking',   'temple');

    // FIX 2: Direct MBA → Parking and MBA → Temple edges.
    // Without these, Dijkstra had to route MBA → CSE → Food Court
    // → (long detour) to reach Parking/Temple because there was no
    // shorter direct path. Now MBA connects directly to both,
    // so MBA → Parking and MBA → Temple are always the shortest routes.
    addEdge('mba_block', 'parking');   // ← direct shortcut
    addEdge('mba_block', 'temple');    // ← direct shortcut
    addEdge('mba_block', 'main_gate'); // ← also connect to gate
    addEdge('mba_block', 'cse_block');

    // ── Academic / Remote cluster ─────────────────────
    // CSE → Food Court → Library (one-way chain into remote area)
    // These are NOT connected back to MBA to avoid the detour loop
    addEdge('cse_block',   'food_court');
    addEdge('food_court',  'library');

    return StationGraph(nodes: nodes, edges: edges);
  }

  // ── STATION MODE (Railway) ────────────────────────────
  static StationGraph buildStationGraph() {
    final nodes = {
      'parking': const StationNode(
        id: 'parking',
        displayName: 'Parking',
        coordinate: Offset(0, 0),
        icon: '🅿️',
        qrCode: 'parking',
      ),
      'entrance': const StationNode(
        id: 'entrance',
        displayName: 'Entrance',
        coordinate: Offset(1, 1),
        icon: '🚪',
        qrCode: 'entrance',
      ),
      'ticket_counter': const StationNode(
        id: 'ticket_counter',
        displayName: 'Ticket Counter',
        coordinate: Offset(2, 1),
        icon: '🎫',
        qrCode: 'ticket_counter',
      ),
      'washrooms': const StationNode(
        id: 'washrooms',
        displayName: 'Washrooms',
        coordinate: Offset(1, 2),
        icon: '🚻',
        qrCode: 'washrooms',
      ),
      'platform_1': const StationNode(
        id: 'platform_1',
        displayName: 'Platform 1',
        coordinate: Offset(4, 2),
        icon: '🚉',
        qrCode: 'platform_1',
      ),
      'bridge_start': const StationNode(
        id: 'bridge_start',
        displayName: 'Bridge Start',
        coordinate: Offset(3, 3),
        icon: '🌉',
        qrCode: 'bridge_start',
      ),
      'bridge_end': const StationNode(
        id: 'bridge_end',
        displayName: 'Bridge End',
        coordinate: Offset(3, 5),
        icon: '🌉',
        qrCode: 'bridge_end',
      ),
      'platform_2': const StationNode(
        id: 'platform_2',
        displayName: 'Platform 2',
        coordinate: Offset(5, 5),
        icon: '🚉',
        qrCode: 'platform_2',
      ),
    };

    final edges = <String, List<StationEdge>>{};
    void addEdge(String a, String b) {
      final w = sqrt(
        pow(nodes[a]!.coordinate.dx - nodes[b]!.coordinate.dx, 2) +
        pow(nodes[a]!.coordinate.dy - nodes[b]!.coordinate.dy, 2),
      );
      edges.putIfAbsent(a, () => [])
          .add(StationEdge(toNodeId: b, weight: w));
      edges.putIfAbsent(b, () => [])
          .add(StationEdge(toNodeId: a, weight: w));
    }

    addEdge('parking',        'entrance');
    addEdge('entrance',       'ticket_counter');
    addEdge('entrance',       'washrooms');
    addEdge('ticket_counter', 'platform_1');
    addEdge('platform_1',     'bridge_start');
    addEdge('bridge_start',   'bridge_end');
    addEdge('bridge_end',     'platform_2');
    addEdge('ticket_counter', 'bridge_start');

    return StationGraph(nodes: nodes, edges: edges);
  }
}