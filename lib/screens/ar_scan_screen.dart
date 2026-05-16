// ============================================================
// RailGuide — AR Scan Screen
// screens/ar_scan_screen.dart
//
// Features:
//  • Live camera feed (MobileScanner)
//  • Rotating directional arrow (flutter_compass + DirectionalHelper)
//  • Distance-to-destination HUD
//  • Dynamic TTS instructions on each node scan
//  • Node info overlay with next-step preview
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/directional_helper.dart';
import '../providers/navigation_provider.dart';
import '../models/station_node.dart';
import '../utils/app_theme.dart';

class ArScanScreen extends StatefulWidget {
  /// The ordered list of node IDs forming the Dijkstra path
  final List<String> pathNodeIds;

  /// Set to true when launched from CampusNavigationScreen
  /// so the screen uses the campus graph for node lookups
  final bool isCampusMode;

  const ArScanScreen({
    super.key,
    required this.pathNodeIds,
    this.isCampusMode = false, // ← default false = railway mode
  });

  @override
  State<ArScanScreen> createState() => _ArScanScreenState();
}

class _ArScanScreenState extends State<ArScanScreen>
    with SingleTickerProviderStateMixin {
  // ── Scanner ───────────────────────────────────────────────
  final MobileScannerController _scanCtrl = MobileScannerController();
  bool _hasScanned = false;

  // ── TTS ───────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();

  // ── Path state ────────────────────────────────────────────
  int _currentPathIndex = 0; // which node we're currently AT
  String? _lastScannedId;

  // ── Arrow pulse animation ─────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  // ── HUD display values ────────────────────────────────────
  String _hudDistance   = '---';
  String _hudDirection  = '---';
  String _hudNextNode   = 'Scan your first QR';
  String _hudCurrentNode = '';

  @override
  void initState() {
    super.initState();
    _initTts();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Initial TTS greeting
    Future.delayed(const Duration(milliseconds: 800), () {
      _speak('AR Navigation active. Scan a QR code at your location.');
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _tts.stop();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── QR Detection ─────────────────────────────────────────
  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final value = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (value == null || value.isEmpty) return;

    final nav = context.read<NavigationProvider>();
    // Use campus graph when in campus mode, railway graph otherwise
    final graph = widget.isCampusMode ? nav.campusGraph : nav.graph;
    final scannedNode = graph.nodeByQrCode(value.toLowerCase());
    if (scannedNode == null) return;

    // Prevent duplicate scans of the same node
    if (_lastScannedId == scannedNode.id) return;

    _hasScanned = true;
    _lastScannedId = scannedNode.id;

    // Find where this node sits in the path
    final idx = widget.pathNodeIds.indexOf(scannedNode.id);
    if (idx != -1) {
      setState(() => _currentPathIndex = idx);
    }

    _updateHudAndSpeak(scannedNode, nav);

    // Re-enable scanner after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hasScanned = false);
    });
  }

  void _updateHudAndSpeak(StationNode current, NavigationProvider nav) {
    final pathIds = widget.pathNodeIds;
    final curIdx  = pathIds.indexOf(current.id);
    // Use correct graph based on mode
    final graph = widget.isCampusMode ? nav.campusGraph : nav.graph;

    setState(() => _hudCurrentNode = current.displayName);

    if (curIdx == -1 || curIdx >= pathIds.length - 1) {
      // Reached destination
      setState(() {
        _hudDistance  = '0 m';
        _hudDirection = '🎯';
        _hudNextNode  = 'Destination Reached!';
      });
      _speak('Congratulations! You have arrived at your destination.');
      return;
    }

    final nextNode = graph.nodes[pathIds[curIdx + 1]];
    if (nextNode == null) return;

    final dist = DirectionalHelper.distanceMeters(
      current.coordinate.dx, current.coordinate.dy,
      nextNode.coordinate.dx, nextNode.coordinate.dy,
    );

    final dir = DirectionalHelper.compassLabel(
      currentX: current.coordinate.dx,
      currentY: current.coordinate.dy,
      targetX:  nextNode.coordinate.dx,
      targetY:  nextNode.coordinate.dy,
    );

    setState(() {
      _hudDistance  = DirectionalHelper.hudDistance(dist);
      _hudDirection = dir;
      _hudNextNode  = nextNode.displayName;
    });

    // Build and speak dynamic instruction
    final instruction = DirectionalHelper.buildTtsInstruction(
      currentNodeName: current.displayName,
      nextNodeName:    nextNode.displayName,
      currentX: current.coordinate.dx,
      currentY: current.coordinate.dy,
      targetX:  nextNode.coordinate.dx,
      targetY:  nextNode.coordinate.dy,
    );
    _speak(instruction);
  }

  // ── Compute arrow rotation from compass stream ─────────────
  double _computeArrowRotation(double compassHeading) {
    final nav      = context.read<NavigationProvider>();
    final pathIds  = widget.pathNodeIds;
    final curIdx   = _currentPathIndex;
    // Use correct graph based on mode
    final graph = widget.isCampusMode ? nav.campusGraph : nav.graph;

    if (pathIds.isEmpty || curIdx >= pathIds.length - 1) return 0;

    final currentNode = graph.nodes[pathIds[curIdx]];
    final nextNode    = graph.nodes[pathIds[curIdx + 1]];
    if (currentNode == null || nextNode == null) return 0;

    return DirectionalHelper.arrowRotation(
      currentX: currentNode.coordinate.dx,
      currentY: currentNode.coordinate.dy,
      targetX:  nextNode.coordinate.dx,
      targetY:  nextNode.coordinate.dy,
      compassHeadingDeg: compassHeading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Live Camera Feed ──────────────────────
          MobileScanner(
            controller: _scanCtrl,
            onDetect: _onDetect,
          ),

          // ── Layer 2: Dark vignette overlay ─────────────────
          _buildVignette(),

          // ── Layer 3: Top Status Bar ─────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildTopBar(),
          ),

          // ── Layer 4: Scan Frame (center) ────────────────────
          Center(child: _buildScanFrame()),

          // ── Layer 5: Directional Arrow (compass-driven) ─────
          Center(child: _buildDirectionalArrow()),

          // ── Layer 6: Bottom HUD ─────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomHud(),
          ),

          // ── Layer 7: Scan flash feedback ────────────────────
          if (_hasScanned)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _hasScanned ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(color: AppTheme.safetyYellow),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Layer Builders ────────────────────────────────────────

  Widget _buildVignette() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 12),

            // Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.isCampusMode ? '🎓 Campus AR Nav' : '🚉 Station AR Nav',
                  style: GoogleFonts.rajdhani(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _hudCurrentNode.isEmpty
                      ? 'Scan a QR code to begin'
                      : 'At: $_hudCurrentNode',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white60),
                ),
              ],
            ),
            const Spacer(),

            // Live indicator
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('LIVE',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Flash toggle
            GestureDetector(
              onTap: _scanCtrl.toggleTorch,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flashlight_on_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanFrame() {
    return SizedBox(
      width: 220, height: 220,
      child: Stack(
        children: [
          // Animated border
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppTheme.safetyYellow.withValues(alpha: 0.8),
                    width: 2.5),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Corner accents
          ..._buildCorners(),
          // Center crosshair
          Center(
            child: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 1.5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 5, height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    return [
      const Aligned(alignment: Alignment.topLeft,
          dx: 0, dy: 0, isTop: true, isLeft: true),
      const Aligned(alignment: Alignment.topRight,
          dx: 0, dy: 0, isTop: true, isLeft: false),
      const Aligned(alignment: Alignment.bottomLeft,
          dx: 0, dy: 0, isTop: false, isLeft: true),
      const Aligned(alignment: Alignment.bottomRight,
          dx: 0, dy: 0, isTop: false, isLeft: false),
    ].map((a) => a.build()).toList();
  }

  Widget _buildDirectionalArrow() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        final heading = snapshot.data?.heading ?? 0.0;
        final rotationDeg = _computeArrowRotation(heading);
        final rotationRad = rotationDeg * math.pi / 180.0;

        final bool atDestination =
            _currentPathIndex >= widget.pathNodeIds.length - 1;

        if (atDestination) {
          return const SizedBox.shrink();
        }

        return Transform.translate(
          offset: const Offset(0, -150), // above scan frame
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Direction label chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.safetyYellow.withValues(
                          alpha: 0.60),
                      width: 1.2),
                ),
                child: Text(
                  'HEAD $_hudDirection → $_hudNextNode',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.safetyYellow,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Rotating arrow
              Transform.rotate(
                angle: rotationRad,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow behind arrow
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.railwayBlue
                            .withValues(alpha: 0.35),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.safetyYellow
                                .withValues(alpha: 0.40),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    // Arrow icon
                    const Icon(
                      Icons.navigation_rounded,
                      color: AppTheme.safetyYellow,
                      size: 52,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomHud() {
    final nav      = context.watch<NavigationProvider>();
    final pathIds  = widget.pathNodeIds;
    final progress = pathIds.isEmpty
        ? 0.0
        : (_currentPathIndex / (pathIds.length - 1)).clamp(0.0, 1.0);
    final stepsLeft =
        (pathIds.length - 1 - _currentPathIndex).clamp(0, 99);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Progress bar ──────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.safetyYellow),
              minHeight: 4,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                // ── Top row: distance + direction ────────
                Row(
                  children: [
                    // Distance HUD tile
                    _HudTile(
                      icon: Icons.straighten_rounded,
                      label: 'DISTANCE',
                      value: _hudDistance,
                      color: AppTheme.safetyYellow,
                    ),
                    const SizedBox(width: 10),

                    // Direction HUD tile
                    _HudTile(
                      icon: Icons.explore_rounded,
                      label: 'DIRECTION',
                      value: _hudDirection,
                      color: AppTheme.railwayBlueLight,
                    ),
                    const SizedBox(width: 10),

                    // Steps remaining tile
                    _HudTile(
                      icon: Icons.pin_drop_rounded,
                      label: 'STOPS',
                      value: '$stepsLeft left',
                      color: AppTheme.success,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Next node row ────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_forward_rounded,
                          color: AppTheme.safetyYellow, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NEXT NODE',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white38,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              _hudNextNode,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Speak button
                      GestureDetector(
                        onTap: () => _speakCurrentInstruction(nav),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.railwayBlue
                                .withValues(alpha: 0.60),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.volume_up_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Path progress chips ──────────────────
                _buildPathChips(nav),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathChips(NavigationProvider nav) {
    final graph = Provider.of<NavigationProvider>(context, listen: false).graph;
    if (widget.pathNodeIds.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.pathNodeIds.asMap().entries.map((entry) {
          final i      = entry.key;
          final nodeId = entry.value;
          final node   = graph.nodes[nodeId];
          final isDone = i < _currentPathIndex;
          final isCurrent = i == _currentPathIndex;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppTheme.safetyYellow
                      : isDone
                          ? AppTheme.success.withValues(alpha: 0.30)
                          : Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCurrent
                        ? AppTheme.safetyYellow
                        : isDone
                            ? AppTheme.success.withValues(alpha: 0.50)
                            : Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: Text(
                  '${isDone ? '✓ ' : ''}${node?.displayName ?? nodeId}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isCurrent
                        ? AppTheme.railwayBlue
                        : Colors.white70,
                  ),
                ),
              ),
              if (i < widget.pathNodeIds.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.30),
                    size: 14,
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _speakCurrentInstruction(NavigationProvider nav) {
    final pathIds = widget.pathNodeIds;
    final graph   = widget.isCampusMode ? nav.campusGraph : nav.graph;
    if (_currentPathIndex >= pathIds.length - 1) {
      _speak('You have reached your destination.');
      return;
    }
    final cur  = graph.nodes[pathIds[_currentPathIndex]];
    final next = graph.nodes[pathIds[_currentPathIndex + 1]];
    if (cur == null || next == null) return;

    final instruction = DirectionalHelper.buildTtsInstruction(
      currentNodeName: cur.displayName,
      nextNodeName:    next.displayName,
      currentX: cur.coordinate.dx,  currentY: cur.coordinate.dy,
      targetX:  next.coordinate.dx, targetY:  next.coordinate.dy,
    );
    _speak(instruction);
  }
}

// ──────────────────────────────────────────────────────────
// HUD Tile Widget
// ──────────────────────────────────────────────────────────
class _HudTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HudTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white38,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Corner accent widget for scan frame
// ──────────────────────────────────────────────────────────
class Aligned {
  final Alignment alignment;
  final double dx, dy;
  final bool isTop, isLeft;

  const Aligned({
    required this.alignment,
    required this.dx, required this.dy,
    required this.isTop, required this.isLeft,
  });

  Widget build() {
    return Align(
      alignment: alignment,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(
                    color: AppTheme.safetyYellow, width: 3.5)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(
                    color: AppTheme.safetyYellow, width: 3.5)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(
                    color: AppTheme.safetyYellow, width: 3.5)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(
                    color: AppTheme.safetyYellow, width: 3.5)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}