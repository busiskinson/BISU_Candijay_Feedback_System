import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/qa_shell.dart';
import 'qa_report_review_screen.dart';

class QaReportsScreen extends StatefulWidget {
  const QaReportsScreen({super.key});

  @override
  State<QaReportsScreen> createState() => _QaReportsScreenState();
}

class _QaReportsScreenState extends State<QaReportsScreen> {
  String statusFilter = 'All Status';

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.danger;
      case 'Returned for Revision':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    const monthNames = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];

    return QaShell(
      title: 'Reports',
      selectedIndex: 1,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('submitted_reports').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }

          final docs = snapshot.data!.docs;
          final filtered = docs.where((doc) {
            final status = (doc.data() as Map)['status'] ?? 'Pending Review';
            return statusFilter == 'All Status' || status == statusFilter;
          }).toList();

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.card(),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined, size: 17, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(9)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: statusFilter,
                            items: const ['All Status', 'Pending Review', 'Approved', 'Rejected', 'Returned for Revision']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12.5))))
                                .toList(),
                            onChanged: (v) => setState(() => statusFilter = v!),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text('${filtered.length} report(s)', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: AppDecorations.card(),
                  child: filtered.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('No reports match this filter.', style: TextStyle(color: AppColors.textSecondary))),
                  )
                      : Column(
                    children: [
                      for (int i = 0; i < filtered.length; i++) _tile(context, filtered[i], monthNames, isLast: i == filtered.length - 1),
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

  Widget _tile(BuildContext context, QueryDocumentSnapshot doc, List<String> monthNames, {required bool isLast}) {
    final report = ReportModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    final officeLabel = report.officeBreakdowns.length == 1
        ? report.officeBreakdowns.first.officeName
        : '${report.officeBreakdowns.length} Office(s)';

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QaReportReviewScreen(reportId: doc.id))),
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
                  if (report.approvalRemarks != null && report.approvalRemarks!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Remarks: ${report.approvalRemarks}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _statusColor(report.status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(report.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(report.status))),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}