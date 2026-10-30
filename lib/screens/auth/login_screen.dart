import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/admin_dashboard.dart';
import '../qa/qa_dashboard.dart';
import '../director/director_dashboard.dart';
import '../staff/staff_dashboard.dart';
import '../customer/customer_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String? errorMessage;

  static const Color _purple = Color(0xFF3B075B);
  static const Color _deepPurple = Color(0xFF26003D);
  static const Color _gold = Color(0xFFFFB800);
  static const Color _lavender = Color(0xFFF3EEFA);
  static const Color _text = Color(0xFF21152E);
  static const Color _secondary = Color(0xFF777184);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;
      final uid = credential.user!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;

      if (!userDoc.exists) {
        setState(() => errorMessage = 'No profile found for this account.');
        return;
      }

      final role = userDoc.data()?['role'] ?? 'customer';
      final Widget destination;
      switch (role) {
        case 'admin':
          destination = const AdminDashboard();
          break;
        case 'qa_director':
          destination = const QaDashboard();
          break;
        case 'campus_director':
          destination = const DirectorDashboard();
          break;
        case 'faculty_staff':
          destination = const StaffDashboard();
          break;
        case 'customer':
        default:
          destination = const CustomerDashboard();
      }

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => errorMessage = e.message ?? 'Login failed.');
    } catch (e) {
      if (mounted) setState(() => errorMessage = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lavender,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return isWide ? _wideLayout() : _narrowLayout(constraints.maxHeight);
        },
      ),
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        const Expanded(flex: 5, child: _BrandPanel()),
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF7F4FC), Color(0xFFF0EBFA)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -110,
                  bottom: -130,
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _purple.withValues(alpha: 0.06), width: 32),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 36),
                      child: _loginCard(isWide: true),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout(double availableHeight) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: availableHeight < 700 ? 235 : 270, child: const _BrandPanel(compact: true)),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
              child: _loginCard(isWide: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginCard({required bool isWide}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.home_rounded, size: 19),
                label: const Text('Back to Home'),
                style: TextButton.styleFrom(
                  foregroundColor: _purple,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: _lavender,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _purple.withValues(alpha: 0.05)),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: _purple, size: 30),
            ),
            const SizedBox(height: 22),
            Text(
              'Welcome back',
              style: TextStyle(
                fontSize: isWide ? 34 : 29,
                fontWeight: FontWeight.w800,
                color: _text,
                letterSpacing: -0.8,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sign in to access the BISU Candijay Campus Feedback System.',
              style: TextStyle(fontSize: 15, height: 1.6, color: _secondary),
            ),
            const SizedBox(height: 32),
            _fieldLabel('Email address'),
            const SizedBox(height: 9),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration(hint: 'Enter your email address', icon: Icons.mail_outline_rounded),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Please enter your email';
                if (!value.trim().contains('@')) return 'Please enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 22),
            _fieldLabel('Password'),
            const SizedBox(height: 9),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => isLoading ? null : loginUser(),
              decoration: _fieldDecoration(hint: 'Enter your password', icon: Icons.lock_outline_rounded).copyWith(
                suffixIcon: IconButton(
                  tooltip: obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => obscurePassword = !obscurePassword),
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: _secondary,
                    size: 20,
                  ),
                ),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter your password' : null,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFE8B7B7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(errorMessage!, style: const TextStyle(color: Color(0xFFB42318), fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_purple, _deepPurple]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _gold.withValues(alpha: 0.55), width: 1),
                  boxShadow: [
                    BoxShadow(color: _purple.withValues(alpha: 0.18), blurRadius: 22, offset: const Offset(0, 10)),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white70,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 23, height: 23, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded, size: 22),
                      SizedBox(width: 13),
                      Text('Sign In Securely', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: _purple, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Authorized access for Admin, QA Director, Campus Director, and Faculty/Staff accounts.',
                    style: TextStyle(color: _secondary, fontSize: 12.5, height: 1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Center(
              child: Text(
                'BOHOL ISLAND STATE UNIVERSITY • CANDIJAY CAMPUS',
                textAlign: TextAlign.center,
                style: TextStyle(color: _secondary.withValues(alpha: 0.8), fontSize: 9.5, letterSpacing: 1.1, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(
    label,
    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _text),
  );

  InputDecoration _fieldDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFAAA4B5), fontSize: 14),
      prefixIcon: Icon(icon, size: 21, color: _purple.withValues(alpha: 0.78)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.94),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE6E0EE))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE6E0EE))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _purple, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD92D20), width: 1.2)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD92D20), width: 1.4)),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final bool compact;
  const _BrandPanel({this.compact = false});

  static const Color _purple = Color(0xFF3B075B);
  static const Color _deepPurple = Color(0xFF26003D);
  static const Color _gold = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('image/img_2.png', fit: BoxFit.cover, alignment: const Alignment(0, 0.35)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC26003D), Color(0x6626003D), Color(0xB326003D)],
                  stops: [0.0, 0.48, 1.0],
                ),
              ),
            ),
            Positioned(
              top: compact ? 20 : 38,
              left: compact ? 18 : 34,
              right: compact ? 18 : 32,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: _gold, width: 2),
                      boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.22), blurRadius: 16, spreadRadius: 1)],
                    ),
                    child: ClipOval(
                      child: Image.asset('image/img.png', width: compact ? 43 : 64, height: compact ? 43 : 64, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 13),
                      decoration: const BoxDecoration(border: Border(left: BorderSide(color: _gold, width: 2))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'BOHOL ISLAND STATE UNIVERSITY',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white, fontSize: compact ? 10 : 14, letterSpacing: compact ? 0.7 : 1.3, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text('CANDIJAY CAMPUS', style: TextStyle(color: _gold, fontSize: compact ? 13 : 20, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                          if (!compact) ...[
                            const SizedBox(height: 5),
                            const Text('Quality Education  •  Service  •  Community', style: TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!compact)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(38, 130, 38, 88),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                        decoration: BoxDecoration(
                          color: _deepPurple.withValues(alpha: 0.48),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,

                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: _gold, size: 17),
                    const SizedBox(width: 8),
                    Expanded(child: Text('BISU Candijay Campus • Feedback System', style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontWeight: FontWeight.w600, fontSize: 12))),
                  ],
                ),
              ),
            Positioned(
              left: -35,
              bottom: compact ? -65 : -95,
              child: Transform.rotate(
                angle: -0.12,
                child: Container(
                  width: compact ? 300 : 600,
                  height: compact ? 100 : 150,
                  decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(100)),
                ),
              ),
            ),
            Positioned(
              left: -45,
              bottom: compact ? -78 : -112,
              child: Transform.rotate(
                angle: -0.12,
                child: Container(
                  width: compact ? 320 : 630,
                  height: compact ? 110 : 165,
                  decoration: BoxDecoration(color: _deepPurple, borderRadius: BorderRadius.circular(100)),
                ),
              ),
            ),
            Positioned(right: 0, top: 0, bottom: 0, child: Container(width: 4, color: _gold)),
          ],
        ),
      ),
    );
  }
}

