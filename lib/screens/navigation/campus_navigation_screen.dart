// ============================================================
// RailGuide — Campus Navigation Screen
// screens/navigation/campus_navigation_screen.dart
//
// RNSIT Campus indoor navigation with:
//  • Dijkstra pathfinding on campus graph
//  • QR code scanning for start node
//  • flutter_tts voice directions
//  • Arrow-based visual path display
//  • College Green accent theme
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../providers/navigation_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_theme.dart';
import '../ar_scan_screen.dart'; // ← AR Navigation (compass + TTS + HUD)

// ── Campus accent color ───────────────────────────────────
const Color collegeGreen      = Color(0xFF1B6B3A);
const Color collegeGreenLight = Color(0xFF2E9E58);
const Color collegeGreenSoft  = Color(0xFFE8F5EE);

class CampusNavigationScreen extends StatefulWidget {
  const CampusNavigationScreen({super.key});

  @override
  State<CampusNavigationScreen> createState() =>
      _CampusNavigationScreenState();
}

class _CampusNavigationScreenState extends State<CampusNavigationScreen>
    with SingleTickerProviderStateMixin {
  // ── TTS ────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  // ── Tab animation ──────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _setupTts();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();

    // Switch provider to campus mode when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationProvider>().setMode(AppNavigationMode.campus);
    });
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _speakPath(List<String> instructions) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSpeaking = true);
    final fullText = instructions.join('. ');
    await _tts.speak(fullText);
  }

  Future<void> _announcePathFound(String start, String next) async {
    await _tts.speak(
        'Path found. Proceed from $start toward $next.');
  }

  @override
  void dispose() {
    _tts.stop();
    _animCtrl.dispose();
    // Switch back to railway mode when leaving
    context.read<NavigationProvider>().setMode(AppNavigationMode.railway);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav  = context.watch<NavigationProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      // ── AppBar ────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: collegeGreen,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AppTheme.safetyYellow,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                  child: Text('🎓', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Text('Campus Navigation',
              style: GoogleFonts.rajdhani(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Reset button
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset',
            onPressed: () {
              nav.reset();
              _tts.stop();
              setState(() => _isSpeaking = false);
            },
          ),
        ],
      ),

      backgroundColor: const Color(0xFFF0F7F3), // soft green-tinted bg

      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Campus info banner ─────────────────────
              _CampusBanner(),
              const SizedBox(height: 16),

              // ── Step 1: Scan / Select Start ────────────
              _StartNodeCard(nav: nav, lang: lang),
              const SizedBox(height: 14),

              // ── Step 2: Select Destination ─────────────
              _DestinationCard(nav: nav, lang: lang),
              const SizedBox(height: 16),

              // ── Find Path Button ───────────────────────
              AnimatedOpacity(
                opacity: (nav.campusStartNode != null &&
                        nav.campusEndNode != null)
                    ? 1.0
                    : 0.45,
                duration: const Duration(milliseconds: 300),
                // ignore: prefer_const_constructors
                child: _GreenButton(
                  label: nav.isComputing
                      ? 'Calculating...'
                      : '🗺️  Find Campus Path',
                  isLoading: nav.isComputing,
                  onPressed: (nav.campusStartNode != null &&
                          nav.campusEndNode != null)
                      ? () async {
                          await nav.computeCampusPath();
                          // Announce result via TTS
                          if (nav.campusResult != null &&
                              nav.campusResult!.found &&
                              nav.campusResult!.path.length >= 2) {
                            final start = nav.graph
                                    .nodes[nav.campusResult!.path[0]]
                                    ?.displayName ??
                                '';
                            final next = nav.graph
                                    .nodes[nav.campusResult!.path[1]]
                                    ?.displayName ??
                                '';
                            await _announcePathFound(start, next);
                          }
                        }
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // ── Result ────────────────────────────────
              if (nav.campusResult != null) ...[
                if (nav.campusResult!.found) ...[
                  // Visual arrow path
                  _ArrowPathCard(nav: nav),
                  const SizedBox(height: 16),

                  // ── ★ AR Navigation Launch Button ──────
                  // Launches the compass-driven AR overlay
                  // with the computed campus Dijkstra path.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: collegeGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ArScanScreen(
                              pathNodeIds: nav.campusResult!.path,
                              isCampusMode: true, // ← use campus graph
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.view_in_ar_rounded, size: 22),
                      label: Text(
                        '🧭  Launch Campus AR Navigation',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Step-by-step instructions + TTS
                  _StepByStepCard(
                    nav: nav,
                    isSpeaking: _isSpeaking,
                    onSpeak: () =>
                        _speakPath(nav.campusResult!.instructions),
                  ),
                ] else
                  _NoPathCard(),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Campus Info Banner
// ──────────────────────────────────────────────────────────
class _CampusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [collegeGreen, collegeGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: collegeGreen.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RNSIT Campus',
                  style: GoogleFonts.rajdhani(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'R.N.S. Institute of Technology\nBengaluru, Karnataka',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.safetyYellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('📍 6 Campus Nodes',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: collegeGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Text('🏫', style: TextStyle(fontSize: 52)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Step 1 — Start Node Card (QR + manual chips)
// ──────────────────────────────────────────────────────────
class _StartNodeCard extends StatelessWidget {
  final NavigationProvider nav;
  final LanguageProvider lang;
  const _StartNodeCard({required this.nav, required this.lang});

  @override
  Widget build(BuildContext context) {
    return _GreenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const _StepBadge(label: '1', color: collegeGreen),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Location',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                  Text('Scan QR or tap a node below',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textLight)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Scanned node display
          if (nav.campusStartNode != null)
            _ScannedBadge(
              icon: nav.campusStartNode!.icon,
              name: lang.t(nav.campusStartNode!.id), // ✅ Localizes your current matching station tag
              qr: nav.campusStartNode!.qrCode,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 11, horizontal: 14),
              decoration: BoxDecoration(
                color: collegeGreenSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: collegeGreen.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_off_outlined,
                      color: collegeGreen.withValues(alpha: 0.50),
                      size: 18),
                  const SizedBox(width: 8),
                  Text('Not scanned yet',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: collegeGreen.withValues(alpha: 0.60))),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // QR Scan button
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: collegeGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const _CampusQrScannerScreen()),
              ),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: Text('Scan Campus QR',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),

          const SizedBox(height: 12),

          // Manual node chips
          Text('Or tap to select your location:',
            style: GoogleFonts.inter(
                fontSize: 11, color: AppTheme.textLight)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: nav.campusNodes.map((node) {
              final isSelected = nav.campusStartNode?.id == node.id;
              return GestureDetector(
                onTap: () => nav.setCampusStart(node.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? collegeGreen : collegeGreenSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? collegeGreen
                          : collegeGreen.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '${node.icon} ${lang.t(node.id)}', // ✅ Translates campus selector button tags live
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : collegeGreen,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Step 2 — Destination Dropdown
// ──────────────────────────────────────────────────────────
class _DestinationCard extends StatelessWidget {
  final NavigationProvider nav;
  final LanguageProvider lang;
  const _DestinationCard({required this.nav, required this.lang});

  @override
  Widget build(BuildContext context) {
    return _GreenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _StepBadge(label: '2', color: AppTheme.safetyYellow),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Destination',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                  Text('Where do you want to go?',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textLight)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: nav.campusEndNode?.id,
            hint: Text('Select campus destination',
              style: GoogleFonts.inter(fontSize: 13)),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.flag_rounded, color: collegeGreen),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder( // ignore: prefer_const_constructors
              
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: collegeGreen.withValues(alpha: 0.30)),
              ),
              focusedBorder: OutlineInputBorder( // ignore: prefer_const_constructors
              
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: collegeGreen, width: 2),
              ),
              enabledBorder: OutlineInputBorder( // ignore: prefer_const_constructors
              
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: collegeGreen.withValues(alpha: 0.25)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
            isExpanded: true,
            items: nav.campusNodes
                .where((n) => n.id != nav.campusStartNode?.id)
                .map((node) => DropdownMenuItem(
                      value: node.id,
                      child: Row(
                        children: [
                          Text(node.icon,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(lang.t(node.id), // ✅ Localizes the dropdown choices
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (id) {
              if (id != null) nav.setCampusEnd(id);
            },
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Arrow Path Card — Visual path with arrow icons
// ──────────────────────────────────────────────────────────
class _ArrowPathCard extends StatelessWidget {
  final NavigationProvider nav;
  const _ArrowPathCard({required this.nav});

  @override
  Widget build(BuildContext context) {
    final path = nav.campusResult!.path;

    return _GreenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.route_rounded,
                  color: collegeGreen, size: 20),
              const SizedBox(width: 8),
              Text('Shortest Path',
                style: GoogleFonts.rajdhani(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: collegeGreen)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.safetyYellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${path.length - 1} stop${path.length - 1 == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: collegeGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Arrow path visual — wraps into rows
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 12,
            children: _buildArrowWidgets(path, nav, context),
          ),

          const SizedBox(height: 14),

          // Distance info
          Row(
            children: [
              const Icon(Icons.straighten_rounded,
                  size: 14, color: AppTheme.textLight),
              const SizedBox(width: 6),
              Text(
                'Total distance: ${nav.campusResult!.totalDistance.toStringAsFixed(1)} m',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildArrowWidgets(
      List<String> path, NavigationProvider nav, BuildContext context) {
    final widgets = <Widget>[];

    for (int i = 0; i < path.length; i++) {
      final node = nav.campusGraph.nodes[path[i]];
      final isStart = i == 0;
      final isEnd   = i == path.length - 1;

      // Node chip
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isStart
                ? AppTheme.safetyYellow
                : isEnd
                    ? collegeGreen
                    : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isStart
                  ? AppTheme.railwayBlue
                  : isEnd
                      ? collegeGreenLight
                      : collegeGreen.withValues(alpha: 0.30),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(node?.icon ?? '📍',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                node != null ? Provider.of<LanguageProvider>(context, listen: false).t(node.id) : path[i], // ✅ Updates route badges
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isStart
                      ? AppTheme.railwayBlue
                      : isEnd
                          ? Colors.white
                          : collegeGreen,
                ),
              ),
            ],
          ),
        ),
      );

      // Arrow between nodes
      if (i < path.length - 1) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: collegeGreenLight,
              size: 20,
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

// ──────────────────────────────────────────────────────────
// Step-by-Step + TTS Card
// ──────────────────────────────────────────────────────────
class _StepByStepCard extends StatelessWidget {
  final NavigationProvider nav;
  final bool isSpeaking;
  final VoidCallback onSpeak;
  const _StepByStepCard({
    required this.nav,
    required this.isSpeaking,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final steps = nav.campusResult!.instructions;

    return _GreenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + TTS button
          Row(
            children: [
              const Icon(Icons.format_list_numbered_rounded,
                  color: collegeGreen, size: 20),
              const SizedBox(width: 8),
              Text('Step-by-Step',
                style: GoogleFonts.rajdhani(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: collegeGreen)),
              const Spacer(),

              // ── Speak Directions Button ───────────────
              GestureDetector(
                onTap: onSpeak,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSpeaking
                        ? AppTheme.error
                        : collegeGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSpeaking
                            ? Icons.stop_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isSpeaking ? 'Stop' : 'Speak',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Steps list
          ...steps.asMap().entries.map((entry) {
            final i       = entry.key;
            final step    = entry.value;
            final isFirst = i == 0;
            final isLast  = i == steps.length - 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Timeline
                    SizedBox(
                      width: 32,
                      child: Column(
                        children: [
                          Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: isLast
                                  ? collegeGreen
                                  : isFirst
                                      ? AppTheme.safetyYellow
                                      : collegeGreenLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                isFirst
                                    ? '📍'
                                    : isLast
                                        ? '✅'
                                        : '$i',
                                style: TextStyle(
                                  fontSize:
                                      isFirst || isLast ? 12 : 10,
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
                                color: collegeGreen
                                    .withValues(alpha: 0.20),
                                margin: const EdgeInsets.symmetric(
                                    vertical: 2),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Step text
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: isLast ? 0 : 14),
                        child: Text(
                          step,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isFirst || isLast
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isFirst || isLast
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Campus QR Scanner Screen
// ──────────────────────────────────────────────────────────
class _CampusQrScannerScreen extends StatefulWidget {
  const _CampusQrScannerScreen();

  @override
  State<_CampusQrScannerScreen> createState() =>
      _CampusQrScannerScreenState();
}

class _CampusQrScannerScreenState
    extends State<_CampusQrScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _hasScanned = false;

  // QR payload → campus node ID mapping
  static const Map<String, String> _qrMap = {
    'RNSIT_GATE':       'main_gate',
    'RNSIT_MECH':       'mechanical_block',
    'RNSIT_MBA':        'mba_block',
    'RNSIT_FOOD1':      'food_court_1',
    'RNSIT_FOOD2':      'food_court_2',
    'RNSIT_TEMPLE':     'temple_parking',
    // Also accept raw node IDs directly
    'main_gate':        'main_gate',
    'mechanical_block': 'mechanical_block',
    'mba_block':        'mba_block',
    'food_court_1':     'food_court_1',
    'food_court_2':     'food_court_2',
    'temple_parking':   'temple_parking',
  };

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final value = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (value == null || value.isEmpty) return;

    final nodeId = _qrMap[value];

    _hasScanned = true;

    if (nodeId != null) {
      context.read<NavigationProvider>().setCampusStart(nodeId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Location set: $value'),
        backgroundColor: collegeGreen,
        duration: const Duration(seconds: 2),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ Unknown QR: $value'),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 2),
      ));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: collegeGreen,
        foregroundColor: Colors.white,
        title: const Text('Scan Campus QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on_rounded),
            onPressed: _ctrl.toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: _ctrl.switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _ctrl, onDetect: _onDetect),

          // Scan frame
          Center(
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppTheme.safetyYellow, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 60, left: 20, right: 20,
            child: Column(
              children: [
                const Icon(Icons.qr_code_2_rounded,
                    color: Colors.white54, size: 36),
                const SizedBox(height: 10),
                Text('Point at a RNSIT Campus QR code',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: collegeGreen.withValues(alpha: 0.80),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Supported: RNSIT_GATE, RNSIT_MECH,\nRNSIT_MBA, RNSIT_FOOD1, RNSIT_FOOD2, RNSIT_TEMPLE',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Reusable Widgets
// ──────────────────────────────────────────────────────────

class _GreenCard extends StatelessWidget {
  final Widget child;
  const _GreenCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: collegeGreen.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StepBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StepBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Center(
        child: Text(label,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color)),
      ),
    );
  }
}

class _ScannedBadge extends StatelessWidget {
  final String icon, name, qr;
  const _ScannedBadge(
      {required this.icon, required this.name, required this.qr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [collegeGreen, collegeGreenLight]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
              Text('QR: $qr',
                style: GoogleFonts.inter(
                    fontSize: 10, color: Colors.white60)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.safetyYellow, size: 18),
        ],
      ),
    );
  }
}

class _GreenButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  const _GreenButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.safetyYellow,
          foregroundColor: collegeGreen,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: collegeGreen))
            : Text(label,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _NoPathCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Text('❌', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 8),
          Text('No Path Found',
            style: GoogleFonts.rajdhani(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.error)),
          const SizedBox(height: 6),
          Text('No route between selected campus locations.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}