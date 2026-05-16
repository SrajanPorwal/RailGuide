// ============================================================
// RailGuide — Home / Dashboard Screen
// screens/home_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/train_info.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang   = context.watch<LanguageProvider>();
    final auth   = context.watch<RailAuthProvider>();
    final trains = TrainInfo.mockTrains();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeBanner(auth: auth),
          const SizedBox(height: 24),
          _QuickAccessGrid(lang: lang),
          const SizedBox(height: 28),

          // ── Train Info section header ─────────────────────
          Row(
            children: [
              const Icon(Icons.train_rounded,
                  color: AppTheme.railwayBlue, size: 22),
              const SizedBox(width: 8),
              Text(lang.t('train_info'),
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('Live',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...trains.map((t) => _TrainCard(info: t, lang: lang)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Welcome Banner
// ──────────────────────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  final RailAuthProvider auth;
  const _WelcomeBanner({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.railwayBlue, AppTheme.railwayBlueLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.railwayBlue.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back!',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  auth.isGuest
                      ? 'Guest Passenger'
                      : auth.userEmail?.split('@').first ?? 'Passenger',
                  style: GoogleFonts.rajdhani(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.safetyYellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('📍 Bengaluru City Station',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.railwayBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Text('🚂', style: TextStyle(fontSize: 52)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Quick Access Grid
// ──────────────────────────────────────────────────────────
class _QuickItem {
  final String emoji;
  final String label;
  final Color color;
  _QuickItem(this.emoji, this.label, this.color);
}

class _QuickAccessGrid extends StatelessWidget {
  final LanguageProvider lang;
  const _QuickAccessGrid({required this.lang});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickItem('🚻', 'Washrooms', AppTheme.railwayBlueLight),
      _QuickItem('🎫', 'Tickets',   AppTheme.railwayBlueMid),
      _QuickItem('🅿️', 'Parking',  AppTheme.railwayBlue),
      _QuickItem('🔒', 'Security',  const Color(0xFF374151)),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: items.map((item) => _QuickAccessTile(item: item)).toList(),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final _QuickItem item;
  const _QuickAccessTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(item.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 6),
            Text(item.label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Train Information Card
// ──────────────────────────────────────────────────────────
class _TrainCard extends StatelessWidget {
  final TrainInfo info;
  final LanguageProvider lang;
  const _TrainCard({required this.info, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppTheme.railwayBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🚉', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),

          // Train name + number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.trainName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text('# ${info.trainNumber}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textLight)),
              ],
            ),
          ),

          // Platform + time + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.safetyYellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${lang.t('platform')} ${info.platformNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.railwayBlue,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time,
                      size: 12, color: AppTheme.textLight),
                  const SizedBox(width: 4),
                  Text(info.arrivalTime,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                info.status +
                    (info.delayMinutes > 0
                        ? ' (+${info.delayMinutes}m)'
                        : ''),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: info.statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}