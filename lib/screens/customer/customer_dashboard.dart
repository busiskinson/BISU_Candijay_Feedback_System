import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_theme.dart';
import 'feedback_type_screen.dart';
import 'qr_scanner_screen.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  Future<void> _confirmExit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to close the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (confirmed == true) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 760;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFF),
      body: Stack(
        children: [
          // Decorative campus image at the bottom. Keep image/img_2.png in pubspec assets.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.34,
            child: Opacity(
              opacity: 0.22,
              child: Image.asset(
                'image/img_2.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFDFBFF),
                    const Color(0xFFFDFBFF).withValues(alpha: 0.94),
                    const Color(0xFFEDE7FA).withValues(alpha: 0.38),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _CustomerHeader(onExit: () => _confirmExit(context)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, compact ? 18 : 28, 24, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome!',
                                    style: TextStyle(
                                      fontSize: compact ? 34 : 40,
                                      height: 1.1,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.1,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'BISU Candijay Campus',
                                    style: TextStyle(
                                      fontSize: compact ? 17 : 20,
                                      color: const Color(0xFF77728D),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 22 : 30),
                            _FeedbackIllustration(size: compact ? 150 : 182),
                            SizedBox(height: compact ? 18 : 26),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'We value your\n',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                  TextSpan(
                                    text: 'feedback',
                                    style: TextStyle(color: AppColors.accent),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: compact ? 34 : 43,
                                height: 1.06,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.2,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                'Help us improve our services by sharing your experience or reporting a concern.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.55,
                                  color: Color(0xFF666277),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 26 : 38),
                            _ActionButton(
                              title: 'Scan Office QR Code',
                              icon: Icons.qr_code_2_rounded,
                              primary: true,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _ActionButton(
                              title: 'Submit Feedback Manually',
                              icon: Icons.edit_rounded,
                              primary: false,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const FeedbackTypeScreen()),
                              ),
                            ),
                            const SizedBox(height: 26),
                            const Text(
                              'QUALITY EDUCATION  •  SERVICE  •  COMMUNITY',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF817B99),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _CustomerHeader extends StatelessWidget {
  final VoidCallback onExit;
  const _CustomerHeader({required this.onExit});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _HeaderWaveClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 18, 18, 34),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF321052), Color(0xFF21083E), Color(0xFF18052F)],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.accent, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'image/img.png',
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 68,
                    height: 68,
                    child: Icon(Icons.account_balance_rounded, color: Color(0xFF321052), size: 34),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Container(width: 2, height: 62, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BOHOL ISLAND STATE UNIVERSITY',
                    maxLines: 2,
                    style: TextStyle(color: Colors.white, fontSize: 11, height: 1.3, letterSpacing: 0.7, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Candijay Campus',
                    style: TextStyle(color: Color(0xFFFFC629), fontSize: 20, height: 1.1, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Quality Education  •  Service  •  Community',
                    maxLines: 2,
                    style: TextStyle(color: Color(0xFFE2D8F0), fontSize: 10, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
              child: IconButton(
                tooltip: 'Exit app',
                onPressed: onExit,
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 23),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 26)
      ..quadraticBezierTo(size.width * 0.72, size.height - 4, size.width * 0.48, size.height - 7)
      ..quadraticBezierTo(size.width * 0.22, size.height - 8, 0, size.height - 34)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _FeedbackIllustration extends StatelessWidget {
  final double size;
  const _FeedbackIllustration({this.size = 182});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C42B5).withValues(alpha: 0.07),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 5),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6B42B2).withValues(alpha: 0.12), blurRadius: 28, spreadRadius: 2),
              ],
            ),
          ),
          Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C42B5).withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: size * 0.61,
            height: size * 0.61,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF552080), Color(0xFF260843)],
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFF2A0B49).withValues(alpha: 0.24), blurRadius: 18, offset: const Offset(0, 9)),
              ],
            ),
            child: Icon(Icons.forum_rounded, color: Colors.white, size: size * 0.28),
          ),
          Positioned(
            top: size * 0.05,
            right: size * 0.04,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
                boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Icon(Icons.star_rounded, color: Colors.white, size: size * 0.13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primary;
    return Material(
      color: primary ? null : Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          height: 72,
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4B176F), Color(0xFF260843)],
            )
                : null,
            color: primary ? null : Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: primary ? null : Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: primary ? 0.20 : 0.08),
                blurRadius: primary ? 20 : 12,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: primary ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF1ECFA),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 25, color: primary ? Colors.white : color),
                ),
                const SizedBox(width: 15),
                Container(width: 1.5, height: 32, color: primary ? Colors.white.withValues(alpha: 0.45) : color.withValues(alpha: 0.35)),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: primary ? Colors.white : color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, size: 25, color: primary ? Colors.white : color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

