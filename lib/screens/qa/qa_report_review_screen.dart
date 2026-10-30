import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/qa_shell.dart';
import '../../widgets/official_letterhead.dart';

class QaReportReviewScreen extends StatefulWidget {
  final String reportId;

  const QaReportReviewScreen({super.key, required this.reportId});

  @override
  State<QaReportReviewScreen> createState() => _QaReportReviewScreenState();
}

class _QaReportReviewScreenState extends State<QaReportReviewScreen> {
  static const monthNames = ['', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'];

  bool isLoading = true;
  ReportModel? report;
  bool isSubmittingAction = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    final doc = await FirebaseFirestore.instance.collection('submitted_reports').doc(widget.reportId).get();
    final data = doc.data();
    if (data != null) report = ReportModel.fromMap(doc.id, data);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _takeAction(String newStatus) async {
    final remarksController = TextEditingController();
    final needsRemarks = newStatus != 'Approved';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus == 'Approved' ? 'Approve Report' : (newStatus == 'Rejected' ? 'Reject Report' : 'Return for Revision')),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                newStatus == 'Approved'
                    ? 'This report will be forwarded to the Campus Director.'
                    : 'Please provide remarks explaining the decision.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: remarksController,
                maxLines: 3,
                decoration: AppDecorations.input(needsRemarks ? 'Remarks (required)' : 'Remarks (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: AppDecorations.primaryButton(),
            onPressed: () {
              if (needsRemarks && remarksController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isSubmittingAction = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('submitted_reports').doc(widget.reportId).update({
        'status': newStatus,
        'approvedBy': uid,
        'approvalRemarks': remarksController.text.trim(),
        'approvedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report marked as $newStatus.'), backgroundColor: AppColors.success),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => isSubmittingAction = false);
    }
  }

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
    return QaShell(
      title: 'Report Review',
      selectedIndex: 1,
      body: isLoading
          ? const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
          : report == null
          ? const Padding(padding: EdgeInsets.all(30), child: Text('Report not found.', style: TextStyle(color: AppColors.textSecondary)))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _toolbar(),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Container(
              decoration: AppDecorations.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OfficialLetterhead(officeName: 'Quality Assurance'),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: report!.officeBreakdowns.length > 1
                        ? _summaryReportBody()
                        : _reportCardBody(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (report!.status == 'Pending Review') _actionBar(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------- Toolbar ----------

  Widget _toolbar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${report!.reportTitle} — ${monthNames[report!.reportMonth]} ${report!.reportYear}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _statusColor(report!.status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(report!.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor(report!.status))),
          ),
        ],
      ),
    );
  }

  // ---------- Action Bar ----------

  Widget _actionBar() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isSubmittingAction ? null : () => _takeAction('Approved'),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success, foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isSubmittingAction ? null : () => _takeAction('Returned for Revision'),
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: const Text('Return for Revision'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning, foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isSubmittingAction ? null : () => _takeAction('Rejected'),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger, foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.primary, width: 1.4))),
      child: Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
    );
  }

  // ---------- CSF Summary Report (multi-office) ----------

  Widget _summaryReportBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Text('MONTHLY CUSTOMER SATISFACTION SUMMARY REPORT', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: Text('Month: ${monthNames[report!.reportMonth]} ${report!.reportYear}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
        ),
        _sectionLabel('A. Citizen\'s Charter Summary Result'),
        const SizedBox(height: 10),
        _citizenCharterTable(report!.officeBreakdowns),
        const SizedBox(height: 28),
        _sectionLabel('B. CSF Monthly Rating'),
        const SizedBox(height: 10),
        _ratingTable(report!.officeBreakdowns),
        const SizedBox(height: 28),
        _sectionLabel('C. CSF Monthly Commendations & Suggestions'),
        const SizedBox(height: 10),
        _commendationsTable(report!.officeBreakdowns),
      ],
    );
  }

  // ---------- Monthly Report Card (single office) ----------

  Widget _reportCardBody() {
    final office = report!.officeBreakdowns.isNotEmpty ? report!.officeBreakdowns.first : null;
    if (office == null) {
      return const Padding(padding: EdgeInsets.all(30), child: Text('No office data in this report.', style: TextStyle(color: AppColors.textSecondary)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: Text('MONTHLY REPORT CARD', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Office Concerned: ${office.officeName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('Month: ${monthNames[report!.reportMonth]} ${report!.reportYear}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel('A. Citizen\'s Charter Summary Result'),
        const SizedBox(height: 10),
        _citizenCharterTable([office]),
        const SizedBox(height: 28),
        _sectionLabel('B. CSF Monthly Rating'),
        const SizedBox(height: 10),
        _ratingTable([office]),
        const SizedBox(height: 28),
        _sectionLabel('CSF Monthly Commendations and Suggestions'),
        const SizedBox(height: 10),
        _commendationsTable([office]),
      ],
    );
  }

  // ---------- Shared: Citizen's Charter Table ----------

  Widget _citizenCharterTable(List<OfficeReportBreakdown> rows) {
    if (rows.isEmpty) {
      return const Padding(padding: EdgeInsets.all(20), child: Text('No data for this period.', style: TextStyle(color: AppColors.textSecondary)));
    }
    const headers = [
      'Offices', 'Cust.', 'M', 'F', 'Citizen', 'Business', "Gov't", 'Student',
      'CC1-1', 'CC1-2', 'CC1-3', 'CC1-4',
      'CC2-1', 'CC2-2', 'CC2-3', 'CC2-4', 'CC2-5',
      'CC3-1', 'CC3-2', 'CC3-3', 'CC3-4',
    ];
    final showOverall = rows.length > 1 && report!.overallBreakdown != null;
    final displayRows = [...rows, if (showOverall) report!.overallBreakdown!];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: const Color(0xFFE0E0E0)),
        defaultColumnWidth: const FixedColumnWidth(62),
        columnWidths: const {0: FixedColumnWidth(140)},
        children: [
          TableRow(decoration: const BoxDecoration(color: AppColors.background), children: [for (final h in headers) _gridHeaderCell(h)]),
          for (int i = 0; i < displayRows.length; i++) _charterGridRow(displayRows[i], isTotal: showOverall && i == displayRows.length - 1),
        ],
      ),
    );
  }

  TableRow _charterGridRow(OfficeReportBreakdown b, {bool isTotal = false}) {
    final style = TextStyle(fontSize: 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal);
    final values = [
      isTotal ? 'OVERALL' : b.officeName,
      '${b.numberOfCustomers}', '${b.sexMale}', '${b.sexFemale}',
      '${b.clientCitizen}', '${b.clientBusiness}', '${b.clientGovernment}', '${b.clientStudent}',
      '${b.cc1Counts[1] ?? 0}', '${b.cc1Counts[2] ?? 0}', '${b.cc1Counts[3] ?? 0}', '${b.cc1Counts[4] ?? 0}',
      '${b.cc2Counts[1] ?? 0}', '${b.cc2Counts[2] ?? 0}', '${b.cc2Counts[3] ?? 0}', '${b.cc2Counts[4] ?? 0}', '${b.cc2Counts[5] ?? 0}',
      '${b.cc3Counts[1] ?? 0}', '${b.cc3Counts[2] ?? 0}', '${b.cc3Counts[3] ?? 0}', '${b.cc3Counts[4] ?? 0}',
    ];
    return TableRow(children: [for (final v in values) _gridCell(v, style)]);
  }

  Widget _gridHeaderCell(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
  );

  Widget _gridCell(String text, TextStyle style) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    child: Text(text, textAlign: TextAlign.center, style: style),
  );

  // ---------- Shared: Ratings Table ----------

  Widget _ratingTable(List<OfficeReportBreakdown> rows) {
    if (rows.isEmpty) {
      return const Padding(padding: EdgeInsets.all(20), child: Text('No data for this period.', style: TextStyle(color: AppColors.textSecondary)));
    }
    const dimLabels = {
      'responsiveness': 'Responsiveness', 'reliability': 'Reliability', 'accessFacilities': 'Access & Facilities',
      'communication': 'Communication', 'costs': 'Costs', 'integrity': 'Integrity', 'assurance': 'Assurance', 'outcome': 'Outcome',
    };
    final showOverall = rows.length > 1 && report!.overallBreakdown != null;
    final displayRows = [...rows, if (showOverall) report!.overallBreakdown!];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: const Color(0xFFE0E0E0)),
        defaultColumnWidth: const FixedColumnWidth(88),
        columnWidths: const {0: FixedColumnWidth(140), 1: FixedColumnWidth(56)},
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.background),
            children: [
              _gridHeaderCell('Offices'),
              _gridHeaderCell('Cust.'),
              for (final label in dimLabels.values) _gridHeaderCell(label),
              _gridHeaderCell('Mean'),
              _gridHeaderCell('Description'),
            ],
          ),
          for (int i = 0; i < displayRows.length; i++) _ratingGridRow(displayRows[i], dimLabels, isTotal: showOverall && i == displayRows.length - 1),
        ],
      ),
    );
  }

  TableRow _ratingGridRow(OfficeReportBreakdown b, Map<String, String> dimLabels, {bool isTotal = false}) {
    final style = TextStyle(fontSize: 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal);
    return TableRow(children: [
      _gridCell(isTotal ? 'OVERALL' : b.officeName, style),
      _gridCell('${b.numberOfCustomers}', style),
      for (final key in dimLabels.keys) _gridCell(b.dimensionMeans[key] == null ? '—' : b.dimensionMeans[key]!.toStringAsFixed(2), style),
      _gridCell(b.meanSatisfaction == null ? '—' : b.meanSatisfaction!.toStringAsFixed(2), style.copyWith(fontWeight: FontWeight.bold)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Text(b.description, style: const TextStyle(fontSize: 10, color: AppColors.success)),
          ),
        ),
      ),
    ]);
  }

  // ---------- Section C: CSF Monthly Commendations & Suggestions ----------

  Widget _commendationsTable(List<OfficeReportBreakdown> rows) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No commendations or suggestions recorded for this period.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: const Color(0xFFE0E0E0)),
        defaultColumnWidth: const FixedColumnWidth(180),
        columnWidths: const {
          0: FixedColumnWidth(150),
          1: FixedColumnWidth(220),
          2: FixedColumnWidth(220),
          3: FixedColumnWidth(220),
          4: FixedColumnWidth(180),
          5: FixedColumnWidth(200),
          6: FixedColumnWidth(180),
          7: FixedColumnWidth(200),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.background),
            children: [
              _commHeader('Office'),
              _commHeader('Commendations'),
              _commHeader('Suggestions'),
              _commHeader('Detail of Suggestions'),
              _commHeader('Root Cause'),
              _commHeader('Action Plan'),
              _commHeader('Target of Implementation'),
              _commHeader('Status of Implementation'),
            ],
          ),
          for (final row in rows)
            TableRow(
              children: [
                _commCell(row.officeName, bold: true),
                _commListCell(row.commendations),
                _commListCell(row.suggestions),
                _commCell('—'),
                _commCell('—'),
                _commCell('—'),
                _commCell('—'),
                _commCell('—'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _commHeader(String text) => Padding(padding: const EdgeInsets.all(10), child: Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)));

  Widget _commCell(String text, {bool bold = false}) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(text, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
  );

  Widget _commListCell(List<String> items) {
    final limited = items.take(3).toList();
    if (limited.isEmpty) {
      return const Padding(padding: EdgeInsets.all(10), child: Text('—', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)));
    }
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (int i = 0; i < limited.length; i++) Text('${i + 1}. ${limited[i]}', style: const TextStyle(fontSize: 12))],
      ),
    );
  }
}
