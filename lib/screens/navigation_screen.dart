// ============================================================
// RailGuide — Navigation Screen (Railway Mode)
// screens/navigation_screen.dart
//
// Changes from original:
//  1. Added import for ArScanScreen
//  2. Added "Launch AR Navigation" button inside _MapVisualization
//     — appears after the path summary text, before the 2D map
//  3. Added campus AR button note in _MapVisualization for railway mode
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../providers/navigation_provider.dart';
import '../providers/language_provider.dart';
import '../models/station_node.dart';
import '../utils/app_theme.dart';
import '../widgets/station_map_painter.dart';
import 'ar_scan_screen.dart'; // ← NEW: AR Navigation screen

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) => const _NavigationBody();
}

class _NavigationBody extends StatefulWidget {
  const _NavigationBody();
  @override
  State<_NavigationBody> createState() => _NavigationBodyState();
}

class _NavigationBodyState extends State<_NavigationBody> {
  @override
  Widget build(BuildContext context) {
    final nav  = context.watch<NavigationProvider>();
    final lang = context.watch<LanguageProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ScanCard(nav: nav, lang: lang),
          const SizedBox(height: 16),
          _DestinationCard(nav: nav, lang: lang),
          const SizedBox(height: 16),

          AnimatedOpacity(
            opacity: (nav.startNode != null && nav.endNode != null) ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton.icon(
              onPressed: (nav.startNode != null && nav.endNode != null)
                  ? nav.computePath
                  : null,
              icon: nav.isComputing
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppTheme.railwayBlue))
                  : const Icon(Icons.route_rounded),
              label: Text(
                  nav.isComputing ? 'Computing...' : lang.t('find_path')),
            ),
          ),
          const SizedBox(height: 24),

          if (nav.result != null) ...[
            if (nav.result!.found) ...[
              _MapVisualization(nav: nav),
              const SizedBox(height: 20),
              _StepInstructions(nav: nav, lang: lang),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: nav.reset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Start Over'),
              ),
            ] else
              _NoPathCard(),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Step 1: QR Scan Card ──────────────────────────────────
class _ScanCard extends StatelessWidget {
  final NavigationProvider nav;
  final LanguageProvider lang;
  const _ScanCard({required this.nav, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.railwayBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                    child: Text('1️⃣', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Location',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('Scan a QR code at your current spot',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (nav.startNode != null)
            _ScannedNodeBadge(node: nav.startNode!)
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_outlined,
                      color: AppTheme.textLight, size: 20),
                  const SizedBox(width: 10),
                  Text(lang.t('not_scanned'),
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.textLight)),
                ],
              ),
            ),

          const SizedBox(height: 14),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const _QrScannerScreen()),
                );
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
              label: Text(lang.t('scan_qr')),
            ),
          ),

          const SizedBox(height: 12),
          Text('Or tap a location to simulate scan:',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppTheme.textLight)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: context
                .watch<NavigationProvider>()
                .allNodes
                .take(4)
                .map((node) => GestureDetector(
                      onTap: () => nav.onQrScanned(node.qrCode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: nav.startNode?.id == node.id
                              ? AppTheme.railwayBlue
                              : AppTheme.scaffoldBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: nav.startNode?.id == node.id
                                ? AppTheme.railwayBlue
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          '${node.icon} ${node.displayName}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: nav.startNode?.id == node.id
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Real QR Scanner Screen ────────────────────────────────
class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen();

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    final value   = barcode?.rawValue;
    if (value == null || value.isEmpty) return;

    _hasScanned = true;
    context.read<NavigationProvider>().onQrScanned(value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📍 Scanned: $value'),
        backgroundColor: AppTheme.railwayBlue,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Station QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on_rounded),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Flip Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppTheme.safetyYellow, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Stack(
                children: [
                  _Corner(Alignment.topLeft),
                  _Corner(Alignment.topRight),
                  _Corner(Alignment.bottomLeft),
                  _Corner(Alignment.bottomRight),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0, right: 0,
            child: Column(
              children: [
                const Icon(Icons.qr_code_2_rounded,
                    color: Colors.white54, size: 36),
                const SizedBox(height: 12),
                Text(
                  'Point camera at a RailGuide QR code',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  'The app will detect it automatically',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Corner Decoration Widget ──────────────────────────────
class _Corner extends StatelessWidget {
  final Alignment alignment;
  const _Corner(this.alignment);

  @override
  Widget build(BuildContext context) {
    final isTop  = alignment == Alignment.topLeft ||
                   alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft ||
                   alignment == Alignment.bottomLeft;

    return Align(
      alignment: alignment,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          border: Border(
            top:    isTop  ? const BorderSide(color: AppTheme.safetyYellow, width: 4) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppTheme.safetyYellow, width: 4) : BorderSide.none,
            left:   isLeft  ? const BorderSide(color: AppTheme.safetyYellow, width: 4) : BorderSide.none,
            right:  !isLeft ? const BorderSide(color: AppTheme.safetyYellow, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ── Scanned Node Badge ────────────────────────────────────
class _ScannedNodeBadge extends StatelessWidget {
  final StationNode node;
  const _ScannedNodeBadge({required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.railwayBlue, AppTheme.railwayBlueLight],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(node.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(node.displayName,
                style: GoogleFonts.rajdhani(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Colors.white)),
              Text('QR: ${node.qrCode}',
                style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.white60)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.safetyYellow, size: 20),
        ],
      ),
    );
  }
}

// ── Step 2: Destination Card ──────────────────────────────
class _DestinationCard extends StatelessWidget {
  final NavigationProvider nav;
  final LanguageProvider lang;
  const _DestinationCard({required this.nav, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.safetyYellow.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                    child: Text('2️⃣', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Destination',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('Where do you want to go?',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: nav.endNode?.id,
            hint: Text(lang.t('select_destination')),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.flag_rounded),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
            ),
            isExpanded: true,
            items: nav.allNodes
                .where((n) => n.id != nav.startNode?.id)
                .map((node) => DropdownMenuItem(
                      value: node.id,
                      child: Row(
                        children: [
                          Text(node.icon,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(node.displayName,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (id) {
              if (id != null) nav.setDestination(id);
            },
          ),
        ],
      ),
    );
  }
}

// ── 2D Map Visualization ──────────────────────────────────
class _MapVisualization extends StatelessWidget {
  final NavigationProvider nav;
  const _MapVisualization({required this.nav});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: title + hops badge ───────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.map_rounded,
                    color: AppTheme.railwayBlue, size: 20),
                const SizedBox(width: 8),
                Text('Station Map',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.safetyYellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${nav.result!.path.length - 1} hops',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.railwayBlue),
                  ),
                ),
              ],
            ),
          ),

          // ── Path summary text ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            child: Text(
              nav.result!.path
                  .map((id) => nav.graph.nodes[id]?.displayName ?? id)
                  .join(' → '),
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.railwayBlue),
            ),
          ),

          // ── ★ NEW: AR Navigation Launch Button ────────
          // Placed between path summary and 2D map so it's
          // immediately visible after a path is found.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.railwayBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () {
                // Pass the computed Dijkstra path to ArScanScreen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ArScanScreen(
                      pathNodeIds: nav.result!.path,
                      // ← uses the railway graph (default)
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.view_in_ar_rounded, size: 22),
              label: Text(
                '🧭  Launch AR Navigation',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // ── 2D map canvas ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: StationMapPainter(
                  graph: nav.graph,
                  highlightedPath: nav.result!.path,
                ),
              ),
            ),
          ),

          // ── Distance footer ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                const Icon(Icons.straighten_rounded,
                    size: 16, color: AppTheme.textLight),
                const SizedBox(width: 6),
                Text(
                  'Total distance: ${nav.result!.totalDistance.toStringAsFixed(2)} units',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step-by-Step Instructions ─────────────────────────────
class _StepInstructions extends StatelessWidget {
  final NavigationProvider nav;
  final LanguageProvider lang;
  const _StepInstructions({required this.nav, required this.lang});

  @override
  Widget build(BuildContext context) {
    final steps = nav.result!.instructions;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_list_numbered_rounded,
                  color: AppTheme.railwayBlue, size: 20),
              const SizedBox(width: 8),
              Text(lang.t('step_instructions'),
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) => _StepTile(
                step: entry.value,
                index: entry.key,
                isFirst: entry.key == 0,
                isLast: entry.key == steps.length - 1,
              )),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String step;
  final int index;
  final bool isFirst;
  final bool isLast;
  const _StepTile({
    required this.step,
    required this.index,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: isLast
                        ? AppTheme.success
                        : isFirst
                            ? AppTheme.safetyYellow
                            : AppTheme.railwayBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      isFirst ? '📍' : isLast ? '✅' : '$index',
                      style: TextStyle(
                        fontSize: isFirst || isLast ? 12 : 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade200,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Text(
                step,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isFirst || isLast
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isFirst || isLast
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── No Path Card ──────────────────────────────────────────
class _NoPathCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.30)),
      ),
      child: Column(
        children: [
          const Text('❌', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text('No Path Found',
            style: GoogleFonts.rajdhani(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.error)),
          const SizedBox(height: 6),
          Text(
            'There is no route between the selected locations.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}