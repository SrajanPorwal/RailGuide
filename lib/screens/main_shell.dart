// ============================================================
// RailGuide — Main Shell (Updated)
// screens/main_shell.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/language_provider.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'navigation_screen.dart';
import 'support_screen.dart';
import 'navigation/campus_navigation_screen.dart'; // ← NEW

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    NavigationScreen(),
    SupportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.railwayBlue,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.safetyYellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                  child: Text('🚉', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 10),
            Text('RailGuide',
              style: GoogleFonts.rajdhani(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: Colors.white)),
          ],
        ),
        actions: [
          // ── Campus Nav shortcut button ──────────────
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1B6B3A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CampusNavigationScreen(),
                ),
              ),
              icon: const Text('🎓',
                  style: TextStyle(fontSize: 14)),
              label: Text('Campus',
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
          _LanguageSwitcher(lang: lang),
          const SizedBox(width: 8),
        ],
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          elevation: 0,
          backgroundColor: Colors.transparent,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: lang.t('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.train_rounded),
              activeIcon: const Icon(Icons.train_rounded),
              label: lang.t('navigate'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.support_agent_outlined),
              activeIcon: const Icon(Icons.support_agent),
              label: lang.t('support'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Language Switcher ─────────────────────────────────────
class _LanguageSwitcher extends StatelessWidget {
  final LanguageProvider lang;
  const _LanguageSwitcher({required this.lang});

  static const Map<String, String> _shortLabels = {
    'en': 'EN',
    'hi': 'HI',
    'kn': 'KN',
  };

  @override
  Widget build(BuildContext context) {
    final shortLabel =
        _shortLabels[lang.currentLocale.languageCode] ?? 'EN';

    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.safetyYellow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 16,
                color: AppTheme.railwayBlue),
            const SizedBox(width: 4),
            Text(shortLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.railwayBlue,
              ),
            ),
          ],
        ),
      ),
      onSelected: lang.setLanguage,
      itemBuilder: (_) => LanguageProvider.supportedLocales
          .map((locale) => PopupMenuItem<String>(
                value: locale.languageCode,
                child: Row(
                  children: [
                    if (lang.currentLocale.languageCode ==
                        locale.languageCode)
                      const Icon(Icons.check,
                          size: 16, color: AppTheme.railwayBlue)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(
                      LanguageProvider.languageLabels[
                              locale.languageCode] ??
                          '',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}