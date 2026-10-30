import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/director_shell.dart';
import 'approved_report_view_screen.dart';

class ApprovedReportsScreen extends StatelessWidget {
  const ApprovedReportsScreen({super.key});

  static const monthNames = ['', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'];

  @override
  Widget build(BuildContext context) {
    return DirectorShell(
      title: 'Approved Reports',
      selectedIndex: 1,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('submitted_reports')
            .where('status', isEqualTo: 'Approved')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }

          final docs = snapshot.data!.docs;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${docs.length} approved report(s)', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Container(
                  decoration: AppDecorations.card(),
                  child: docs.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('No approved reports yet.', style: TextStyle(color: AppColors.textSecondary))),
                  )
                      : Column(
                    children: [
                      for (int i = 0; i < docs.length; i++) _tile(context, docs[i], isLast: i == docs.length - 1),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, QueryDocumentSnapshot doc, {required bool isLast}) {
    final report = ReportModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    final officeLabel = report.officeBreakdowns.length == 1
        ? report.officeBreakdowns.first.officeName
        : '${report.officeBreakdowns.length} Office(s)';

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ApprovedReportViewScreen(reportId: doc.id))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF2F2F2)))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.reportTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text('${monthNames[report.reportMonth]} ${report.reportYear} • $officeLabel • ${report.totalFeedback} entries',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: const Text('Approved', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}