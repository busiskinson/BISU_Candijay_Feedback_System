import 'package:flutter/material.dart';
import 'auth/login_screen.dart';

/// Welcome page for the BISU Candijay Campus Feedback System.
/// Uses the existing campus photo and logo assets and preserves Staff Login navigation.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color _purple = Color(0xFF3B075B);
  static const Color _deepPurple = Color(0xFF26003D);
  static const Color _gold = Color(0xFFFFB800);
  static const Color _ink = Color(0xFF21152E);
  static const Color _muted = Color(0xFF777184);
  static const Color _lavender = Color(0xFFF3EEFA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lavender,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return isWide
                ? _buildDesktopLayout(context, constraints)
                : _buildMobileLayout(context, constraints);
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 11,
          child: _BrandPanel(isCompact: constraints.maxHeight < 650),
        ),
        Expanded(
          flex: 9,
          child: _PortalPanel(
            onLogin: () => _openLogin(context),
            isCompact: constraints.maxHeight < 650,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, BoxConstraints constraints) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          children: [
            SizedBox(
              height: constraints.maxHeight < 700 ? 300 : 350,
              child: const _BrandPanel(isCompact: true, mobile: true),
            ),
            _PortalPanel(
              onLogin: () => _openLogin(context),
              mobile: true,
            ),
          ],
        ),
      ),
    );
  }

  void _openLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.isCompact = false, this.mobile = false});

  final bool isCompact;
  final bool mobile;

  static const Color _purple = Color(0xFF3B075B);
  static const Color _deepPurple = Color(0xFF26003D);
  static const Color _gold = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Actual campus photograph, filling the brand panel.
          Image.asset(
            'image/img_2.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0, 0.15),
            errorBuilder: (_, __, ___) => Container(color: _deepPurple),
          ),
          // Purple overlay keeps the campus visible while protecting text contrast.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _deepPurple.withValues(alpha: 0.72),
                  _purple.withValues(alpha: 0.30),
                  _deepPurple.withValues(alpha: 0.84),
                ],
                stops: const [0.0, 0.48, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 4, color: _gold),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              mobile ? 22 : 38,
              mobile ? 20 : 28,
              mobile ? 22 : 32,
              mobile ? 18 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _universityHeader(compact: mobile),
                const Expanded(child: SizedBox.shrink()),
                _brandFooter(compact: mobile || isCompact),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _universityHeader({required bool compact}) {
    final logoSize = compact ? 54.0 : 72.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // University logo sits on the left, matching the Login Screen header.
        Container(
          width: logoSize,
          height: logoSize,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'image/img.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.account_balance_rounded,
                color: _purple,
              ),
            ),
          ),
        ),
        SizedBox(width: compact ? 10 : 16),
        Container(
          width: compact ? 2 : 3,
          height: compact ? 48 : 58,
          color: _gold,
        ),
        SizedBox(width: compact ? 10 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BOHOL ISLAND STATE UNIVERSITY',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 9.5 : 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: compact ? 0.8 : 1.5,
                ),
              ),
              SizedBox(height: compact ? 3 : 5),
              Text(
                'CANDIJAY CAMPUS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _gold,
                  fontSize: compact ? 11 : 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: compact ? 1.0 : 1.7,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 5),
                const Text(
                  'Quality Education  •  Service  •  Community',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _brandFooter({required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 12 : 17, horizontal: compact ? 4 : 8),
      decoration: BoxDecoration(
        color: _deepPurple.withValues(alpha: 0.78),
        border: const Border(top: BorderSide(color: _gold, width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _footerItem(Icons.verified_user_outlined, 'Better Services', compact),
          _footerItem(Icons.groups_2_outlined, 'Stronger Community', compact),
          _footerItem(Icons.trending_up_rounded, 'A Brighter Future', compact),
        ],
      ),
    );
  }

  Widget _footerItem(IconData icon, String label, bool compact) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _gold, size: compact ? 15 : 20),
            SizedBox(width: compact ? 4 : 8),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 8 : 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortalPanel extends StatelessWidget {
  const _PortalPanel({
    required this.onLogin,
    this.isCompact = false,
    this.mobile = false,
  });

  final VoidCallback onLogin;
  final bool isCompact;
  final bool mobile;

  static const Color _purple = Color(0xFF3B075B);
  static const Color _deepPurple = Color(0xFF26003D);
  static const Color _gold = Color(0xFFFFB800);
  static const Color _ink = Color(0xFF21152E);
  static const Color _muted = Color(0xFF777184);
  static const Color _lavender = Color(0xFFF3EEFA);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: const Color(0xFFFCFBFE),
            child: Opacity(
              opacity: 0.055,
              child: Image.asset(
                'image/img_2.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomRight,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        Positioned(
          right: -100,
          bottom: -140,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _lavender.withValues(alpha: 0.9), width: 32),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            mobile ? 24 : (isCompact ? 34 : 54),
            mobile ? 20 : (isCompact ? 22 : 32),
            mobile ? 24 : (isCompact ? 34 : 54),
            mobile ? 28 : (isCompact ? 22 : 32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_outlined, size: 15, color: _muted),
                    const SizedBox(width: 7),
                    Text(
                      'QUALITY EDUCATION',
                      style: TextStyle(
                        color: _muted,
                        fontSize: mobile ? 8 : 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: _gold)),
                    const SizedBox(width: 8),
                    Text(
                      'SERVICE  •  COMMUNITY',
                      style: TextStyle(
                        color: _muted,
                        fontSize: mobile ? 8 : 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: mobile ? 20 : 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: _lavender,
                                borderRadius: BorderRadius.circular(17),
                              ),
                              child: const Icon(Icons.people_alt_rounded, color: _purple, size: 29),
                            ),
                            SizedBox(height: mobile ? 20 : 24),
                            Text(
                              'Administration Portal',
                              style: TextStyle(
                                color: _ink,
                                fontSize: mobile ? 29 : (isCompact ? 30 : 37),
                                height: 1.12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sign in to manage feedback, generate reports, and oversee customer satisfaction across BISU Candijay Campus.',
                              style: TextStyle(
                                color: _muted,
                                fontSize: mobile ? 14 : (isCompact ? 14 : 16),
                                height: 1.65,
                              ),
                            ),
                            SizedBox(height: mobile ? 28 : 38),
                            SizedBox(
                              width: double.infinity,
                              height: 62,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _purple.withValues(alpha: 0.18),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: onLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _deepPurple,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 22),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: _purple.withValues(alpha: 0.65)),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.login_rounded, size: 25),
                                      const SizedBox(width: 18),
                                      Container(width: 1, height: 30, color: Colors.white38),
                                      const SizedBox(width: 18),
                                      const Expanded(
                                        child: Text(
                                          'Staff Login',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_rounded, size: 25),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 23,
                                  height: 23,
                                  decoration: const BoxDecoration(
                                    color: _lavender,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.info_outline_rounded, size: 16, color: _purple),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Authorized access for Admin, QA Director, Campus Director, and Faculty/Staff accounts.',
                                      style: TextStyle(color: _muted, fontSize: 12.5, height: 1.5),
                                    ),
                                  ),

                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

