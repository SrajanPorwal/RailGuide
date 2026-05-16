// ============================================================
// RailGuide — Support Screen
// screens/support_screen.dart
//
// Changes:
//  1. Fixed overflow in success banner — wrapped Text in Expanded
//  2. Integrated Firebase Auth + Firestore for persistent reports
//     and login state
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Firebase — uncomment after FlutterFire CLI setup
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReportIssueCard(lang: lang),
          const SizedBox(height: 20),
          _PastReportsCard(lang: lang),
          const SizedBox(height: 20),
          _EmergencyCard(lang: lang),
          const SizedBox(height: 20),
          _HowItWorksCard(lang: lang),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Report Issue Card
// ──────────────────────────────────────────────────────────
class _ReportIssueCard extends StatefulWidget {
  final LanguageProvider lang;
  const _ReportIssueCard({required this.lang});

  @override
  State<_ReportIssueCard> createState() => _ReportIssueCardState();
}

class _ReportIssueCardState extends State<_ReportIssueCard> {
  final _formKey   = GlobalKey<FormState>();
  final _issueCtrl = TextEditingController();
  String? _category;
  bool _submitted  = false;
  bool _isLoading  = false;

  final categories = [
    'Navigation Error',
    'Dirty Facility',
    'Safety Concern',
    'QR Code Damaged',
    'Missing Signage',
    'Other',
  ];

  @override
  void dispose() {
    _issueCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<RailAuthProvider>();

      // ── Save to Firestore ─────────────────────────────
      // Uncomment after FlutterFire CLI setup:
      //
      // await FirebaseFirestore.instance.collection('reports').add({
      //   'category':  _category,
      //   'issue':     _issueCtrl.text.trim(),
      //   'userId':    FirebaseAuth.instance.currentUser?.uid ?? 'guest',
      //   'userEmail': auth.userEmail ?? 'guest',
      //   'timestamp': FieldValue.serverTimestamp(),
      //   'status':    'open',
      // });

      // ── Mock save for demo (remove when Firebase is live) ──
      await Future.delayed(const Duration(milliseconds: 800));

      // Save locally via provider for demo persistence
      auth.addReport(
        category: _category!,
        issue: _issueCtrl.text.trim(),
      );

      setState(() {
        _submitted = true;
        _isLoading = false;
      });

      _issueCtrl.clear();
      _category = null;

      // Auto-hide success after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _submitted = false);
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

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
              const Text('🚨', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                // ← Expanded prevents header row overflow
                child: Text(
                  widget.lang.t('report_issue'),
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_submitted)
            // ── FIX: Expanded on Text prevents the 6.7px overflow ──
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.30)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.success, size: 20),
                  const SizedBox(width: 10),
                  // ← THIS IS THE FIX: Expanded lets text wrap
                  // instead of overflowing to the right
                  Expanded(
                    child: Text(
                      'Report submitted successfully! We\'ll look into it.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    hint: const Text('Select issue category'),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    isExpanded: true, // ← prevents dropdown overflow too
                    items: categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c,
                                style: GoogleFonts.inter(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v),
                    validator: (v) =>
                        v == null ? 'Please select a category' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _issueCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe the issue in detail...',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.edit_note_rounded),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Please describe the issue'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.railwayBlue))
                        : const Icon(Icons.send_rounded),
                    label: Text(
                        _isLoading ? 'Submitting...' : 'Submit Report'),
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
// Past Reports Card — shows reports saved this session
// (replaced by Firestore stream when Firebase is live)
// ──────────────────────────────────────────────────────────
class _PastReportsCard extends StatelessWidget {
  final LanguageProvider lang;
  const _PastReportsCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<RailAuthProvider>();
    final reports = auth.reports;

    if (reports.isEmpty) return const SizedBox.shrink();

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
              const Text('📋', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text('My Reports (${reports.length})',
                style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          ...reports.reversed.map((r) => _ReportTile(report: r)),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final Map<String, String> report;
  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.railwayBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              report['category'] ?? 'Other',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.railwayBlue,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['issue'] ?? '',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppTheme.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  report['time'] ?? '',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          const Icon(Icons.circle, color: AppTheme.warning, size: 8),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Emergency Contacts Card
// ──────────────────────────────────────────────────────────
class _Contact {
  final String icon, name, number;
  final Color color;
  _Contact(this.icon, this.name, this.number, this.color);
}

class _EmergencyCard extends StatelessWidget {
  final LanguageProvider lang;
  const _EmergencyCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    final contacts = [
      _Contact('🚔', 'Railway Police (RPF)', '1800-111-322', AppTheme.error),
      _Contact('🚑', 'Medical Emergency',    '108',          AppTheme.error),
      _Contact('🔧', 'Station Master', '+91-80-2220-0000',   AppTheme.railwayBlue),
      _Contact('ℹ️', 'Enquiry Helpline',     '139',          AppTheme.railwayBlueMid),
    ];

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
              const Text('📞', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(lang.t('emergency'),
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          ...contacts.map((c) => _ContactTile(contact: c)),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final _Contact contact;
  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: contact.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: contact.color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Text(contact.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
                Text(contact.number,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: contact.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Call',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// How It Works Card
// ──────────────────────────────────────────────────────────
class _HowItWorksCard extends StatelessWidget {
  final LanguageProvider lang;
  const _HowItWorksCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('📍', 'Find a QR code',
          'Locate a QR code placard near your current position.'),
      ('📷', 'Scan the QR',
          'Tap Scan QR Code and point your camera at the placard.'),
      ('🎯', 'Choose destination',
          'Select where you want to go from the dropdown list.'),
      ('🗺️', 'Follow the path',
          "RailGuide runs Dijkstra's algorithm and shows directions."),
    ];

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
              const Text('❓', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text('How It Works',
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.safetyYellow.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(step.$1,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.$2,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                        const SizedBox(height: 2),
                        Text(step.$3,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}