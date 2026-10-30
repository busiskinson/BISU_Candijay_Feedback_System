import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// A premium curved purple header used across customer-facing screens.
/// Wraps arbitrary [child] content, clips a gentle wave at the bottom,
/// and draws a thin gold accent line along that curve.
class WaveHeader extends StatelessWidget {
  final Widget child;
  final double height;

  const WaveHeader({super.key, required this.child, this.height = 190});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            ),
          ),
          ClipPath(
            clipper: _WaveAccentClipper(),
            child: Container(color: AppColors.accent),
          ),
          SafeArea(bottom: false, child: child),
        ],
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 28);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 18,
      size.width,
      size.height - 28,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// A thin sliver just below the main wave, used to render a subtle
/// gold accent line that follows the same curve.
class _WaveAccentClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const thickness = 3.0;
    path.moveTo(0, size.height - 28);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 18,
      size.width,
      size.height - 28,
    );
    path.lineTo(size.width, size.height - 28 + thickness);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 18 + thickness,
      0,
      size.height - 28 + thickness,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Subtle press feedback for cards/buttons — slight scale down on tap.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const TapScale({super.key, required this.child, required this.onTap});

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}