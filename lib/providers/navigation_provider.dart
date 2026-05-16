// ============================================================
// RailGuide — Navigation Provider
// providers/navigation_provider.dart
// ============================================================

import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../core/dijkstra_engine.dart';
import '../models/station_graph.dart';
import '../models/station_node.dart';

// Renamed to avoid clash with Flutter's own NavigationMode
enum AppNavigationMode { railway, campus }

// ──────────────────────────────────────────────────────────
// Campus Graph Factory — RNSIT nodes & edges
// ──────────────────────────────────────────────────────────
// ──────────────────────────────────────────────────────────
// Campus Graph Factory — RNSIT nodes & edges
// ──────────────────────────────────────────────────────────
class CampusGraphFactory {
  static StationGraph buildCampusGraph() {
    final nodes = {
      'main_gate': const StationNode(
        id: 'main_gate',
        displayName: 'Main Gate',
        coordinate: Offset(0, 0),
        icon: '⛩️',
        qrCode: 'RNSIT_GATE',
      ),
      'cse_block': const StationNode(
        id: 'cse_block',
        displayName: 'CSE Block',
        coordinate: Offset(12, 18),
        icon: '💻',
        qrCode: 'RNSIT_CSE',
      ),
      'mba_block': const StationNode(
        id: 'mba_block',
        displayName: 'MBA Block',
        coordinate: Offset(22, 10),
        icon: '🏛️',
        qrCode: 'RNSIT_MBA',
      ),
      // FIX 1: Food Court coordinate updated and renamed
      'food_court': const StationNode(
        id: 'food_court',
        displayName: 'Food Court',
        coordinate: Offset(67, 221),
        icon: '🍽️',
        qrCode: 'RNSIT_FOOD',
      ),
      // FIX 2: Corrected node at (102, 221) to Library
      'library': const StationNode(
        id: 'library',
        displayName: 'Library',
        coordinate: Offset(102, 221),
        icon: '📚',
        qrCode: 'RNSIT_LIBRARY',
      ),
      'temple_parking': const StationNode(
        id: 'temple_parking',
        displayName: 'Temple / Parking',
        coordinate: Offset(0, 303),
        icon: '🛕',
        qrCode: 'RNSIT_TEMPLE',
      ),
    };

    final edges = <String, List<StationEdge>>{};

    void addEdge(String a, String b) {
      if (!nodes.containsKey(a) || !nodes.containsKey(b)) return;
      final w = sqrt(
        pow(nodes[a]!.coordinate.dx - nodes[b]!.coordinate.dx, 2) +
        pow(nodes[a]!.coordinate.dy - nodes[b]!.coordinate.dy, 2),
      );
      edges.putIfAbsent(a, () => []).add(StationEdge(toNodeId: b, weight: w));
      edges.putIfAbsent(b, () => []).add(StationEdge(toNodeId: a, weight: w));
    }

    // --- Graph Connections ---
    addEdge('main_gate', 'cse_block');
    addEdge('cse_block', 'mba_block');
    
    // FIX 3: Direct MBA to Temple/Parking shortcut
    // This allows the algorithm to bypass the long detour through the Food Court
    addEdge('mba_block', 'temple_parking'); 
    
    // Remote Area Path
    addEdge('cse_block', 'food_court');
    addEdge('food_court', 'library');
    addEdge('main_gate', 'temple_parking');

    return StationGraph(nodes: nodes, edges: edges);
  }
}

// ──────────────────────────────────────────────────────────
// Navigation Provider
// ──────────────────────────────────────────────────────────
class NavigationProvider extends ChangeNotifier {
  AppNavigationMode _mode = AppNavigationMode.railway;
  AppNavigationMode get mode => _mode;

  late final StationGraph   _railwayGraph;
  late final DijkstraEngine _railwayEngine;
  late final StationGraph   _campusGraph;
  late final DijkstraEngine _campusEngine;

  StationNode? _startNode;
  StationNode? _endNode;
  PathResult?  _result;

  StationNode? _campusStart;
  StationNode? _campusEnd;
  PathResult?  _campusResult;

  bool _isComputing = false;

  NavigationProvider() {
    _railwayGraph  = StationGraphFactory.buildStationGraph();
    _railwayEngine = DijkstraEngine(graph: _railwayGraph);
    _campusGraph   = CampusGraphFactory.buildCampusGraph();
    _campusEngine  = DijkstraEngine(graph: _campusGraph);
  }

  // Getters — Railway
  StationGraph get graph     => _railwayGraph;
  StationNode? get startNode => _startNode;
  StationNode? get endNode   => _endNode;
  PathResult?  get result    => _result;

  // Getters — Campus
  StationGraph get campusGraph     => _campusGraph;
  StationNode? get campusStartNode => _campusStart;
  StationNode? get campusEndNode   => _campusEnd;
  PathResult?  get campusResult    => _campusResult;

  bool get isComputing => _isComputing;

  List<StationNode> get allNodes    => _railwayGraph.nodes.values.toList();
  List<StationNode> get campusNodes => _campusGraph.nodes.values.toList();

  void setMode(AppNavigationMode mode) {
    _mode = mode;
    notifyListeners();
  }

  // Railway
  void onQrScanned(String rawValue) {
    final node =
        _railwayGraph.nodeByQrCode(rawValue.trim().toLowerCase());
    if (node != null) {
      _startNode = node;
      _result = null;
      notifyListeners();
    }
  }

  void setDestination(String nodeId) {
    _endNode = _railwayGraph.nodes[nodeId];
    _result = null;
    notifyListeners();
  }

  Future<void> computePath() async {
    if (_startNode == null || _endNode == null) return;
    _isComputing = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _result = _railwayEngine.findShortestPath(
        _startNode!.id, _endNode!.id);
    _isComputing = false;
    notifyListeners();
  }

  // Campus
  void setCampusStart(String nodeId) {
    _campusStart = _campusGraph.nodes[nodeId];
    _campusResult = null;
    if (_campusEnd?.id == nodeId) _campusEnd = null;
    notifyListeners();
  }

  void setCampusEnd(String nodeId) {
    _campusEnd = _campusGraph.nodes[nodeId];
    _campusResult = null;
    notifyListeners();
  }

  Future<void> computeCampusPath() async {
    if (_campusStart == null || _campusEnd == null) return;
    _isComputing = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _campusResult = _campusEngine.findShortestPath(
        _campusStart!.id, _campusEnd!.id);
    _isComputing = false;
    notifyListeners();
  }

  void reset() {
    _startNode    = null;
    _endNode      = null;
    _result       = null;
    _campusStart  = null;
    _campusEnd    = null;
    _campusResult = null;
    notifyListeners();
  }
}