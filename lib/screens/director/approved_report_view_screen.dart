import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/director_shell.dart';
import '../../widgets/official_letterhead.dart';

class ApprovedReportViewScreen extends StatefulWidget {
  final String reportId;

  const ApprovedReportViewScreen({super.key, required this.reportId});

  @override
  State<ApprovedReportViewScreen> createState() => _ApprovedReportViewScreenState();
}

class _ApprovedReportViewScreenState extends State<ApprovedReportViewScreen> {
  static const monthNames = ['', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'];

  bool isLoading = true;
  ReportModel? report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance.collection('submitted_reports').doc(widget.reportId).get();
    final data = doc.data();
    if (data != null) report = ReportModel.fromMap(doc.id, data);
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DirectorShell(
      title: 'Report',
      selectedIndex: 1,
      body: isLoading
          ? const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
          : report == null
          ? const Padding(padding: EdgeInsets.all(30), child: Text('Report not found.', style: TextStyle(color: AppColors.textSecondary)))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
              Expanded(child: Text(report!.reportTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: const Text('Approved', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
              ),
            ],
          ),
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
                    child: report!.officeBreakdowns.length > 1 ? _summaryBody() : _reportCardBody(),
                  ),
                ],
              ),
            ),
          ),
          if (report!.approvalRemarks != null && report!.approvalRemarks!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.card(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('QA Director Remarks', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(report!.approvalRemarks!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
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

  Widget _summaryBody() {
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
        _charterTable(report!.officeBreakdowns),
        const SizedBox(height: 28),
        _sectionLabel('B. CSF Monthly Rating'),
        const SizedBox(height: 10),
        _ratingTable(report!.officeBreakdowns),
        const SizedBox(height: 28),
        _sectionLabel('C. CSF Monthly Commendations & Suggestions'),
        const SizedBox(height: 10),
        _commendationsSuggestionsTable(report!.officeBreakdowns),
      ],
    );
  }

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
        _charterTable([office]),
        const SizedBox(height: 28),
        _sectionLabel('B. CSF Monthly Rating'),
        const SizedBox(height: 10),
        _ratingTable([office]),
        const SizedBox(height: 28),
        _sectionLabel('C. CSF Monthly Commendations & Suggestions'),
        const SizedBox(height: 10),
        _commendationsSuggestionsTable([office]),
      ],
    );
  }

  // Read-only Section C matching the Admin and QA report layouts.
  // The submitted report model currently stores commendations and suggestions;
  // implementation-planning values are shown as dashes unless saved in the report data.
  Widget _commendationsSuggestionsTable(List<OfficeReportBreakdown> rows) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No commendations or suggestions this period.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: const Color(0xFFE0E0E0)),
        defaultColumnWidth: const FixedColumnWidth(210),
        columnWidths: const {0: FixedColumnWidth(150)},
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.background),
            children: [
              _headerCell('Office'),
              _headerCell('Commendations'),
              _headerCell('Suggestions'),
              _headerCell('Detail of Suggestions'),
              _headerCell('Root Cause'),
              _headerCell('Action Plan'),
              _headerCell('Target of Implementation'),
              _headerCell('Status of Implementation'),
            ],
          ),
          for (final office in rows)
            TableRow(
              children: [
                _textCell(office.officeName, bold: true),
                _listCell(office.commendations),
                _listCell(office.suggestions),
                _textCell('—'),
                _textCell('—'),
                _textCell('—'),
                _textCell('—'),
                _textCell('—'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _textCell(String text, {bool bold = false}) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
  );

  Widget _listCell(List<String> items) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          '—',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 5),
              child: Text(
                '${i + 1}. ${items[i]}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _charterTable(List<OfficeReportBreakdown> rows) {
    if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('No data.', style: TextStyle(color: AppColors.textSecondary)));
    const headers = [
      'Offices', 'Cust.', 'M', 'F', 'Citizen', 'Business', "Gov't", 'Student',
      'CC1-1', 'CC1-2', 'CC1-3', 'CC1-4', 'CC2-1', 'CC2-2', 'CC2-3', 'CC2-4', 'CC2-5',
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
          TableRow(decoration: const BoxDecoration(color: AppColors.background), children: [for (final h in headers) _headerCell(h)]),
          for (int i = 0; i < displayRows.length; i++) _charterRow(displayRows[i], isTotal: showOverall && i == displayRows.length - 1),
        ],
      ),
    );
  }

  TableRow _charterRow(OfficeReportBreakdown b, {bool isTotal = false}) {
    final style = TextStyle(fontSize: 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal);
    final values = [
      isTotal ? 'OVERALL' : b.officeName, '${b.numberOfCustomers}', '${b.sexMale}', '${b.sexFemale}',
      '${b.clientCitizen}', '${b.clientBusiness}', '${b.clientGovernment}', '${b.clientStudent}',
      '${b.cc1Counts[1] ?? 0}', '${b.cc1Counts[2] ?? 0}', '${b.cc1Counts[3] ?? 0}', '${b.cc1Counts[4] ?? 0}',
      '${b.cc2Counts[1] ?? 0}', '${b.cc2Counts[2] ?? 0}', '${b.cc2Counts[3] ?? 0}', '${b.cc2Counts[4] ?? 0}', '${b.cc2Counts[5] ?? 0}',
      '${b.cc3Counts[1] ?? 0}', '${b.cc3Counts[2] ?? 0}', '${b.cc3Counts[3] ?? 0}', '${b.cc3Counts[4] ?? 0}',
    ];
    return TableRow(children: [for (final v in values) _cell(v, style)]);
  }

  Widget _headerCell(String text) => Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)));
  Widget _cell(String text, TextStyle style) => Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), child: Text(text, textAlign: TextAlign.center, style: style));

  Widget _ratingTable(List<OfficeReportBreakdown> rows) {
    if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('No data.', style: TextStyle(color: AppColors.textSecondary)));
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
            children: [_headerCell('Offices'), _headerCell('Cust.'), for (final label in dimLabels.values) _headerCell(label), _headerCell('Mean'), _headerCell('Description')],
          ),
          for (int i = 0; i < displayRows.length; i++) _ratingRow(displayRows[i], dimLabels, isTotal: showOverall && i == displayRows.length - 1),
        ],
      ),
    );
  }

  TableRow _ratingRow(OfficeReportBreakdown b, Map<String, String> dimLabels, {bool isTotal = false}) {
    final style = TextStyle(fontSize: 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal);
    return TableRow(children: [
      _cell(isTotal ? 'OVERALL' : b.officeName, style),
      _cell('${b.numberOfCustomers}', style),
      for (final key in dimLabels.keys) _cell(b.dimensionMeans[key] == null ? '—' : b.dimensionMeans[key]!.toStringAsFixed(2), style),
      _cell(b.meanSatisfaction == null ? '—' : b.meanSatisfaction!.toStringAsFixed(2), style.copyWith(fontWeight: FontWeight.bold)),
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
}
