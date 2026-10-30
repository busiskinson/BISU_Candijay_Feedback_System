import 'package:flutter/material.dart';
import 'satisfaction_form_screen.dart';
import 'complaint_form_screen.dart';
import '../../utils/app_theme.dart';
import '../../widgets/wave_header.dart';

class FeedbackTypeScreen extends StatelessWidget {
  const FeedbackTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WaveHeader(
            height: 130,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Text('Submit Feedback',
                      style: AppTextStyles.sectionTitle.copyWith(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What would you like to do?', style: AppTextStyles.heading),
                  const SizedBox(height: 8),
                  Text('Choose the option that fits your visit.', style: AppTextStyles.subheading),
                  const SizedBox(height: 28),

                  _FeedbackOptionCard(
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    accentColor: AppColors.primary,
                    iconBackground: AppColors.primary.withValues(alpha: 0.10),
                    title: 'Satisfaction Feedback',
                    subtitle: 'Rate your experience with a service you availed.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SatisfactionFormScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _FeedbackOptionCard(
                    icon: Icons.report_problem_rounded,
                    accentColor: AppColors.danger,
                    iconBackground: AppColors.danger.withValues(alpha: 0.08),
                    title: 'File a Complaint',
                    subtitle: 'Report an issue or concern with a service or staff.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ComplaintFormScreen()),
                      );
                    },
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

class _FeedbackOptionCard extends StatefulWidget {
  final IconData icon;
  final Color accentColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeedbackOptionCard({
    required this.icon,
    required this.accentColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_FeedbackOptionCard> createState() => _FeedbackOptionCardState();
}

class _FeedbackOptionCardState extends State<_FeedbackOptionCard> {
  double _elevationBoost = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _elevationBoost = 4),
      onTapUp: (_) => setState(() => _elevationBoost = 0),
      onTapCancel: () => setState(() => _elevationBoost = 0),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border(left: BorderSide(color: widget.accentColor, width: 4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06 + (_elevationBoost * 0.005)),
              blurRadius: 14 + _elevationBoost,
              offset: Offset(0, 4 + (_elevationBoost * 0.3)),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: widget.iconBackground,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(widget.icon, color: widget.accentColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 4),
                  Text(widget.subtitle, style: AppTextStyles.subheading),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}