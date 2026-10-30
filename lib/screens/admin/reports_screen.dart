import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/report_aggregator.dart';
import '../../utils/report_html_generator.dart';
import '../../utils/report_print.dart';
import '../../utils/signatory_lookup.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/official_letterhead.dart';
import 'report_preview_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const reportTypes = ['CSF Summary Report', 'Monthly Report Card'];

  int year = DateTime.now().year;
  int month = DateTime.now().month;
  String reportType = 'CSF Summary Report';
  String officeFilter = 'All Offices';

  // Filters for the Submitted Reports history (separate from report-generation filters).
  final TextEditingController _submittedSearchController = TextEditingController();
  String _submittedSearch = '';
  int _submittedYear = 0; // 0 = All Years
  int _submittedMonth = 0; // 0 = All Months
  String _submittedStatus = 'All Statuses';
  String _submittedOffice = 'All Offices';
  static const int _submittedReportsPerPage = 5;
  int _submittedPage = 0;

  static const List<String> _submittedStatuses = [
    'All Statuses',
    'Pending Review',
    'Under Review',
    'Approved',
    'Rejected',
    'Returned for Revision',
  ];

  bool isLoading = true;
  List<OfficeReportBreakdown> breakdowns = [];
  OfficeReportBreakdown? overall;
  bool isSubmitting = false;

  final Map<String, TextEditingController> _detailSuggestionCtrls = {};
  final Map<String, TextEditingController> _rootCauseCtrls = {};
  final Map<String, TextEditingController> _actionPlanCtrls = {};
  final Map<String, TextEditingController> _targetCtrls = {};
  final Map<String, String> _statusSelections = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _submittedSearchController.dispose();
    for (final c in _detailSuggestionCtrls.values) {
      c.dispose();
    }
    for (final c in _rootCauseCtrls.values) {
      c.dispose();
    }
    for (final c in _actionPlanCtrls.values) {
      c.dispose();
    }
    for (final c in _targetCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => isLoading = true);
    final result = await ReportAggregator.aggregate(year: year, month: month);
    final loadedBreakdowns =
    result['breakdowns'] as List<OfficeReportBreakdown>;
    final loadedOverall = result['overall'] as OfficeReportBreakdown;
    final officeNames = loadedBreakdowns
        .map((b) => b.officeName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (!mounted) return;
    setState(() {
      breakdowns = loadedBreakdowns;
      overall = loadedOverall;
      isLoading = false;

      // A different month can have a different set of offices. Never keep an
      // office selected if it is not present in the newly loaded data.
      if (reportType == 'Monthly Report Card') {
        officeFilter = officeNames.contains(officeFilter)
            ? officeFilter
            : (officeNames.isNotEmpty ? officeNames.first : 'All Offices');
      } else if (officeFilter != 'All Offices' &&
          !officeNames.contains(officeFilter)) {
        officeFilter = 'All Offices';
      }
    });
  }

  Future<void> _printReport() async {
    final Map<String, String> detailMap = {
      for (final e in _detailSuggestionCtrls.entries) e.key: e.value.text
    };
    final Map<String, String> rootCauseMap = {
      for (final e in _rootCauseCtrls.entries) e.key: e.value.text
    };
    final Map<String, String> actionPlanMap = {
      for (final e in _actionPlanCtrls.entries) e.key: e.value.text
    };
    final Map<String, String> targetMap = {
      for (final e in _targetCtrls.entries) e.key: e.value.text
    };

    // Admin (current user), QA Director, and Campus Director names
    final signatories = await SignatoryLookup.fetch();

    final html = await ReportHtmlGenerator.build(
      reportType: reportType,
      year: year,
      month: month,
      breakdowns: _displayBreakdowns,
      overall: overall,
      detailSuggestions: detailMap,
      rootCauses: rootCauseMap,
      actionPlans: actionPlanMap,
      targets: targetMap,
      statuses: _statusSelections,
      preparedByName: signatories.prepared,
      verifiedByName: signatories.verified,
      approvedByName: signatories.approved,
    );

    printReportHtml(html);
  }

  List<OfficeReportBreakdown> get _displayBreakdowns {
    if (officeFilter == 'All Offices') return breakdowns;
    return breakdowns
        .where((b) => b.officeName.trim() == officeFilter.trim())
        .toList();
  }

  List<String> get _officeNames {
    final names = breakdowns
        .map((b) => b.officeName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return names;
  }

  void _setCurrentPeriod() {
    setState(() {
      year = DateTime.now().year;
      month = DateTime.now().month;
      officeFilter = 'All Offices';
      reportType = 'CSF Summary Report';
    });
    _load();
  }

  TextEditingController _ctrlFor(Map<String, TextEditingController> map, String key) {
    return map.putIfAbsent(key, () => TextEditingController());
  }

  Future<void> _submitToQA() async {
    final titleController = TextEditingController(
      text: '$reportType — ${monthNames[month]} $year',
    );
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Report to QA Director'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: AppDecorations.input('Report Title'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: AppDecorations.input('Notes (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: AppDecorations.primaryButton(),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (titleController.text.trim().isEmpty) return;

    setState(() => isSubmitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final totalFeedback = _displayBreakdowns.fold<int>(0, (total, b) => total + b.numberOfCustomers);

      final report = ReportModel(
        reportTitle: titleController.text.trim(),
        reportMonth: month,
        reportYear: year,
        reportNotes: notesController.text.trim(),
        reportType: 'monthly',
        submittedBy: uid,
        totalFeedback: totalFeedback,
        averageRating: overall?.meanSatisfaction,
        satisfactionRate: null,
        officeBreakdowns: _displayBreakdowns,
        overallBreakdown: overall,
      );

      await FirebaseFirestore.instance.collection('submitted_reports').add(report.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted to QA Director for review.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
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
    return AdminShell(
      title: 'Reports',
      selectedIndex: 3,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _toolbar(),
          const SizedBox(height: 20),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else
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
                      child: reportType == 'CSF Summary Report'
                          ? _summaryReportBody()
                          : _reportCardBody(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Submitted Reports', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),
                _submittedReportsList(),
              ],
            ),
          ),
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
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: [
          _smallLabel('Year:'),
          _dropdown<int>(
            value: year,
            items: [for (int y = DateTime.now().year; y >= DateTime.now().year - 3; y--) y],
            labelBuilder: (y) => y == DateTime.now().year ? '$y (Current)' : '$y',
            onChanged: (v) {
              setState(() => year = v!);
              _load();
            },
          ),
          _smallLabel('Month:'),
          _dropdown<int>(
            value: month,
            items: [for (int m = 1; m <= 12; m++) m],
            labelBuilder: (m) => monthNames[m],
            onChanged: (v) {
              setState(() => month = v!);
              _load();
            },
          ),
          _smallLabel('Report:'),
          _dropdown<String>(
            value: reportType,
            items: reportTypes,
            labelBuilder: (t) => t,
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                reportType = v;
                if (reportType == 'Monthly Report Card') {
                  officeFilter = _officeNames.contains(officeFilter)
                      ? officeFilter
                      : (_officeNames.isNotEmpty
                      ? _officeNames.first
                      : 'All Offices');
                } else if (officeFilter != 'All Offices' &&
                    !_officeNames.contains(officeFilter)) {
                  officeFilter = 'All Offices';
                }
              });
            },
          ),
          _smallLabel('Office:'),
          _dropdown<String>(
            value: officeFilter,
            items: [
              if (reportType == 'CSF Summary Report' || _officeNames.isEmpty)
                'All Offices',
              ..._officeNames,
            ],
            labelBuilder: (o) => o,
            onChanged: (v) {
              if (v == null) return;
              setState(() => officeFilter = v);
            },
          ),
          OutlinedButton.icon(
            onPressed: _setCurrentPeriod,
            icon: const Icon(Icons.star_rounded, size: 16),
            label: const Text('Current Period'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                officeFilter = 'All Offices';
                reportType = 'CSF Summary Report';
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _printReport,
            icon: const Icon(Icons.print_rounded, size: 17),
            label: const Text('Print'),
            style: AppDecorations.primaryButton(),
          ),
          ElevatedButton.icon(
            onPressed: isSubmitting ? null : _submitToQA,
            icon: isSubmitting
                ? const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 16),
            label: const Text('Submit to QA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallLabel(String text) =>
      Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600));

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    // DropdownButton requires exactly one item matching its selected value.
    final uniqueItems = items.toSet().toList();
    final safeItems = uniqueItems.isNotEmpty ? uniqueItems : <T>[value];
    final safeValue = safeItems.contains(value) ? value : safeItems.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          items: safeItems
              .map(
                (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                labelBuilder(item),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.primary, width: 1.4)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
    );
  }

  // ---------- CSF Summary Report (multi-office) ----------

  Widget _summaryReportBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'MONTHLY CUSTOMER SATISFACTION SUMMARY REPORT',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: Text('Month: ${monthNames[month]} $year',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
        ),
        _sectionLabel('A. Citizen\'s Charter Summary Result'),
        const SizedBox(height: 10),
        _citizenCharterTable(_displayBreakdowns),
        const SizedBox(height: 28),
        _sectionLabel('B. CSF Monthly Rating'),
        const SizedBox(height: 10),
        _ratingTable(_displayBreakdowns),
        const SizedBox(height: 28),
        _sectionLabel('C. CSF Monthly Commendations & Suggestions'),
        const SizedBox(height: 10),
        _simpleCommendationsSection(_displayBreakdowns),
      ],
    );
  }

  // ---------- Monthly Report Card (single office) ----------

  Widget _reportCardBody() {
    final office = _displayBreakdowns.isNotEmpty ? _displayBreakdowns.first : null;

    if (office == null) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Text('Select a specific office above to view its Report Card.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text('MONTHLY REPORT CARD',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Office Concerned: ${office.officeName}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('Month: ${monthNames[month]} $year',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
        _reportCardCommendationsTable(office),
      ],
    );
  }

  // ---------- Shared: Citizen's Charter Table (bordered grid) ----------

  Widget _citizenCharterTable(List<OfficeReportBreakdown> rows) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('No data for this period.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    const headers = [
      'Offices', 'Cust.', 'M', 'F', 'Citizen', 'Business', "Gov't", 'Student',
      'CC1-1', 'CC1-2', 'CC1-3', 'CC1-4',
      'CC2-1', 'CC2-2', 'CC2-3', 'CC2-4', 'CC2-5',
      'CC3-1', 'CC3-2', 'CC3-3', 'CC3-4',
    ];

    final showOverall = rows.length > 1 && overall != null;
    final displayRows = [...rows, if (showOverall) overall!];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: const Color(0xFFE0E0E0)),
        defaultColumnWidth: const FixedColumnWidth(62),
        columnWidths: const {0: FixedColumnWidth(140)},
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.background),
            children: [for (final h in headers) _gridHeaderCell(h)],
          ),
          for (int i = 0; i < displayRows.length; i++)
            _charterGridRow(displayRows[i], isTotal: showOverall && i == displayRows.length - 1),
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

  // ---------- Shared: Ratings Table (bordered grid) ----------

  Widget _ratingTable(List<OfficeReportBreakdown> rows) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('No data for this period.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    const dimLabels = {
      'responsiveness': 'Responsiveness',
      'reliability': 'Reliability',
      'accessFacilities': 'Access & Facilities',
      'communication': 'Communication',
      'costs': 'Costs',
      'integrity': 'Integrity',
      'assurance': 'Assurance',
      'outcome': 'Outcome',
    };

    final showOverall = rows.length > 1 && overall != null;
    final displayRows = [...rows, if (showOverall) overall!];

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
          for (int i = 0; i < displayRows.length; i++)
            _ratingGridRow(displayRows[i], dimLabels, isTotal: showOverall && i == displayRows.length - 1),
        ],
      ),
    );
  }

  TableRow _ratingGridRow(OfficeReportBreakdown b, Map<String, String> dimLabels, {bool isTotal = false}) {
    final style = TextStyle(fontSize: 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal);
    return TableRow(children: [
      _gridCell(isTotal ? 'OVERALL' : b.officeName, style),
      _gridCell('${b.numberOfCustomers}', style),
      for (final key in dimLabels.keys)
        _gridCell(b.dimensionMeans[key] == null ? '—' : b.dimensionMeans[key]!.toStringAsFixed(2), style),
      _gridCell(b.meanSatisfaction == null ? '—' : b.meanSatisfaction!.toStringAsFixed(2), style.copyWith(fontWeight: FontWeight.bold)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(b.description, style: const TextStyle(fontSize: 10, color: AppColors.success)),
          ),
        ),
      ),
    ]);
  }

  // ---------- CSF Summary Report: full commendations & suggestions table ----------

  Widget _simpleCommendationsSection(List<OfficeReportBreakdown> rows) {
    final withContent = rows.where((b) => b.commendations.isNotEmpty || b.suggestions.isNotEmpty).toList();
    if (withContent.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No commendations or suggestions this period.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    const statusOptions = ['Implemented (Closed)', 'On-going / To be Implemented (Open)', 'Not Implemented'];

    return Table(
      border: TableBorder.all(color: const Color(0xFFE0E0E0)),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1.6),
        2: FlexColumnWidth(1.4),
        3: FlexColumnWidth(1.2),
        4: FlexColumnWidth(1.4),
        5: FlexColumnWidth(1.2),
        6: FlexColumnWidth(1.6),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.background),
          children: [
            _commHeaderCell('Office'),
            _commHeaderCell('Commendations'),
            _commHeaderCell('Detail of Suggestions'),
            _commHeaderCell('Root Cause'),
            _commHeaderCell('Action Plan'),
            _commHeaderCell('Target of Implementation'),
            _commHeaderCell('Status of Implementation'),
          ],
        ),
        for (final b in withContent) _fullCommendationsRow(b, statusOptions),
      ],
    );
  }

  TableRow _fullCommendationsRow(OfficeReportBreakdown b, List<String> statusOptions) {
    final key = b.officeName;
    final detailCtrl = _ctrlFor(_detailSuggestionCtrls, key);
    final rootCauseCtrl = _ctrlFor(_rootCauseCtrls, key);
    final actionPlanCtrl = _ctrlFor(_actionPlanCtrls, key);
    final targetCtrl = _ctrlFor(_targetCtrls, key);
    _statusSelections.putIfAbsent(key, () => statusOptions.first);

    return TableRow(children: [
      _commTextCell(b.officeName, bold: true),
      _commListCell(b.commendations),
      _cardEditableCell(detailCtrl),
      _cardEditableCell(rootCauseCtrl),
      _cardEditableCell(actionPlanCtrl),
      _cardEditableCell(targetCtrl),
      Padding(
        padding: const EdgeInsets.all(8),
        child: StatefulBuilder(
          builder: (context, setLocalState) {
            return DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusSelections[key],
                isExpanded: true,
                style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                items: statusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 10.5))))
                    .toList(),
                onChanged: (v) => setLocalState(() => _statusSelections[key] = v!),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _commHeaderCell(String text) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
  );

  Widget _commTextCell(String text, {bool bold = false}) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w600 : FontWeight.normal),
    ),
  );

  Widget _commListCell(List<String> items) {
    final limited = items.take(3).toList();
    if (limited.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: Text('—', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < limited.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == limited.length - 1 ? 0 : 4),
              child: Text('${i + 1}. ${limited[i]}', style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  // ---------- Report Card: full manual-entry commendations table ----------

  Widget _reportCardCommendationsTable(OfficeReportBreakdown office) {
    const statusOptions = ['Implemented (Closed)', 'On-going / To be Implemented (Open)', 'Not Implemented'];

    final commendationsText = office.commendations.isEmpty
        ? '—'
        : office.commendations.take(3).toList().asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');

    final key = office.officeName;
    final detailCtrl = _ctrlFor(_detailSuggestionCtrls, key);
    final rootCauseCtrl = _ctrlFor(_rootCauseCtrls, key);
    final actionPlanCtrl = _ctrlFor(_actionPlanCtrls, key);
    final targetCtrl = _ctrlFor(_targetCtrls, key);
    _statusSelections.putIfAbsent(key, () => statusOptions.first);

    return Table(
      border: TableBorder.all(color: const Color(0xFFE0E0E0)),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1.6),
        2: FlexColumnWidth(1.4),
        3: FlexColumnWidth(1.2),
        4: FlexColumnWidth(1.4),
        5: FlexColumnWidth(1.2),
        6: FlexColumnWidth(1.6),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.background),
          children: [
            _cardHeaderCell('Office'),
            _cardHeaderCell('Commendations'),
            _cardHeaderCell('Detail of Suggestions'),
            _cardHeaderCell('Root Cause'),
            _cardHeaderCell('Action Plan'),
            _cardHeaderCell('Target of Implementation'),
            _cardHeaderCell('Status of Implementation'),
          ],
        ),
        TableRow(
          children: [
            _cardTextCell(office.officeName),
            _cardTextCell(commendationsText),
            _cardEditableCell(detailCtrl),
            _cardEditableCell(rootCauseCtrl),
            _cardEditableCell(actionPlanCtrl),
            _cardEditableCell(targetCtrl),
            Padding(
              padding: const EdgeInsets.all(8),
              child: StatefulBuilder(
                builder: (context, setLocalState) {
                  return DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusSelections[key],
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                      items: statusOptions
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 11))))
                          .toList(),
                      onChanged: (v) => setLocalState(() => _statusSelections[key] = v!),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cardHeaderCell(String text) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
  );

  Widget _cardTextCell(String text) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(text, style: const TextStyle(fontSize: 11.5)),
  );

  Widget _cardEditableCell(TextEditingController controller) => Padding(
    padding: const EdgeInsets.all(6),
    child: TextField(
      controller: controller,
      maxLines: 3,
      minLines: 1,
      style: const TextStyle(fontSize: 11.5),
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        hintText: 'Enter here...',
        hintStyle: TextStyle(fontSize: 10.5),
      ),
    ),
  );

  // ---------- Submitted Reports history ----------

  Widget _submittedReportsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('submitted_reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: AppDecorations.card(),
            child: Text('Unable to load submitted reports: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final docs = snapshot.data!.docs;
        final reports = docs.map((doc) {
          return MapEntry(doc, ReportModel.fromMap(
            doc.id,
            doc.data() as Map<String, dynamic>,
          ));
        }).toList();

        final years = <int>{
          for (int y = DateTime.now().year; y >= DateTime.now().year - 5; y--) y,
          ...reports.map((entry) => entry.value.reportYear),
        }.toList()..sort((a, b) => b.compareTo(a));
        final offices = <String>{
          for (final entry in reports)
            for (final breakdown in entry.value.officeBreakdowns)
              if (breakdown.officeName.trim().isNotEmpty)
                breakdown.officeName.trim(),
        }.toList()..sort();

        final filtered = reports.where((entry) {
          final report = entry.value;
          if (_submittedYear != 0 && report.reportYear != _submittedYear) {
            return false;
          }
          if (_submittedMonth != 0 && report.reportMonth != _submittedMonth) {
            return false;
          }
          if (_submittedStatus != 'All Statuses' &&
              report.status != _submittedStatus) {
            return false;
          }
          if (_submittedOffice != 'All Offices' &&
              !report.officeBreakdowns.any(
                    (b) => b.officeName.trim() == _submittedOffice,
              )) {
            return false;
          }
          final keyword = _submittedSearch.trim().toLowerCase();
          if (keyword.isNotEmpty) {
            final officeNames = report.officeBreakdowns
                .map((b) => b.officeName)
                .join(' ');
            final haystack = '${report.reportTitle} $officeNames ${report.reportNotes}'
                .toLowerCase();
            if (!haystack.contains(keyword)) return false;
          }
          return true;
        }).toList();

        final pageCount = (filtered.length / _submittedReportsPerPage).ceil();
        final currentPage = pageCount == 0
            ? 0
            : _submittedPage.clamp(0, pageCount - 1).toInt();
        final startIndex = currentPage * _submittedReportsPerPage;
        final endIndex = (startIndex + _submittedReportsPerPage) > filtered.length
            ? filtered.length
            : startIndex + _submittedReportsPerPage;
        final pageReports = filtered.sublist(startIndex, endIndex);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.adminPanel(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list_rounded,
                          color: AppColors.primary, size: 19),
                      const SizedBox(width: 8),
                      const Text('Filter Submitted Reports',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const Spacer(),
                      Text('${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        child: TextField(
                          controller: _submittedSearchController,
                          onChanged: (value) => setState(() {
                            _submittedSearch = value;
                            _submittedPage = 0;
                          }),
                          decoration: InputDecoration(
                            hintText: 'Search title, office, notes...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
                            suffixIcon: _submittedSearch.isEmpty
                                ? null
                                : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _submittedSearchController.clear();
                                setState(() {
                                  _submittedSearch = '';
                                  _submittedPage = 0;
                                });
                              },
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      _dropdown<int>(
                        value: _submittedYear,
                        items: [0, ...years.where((y) => y != 0)],
                        labelBuilder: (y) => y == 0 ? 'All Years' : '$y',
                        onChanged: (v) => setState(() { _submittedYear = v ?? 0; _submittedPage = 0; }),
                      ),
                      _dropdown<int>(
                        value: _submittedMonth,
                        items: List<int>.generate(13, (i) => i),
                        labelBuilder: (m) => m == 0 ? 'All Months' : monthNames[m],
                        onChanged: (v) => setState(() { _submittedMonth = v ?? 0; _submittedPage = 0; }),
                      ),
                      _dropdown<String>(
                        value: _submittedOffice,
                        items: ['All Offices', ...offices],
                        labelBuilder: (office) => office,
                        onChanged: (v) => setState(() { _submittedOffice = v ?? 'All Offices'; _submittedPage = 0; }),
                      ),
                      _dropdown<String>(
                        value: _submittedStatus,
                        items: _submittedStatuses,
                        labelBuilder: (status) => status,
                        onChanged: (v) => setState(() { _submittedStatus = v ?? 'All Statuses'; _submittedPage = 0; }),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _submittedSearchController.clear();
                          setState(() {
                            _submittedSearch = '';
                            _submittedYear = 0;
                            _submittedMonth = 0;
                            _submittedOffice = 'All Offices';
                            _submittedStatus = 'All Statuses';
                            _submittedPage = 0;
                          });
                        },
                        icon: const Icon(Icons.restart_alt_rounded, size: 17),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: AppDecorations.card(),
              child: filtered.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    'No submitted reports match these filters.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
                  : Column(
                children: [
                  for (int i = 0; i < pageReports.length; i++)
                    _reportTile(
                      pageReports[i].key,
                      isLast: i == pageReports.length - 1,
                    ),
                ],
              ),
            ),
            if (filtered.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${startIndex + 1}–$endIndex of ${filtered.length} reports',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous page',
                        onPressed: currentPage > 0
                            ? () => setState(() => _submittedPage = currentPage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Text(
                        'Page ${currentPage + 1} of $pageCount',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        tooltip: 'Next page',
                        onPressed: currentPage < pageCount - 1
                            ? () => setState(() => _submittedPage = currentPage + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _reportTile(QueryDocumentSnapshot doc, {required bool isLast}) {
    final data = doc.data() as Map<String, dynamic>;
    final report = ReportModel.fromMap(doc.id, data);
    final officeLabel = report.officeBreakdowns.length == 1
        ? report.officeBreakdowns.first.officeName
        : '${report.officeBreakdowns.length} Office(s)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.reportTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  '${monthNames[report.reportMonth]} ${report.reportYear} • $officeLabel • ${report.totalFeedback} feedback entries',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(report.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              report.status,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(report.status)),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReportPreviewScreen(reportId: doc.id)),
              );
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}

