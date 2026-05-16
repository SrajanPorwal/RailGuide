// ============================================================
// RailGuide — Auth Provider
// providers/auth_provider.dart
// ============================================================

import 'package:flutter/material.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, guest }

/// Manages Firebase Authentication state.
/// Firebase calls are commented out — uncomment after setup.
class RailAuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  String? _userEmail;
  String? _error;

  AuthStatus get status => _status;
  String? get userEmail => _userEmail;
  String? get error => _error;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated || _status == AuthStatus.guest;
  bool get isGuest => _status == AuthStatus.guest;

  // ── Sign In ───────────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      // Firebase Auth (uncomment after setup):
      // final credential = await FirebaseAuth.instance
      //     .signInWithEmailAndPassword(email: email, password: password);
      // _userEmail = credential.user?.email;

      // ── Mock delay for demo ──
      await Future.delayed(const Duration(seconds: 1));
      _userEmail = email;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── Sign Up ───────────────────────────────────────────────
  Future<bool> signUp(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      // Firebase Auth (uncomment after setup):
      // final credential = await FirebaseAuth.instance
      //     .createUserWithEmailAndPassword(email: email, password: password);
      // _userEmail = credential.user?.email;

      await Future.delayed(const Duration(seconds: 1));
      _userEmail = email;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── Guest Mode ────────────────────────────────────────────
  void continueAsGuest() {
    _status = AuthStatus.guest;
    _userEmail = 'Guest';
    notifyListeners();
  }

  // ── Sign Out ──────────────────────────────────────────────
  Future<void> signOut() async {
    // await FirebaseAuth.instance.signOut();
    _status = AuthStatus.unauthenticated;
    _userEmail = null;
    notifyListeners();
  }
}