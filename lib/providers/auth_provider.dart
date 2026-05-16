// ============================================================
// RailGuide — Auth Provider (Updated)
// providers/auth_provider.dart
//
// Changes:
//  1. Added reports list — stores submitted issues in memory
//     and persists them to Firestore when Firebase is live
//  2. Added addReport() method called by SupportScreen
//  3. Persistent login — Firebase Auth remembers the user
//     across app restarts automatically once enabled
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase — uncomment after FlutterFire CLI setup
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, guest }

class RailAuthProvider extends ChangeNotifier {
  AuthStatus _status   = AuthStatus.initial;
  String?    _userEmail;
  String?    _error;

  // ── Reports list — persists across the session ────────
  // When Firebase is live, load from Firestore instead
  final List<Map<String, String>> _reports = [];

  AuthStatus               get status    => _status;
  String?                  get userEmail => _userEmail;
  String?                  get error     => _error;
  List<Map<String, String>> get reports  => List.unmodifiable(_reports);

  bool get isAuthenticated =>
      _status == AuthStatus.authenticated ||
      _status == AuthStatus.guest;
  bool get isGuest => _status == AuthStatus.guest;

  // ── Constructor: check saved login on startup ─────────
  RailAuthProvider() {
    _restoreSession();
  }

  // ── Restore session from SharedPreferences ────────────
  // This keeps the user logged in across app restarts
  // even before Firebase is enabled.
  // When Firebase Auth is live, FirebaseAuth.instance.authStateChanges()
  // handles this automatically — remove _restoreSession() then.
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('user_email');
      final savedGuest = prefs.getBool('is_guest') ?? false;

      if (savedGuest) {
        _status    = AuthStatus.guest;
        _userEmail = 'Guest';
      } else if (savedEmail != null) {
        _status    = AuthStatus.authenticated;
        _userEmail = savedEmail;
        // Also reload their reports from prefs
        _loadReportsFromPrefs(prefs);
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  void _loadReportsFromPrefs(SharedPreferences prefs) {
    // Reports stored as: "report_0_category", "report_0_issue", etc.
    int i = 0;
    while (prefs.containsKey('report_${i}_category')) {
      _reports.add({
        'category': prefs.getString('report_${i}_category') ?? '',
        'issue':    prefs.getString('report_${i}_issue')    ?? '',
        'time':     prefs.getString('report_${i}_time')     ?? '',
      });
      i++;
    }
  }

  Future<void> _saveReportsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _reports.length; i++) {
      await prefs.setString('report_${i}_category', _reports[i]['category'] ?? '');
      await prefs.setString('report_${i}_issue',    _reports[i]['issue']    ?? '');
      await prefs.setString('report_${i}_time',     _reports[i]['time']     ?? '');
    }
  }

  // ── Sign In ───────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _error  = null;
    notifyListeners();

    try {
      // ── Firebase Auth (uncomment after setup) ──────────
      // final credential = await FirebaseAuth.instance
      //     .signInWithEmailAndPassword(email: email, password: password);
      // _userEmail = credential.user?.email;
      // // Load reports from Firestore
      // final snap = await FirebaseFirestore.instance
      //     .collection('reports')
      //     .where('userEmail', isEqualTo: email)
      //     .orderBy('timestamp', descending: true)
      //     .get();
      // _reports.clear();
      // for (final doc in snap.docs) {
      //   _reports.add({
      //     'category': doc['category'] ?? '',
      //     'issue':    doc['issue']    ?? '',
      //     'time':     doc['timestamp']?.toDate().toString() ?? '',
      //   });
      // }

      // ── Mock (remove when Firebase is live) ───────────
      await Future.delayed(const Duration(seconds: 1));
      _userEmail = email;
      _status    = AuthStatus.authenticated;

      // Save login to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setBool('is_guest', false);
      // Load any previously saved reports for this device
      _reports.clear();
      _loadReportsFromPrefs(prefs);

      notifyListeners();
      return true;
    } catch (e) {
      _error  = _friendlyError(e.toString());
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── Sign Up ───────────────────────────────────────────
  Future<bool> signUp(String email, String password) async {
    _status = AuthStatus.loading;
    _error  = null;
    notifyListeners();

    try {
      // ── Firebase Auth (uncomment after setup) ──────────
      // final credential = await FirebaseAuth.instance
      //     .createUserWithEmailAndPassword(email: email, password: password);
      // _userEmail = credential.user?.email;

      // ── Mock (remove when Firebase is live) ───────────
      await Future.delayed(const Duration(seconds: 1));
      _userEmail = email;
      _status    = AuthStatus.authenticated;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setBool('is_guest', false);

      notifyListeners();
      return true;
    } catch (e) {
      _error  = _friendlyError(e.toString());
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── Guest Mode ────────────────────────────────────────
  Future<void> continueAsGuest() async {
    _status    = AuthStatus.guest;
    _userEmail = 'Guest';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', true);
    await prefs.remove('user_email');

    notifyListeners();
  }

  // ── Sign Out ──────────────────────────────────────────
  Future<void> signOut() async {
    // await FirebaseAuth.instance.signOut();
    _status    = AuthStatus.unauthenticated;
    _userEmail = null;
    _reports.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('is_guest');
    // Clear saved reports on logout
    int i = 0;
    while (prefs.containsKey('report_${i}_category')) {
      await prefs.remove('report_${i}_category');
      await prefs.remove('report_${i}_issue');
      await prefs.remove('report_${i}_time');
      i++;
    }

    notifyListeners();
  }

  // ── Add Report ────────────────────────────────────────
  // Called by SupportScreen after form submission.
  // Saves to memory + SharedPreferences immediately.
  // When Firebase is live, Firestore handles persistence instead.
  void addReport({
    required String category,
    required String issue,
  }) {
    final now = DateTime.now();
    final timeStr =
        '${now.day}/${now.month}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    _reports.add({
      'category': category,
      'issue':    issue,
      'time':     timeStr,
    });

    // Persist to device storage
    _saveReportsToPrefs();

    notifyListeners();
  }

  // ── Friendly error messages ───────────────────────────
  String _friendlyError(String raw) {
    if (raw.contains('user-not-found'))    return 'No account found for this email.';
    if (raw.contains('wrong-password'))    return 'Incorrect password. Please try again.';
    if (raw.contains('email-already'))     return 'An account with this email already exists.';
    if (raw.contains('weak-password'))     return 'Password is too weak. Use at least 6 characters.';
    if (raw.contains('network-request'))   return 'No internet connection.';
    return 'Something went wrong. Please try again.';
  }
}