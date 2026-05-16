// ============================================================
// RailGuide — Authentication Screen
// screens/auth_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_theme.dart';
import 'main_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _loginFormKey  = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  final _loginEmailCtrl    = TextEditingController();
  final _loginPassCtrl     = TextEditingController();
  final _signupEmailCtrl   = TextEditingController();
  final _signupPassCtrl    = TextEditingController();
  final _signupConfirmCtrl = TextEditingController();

  bool _loginObscure  = true;
  bool _signupObscure = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPassCtrl.dispose();
    _signupConfirmCtrl.dispose();
    super.dispose();
  }

  void _navigate() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final auth = context.read<RailAuthProvider>();
    final ok = await auth.signIn(_loginEmailCtrl.text, _loginPassCtrl.text);
    if (ok && mounted) _navigate();
  }

  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;
    final auth = context.read<RailAuthProvider>();
    final ok = await auth.signUp(_signupEmailCtrl.text, _signupPassCtrl.text);
    if (ok && mounted) _navigate();
  }

  void _handleGuest() {
    context.read<RailAuthProvider>().continueAsGuest();
    _navigate();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final auth = context.watch<RailAuthProvider>();
    final isLoading = auth.status == AuthStatus.loading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.railwayBlue, AppTheme.railwayBlueMid],
            begin: Alignment.topCenter,
            end: Alignment(0, 0.5),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top header ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.safetyYellow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text('🚉', style: TextStyle(fontSize: 38)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'RailGuide',
                      style: GoogleFonts.rajdhani(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      lang.t('app_title') == 'RailGuide'
                          ? 'Navigate with confidence'
                          : lang.t('app_title'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Card ───────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.scaffoldBg,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      // Tab bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TabBar(
                            controller: _tabCtrl,
                            indicator: BoxDecoration(
                              color: AppTheme.railwayBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.white,
                            unselectedLabelColor: AppTheme.textSecondary,
                            labelStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            tabs: [
                              Tab(text: lang.t('login')),
                              Tab(text: lang.t('signup')),
                            ],
                          ),
                        ),
                      ),

                      // Tab views
                      Expanded(
                        child: TabBarView(
                          controller: _tabCtrl,
                          children: [
                            // ── Login Tab ───────────────────
                            _LoginTab(
                              formKey: _loginFormKey,
                              emailCtrl: _loginEmailCtrl,
                              passCtrl: _loginPassCtrl,
                              obscure: _loginObscure,
                              onToggleObscure: () =>
                                  setState(() => _loginObscure = !_loginObscure),
                              isLoading: isLoading,
                              onLogin: _handleLogin,
                              onGuest: _handleGuest,
                              lang: lang,
                            ),

                            // ── Sign Up Tab ─────────────────
                            _SignupTab(
                              formKey: _signupFormKey,
                              emailCtrl: _signupEmailCtrl,
                              passCtrl: _signupPassCtrl,
                              confirmCtrl: _signupConfirmCtrl,
                              obscure: _signupObscure,
                              onToggleObscure: () => setState(
                                  () => _signupObscure = !_signupObscure),
                              isLoading: isLoading,
                              onSignup: _handleSignup,
                              lang: lang,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Login Tab
// ──────────────────────────────────────────────────────────
class _LoginTab extends StatelessWidget {
  const _LoginTab({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.isLoading,
    required this.onLogin,
    required this.onGuest,
    required this.lang,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onGuest;
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: lang.t('email'),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: passCtrl,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: lang.t('password'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: onToggleObscure,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your password';
                if (v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Login Button
            ElevatedButton(
              onPressed: isLoading ? null : onLogin,
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.railwayBlue,
                      ),
                    )
                  : Text(lang.t('login')),
            ),
            const SizedBox(height: 14),

            // Divider
            const Row(children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('or',
                    style: TextStyle(color: AppTheme.textLight)),
              ),
              Expanded(child: Divider()),
            ]),
            const SizedBox(height: 14),

            // Guest Mode
            OutlinedButton.icon(
              onPressed: onGuest,
              icon: const Icon(Icons.person_outline),
              label: Text(lang.t('guest')),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Sign Up Tab
// ──────────────────────────────────────────────────────────
class _SignupTab extends StatelessWidget {
  const _SignupTab({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.isLoading,
    required this.onSignup,
    required this.lang,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool isLoading;
  final VoidCallback onSignup;
  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: lang.t('email'),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passCtrl,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: lang.t('password'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: onToggleObscure,
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 6) {
                  return 'Minimum 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) {
                if (v != passCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: isLoading ? null : onSignup,
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.railwayBlue,
                      ),
                    )
                  : Text(lang.t('signup')),
            ),
          ],
        ),
      ),
    );
  }
}