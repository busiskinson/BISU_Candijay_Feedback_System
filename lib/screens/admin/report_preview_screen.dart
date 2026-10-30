import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/report_html_generator.dart';
import '../../utils/report_print.dart';
import '../../utils/signatory_lookup.dart';
import '../../widgets/admin_shell.dart';
import '../../widgets/official_letterhead.dart';

class ReportPreviewScreen extends StatefulWidget {
  final String reportId;

  const ReportPreviewScreen({super.key, required this.reportId});

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  static const monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const reportTypes = ['CSF Summary Report', 'Monthly Report Card'];

  String reportType = 'CSF Summary Report';
  String officeFilter = 'All Offices';

  bool isLoading = true;
  ReportModel? report;

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
  void didUpdateWidget(covariant ReportPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reportId != widget.reportId) {
      _load();
    }
  }

  @override
  void dispose() {
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
    if (mounted) {
      setState(() {
        isLoading = true;
        report = null;
      });
    } else {
      isLoading = true;
      report = null;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('submitted_reports')
          .doc(widget.reportId)
          .get();

      if (!mounted) return;

      final data = doc.data();
      final loadedReport = data == null ? null : ReportModel.fromMap(doc.id, data);
      final names = (loadedReport?.officeBreakdowns ?? [])
          .map((b) => b.officeName.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        report = loadedReport;
        // A report for another month can contain a different set of offices.
        // Never keep a selection from the previously opened report.
        if (reportType == 'Monthly Report Card') {
          officeFilter = names.isNotEmpty ? names.first : 'All Offices';
        } else if (officeFilter != 'All Offices' && !names.contains(officeFilter)) {
          officeFilter = 'All Offices';
        }
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      rethrow;
    }
  }

  Future<void> _printReport() async {
    if (report == null) return;

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

    // "Prepared" = the admin who submitted this report;
    // "Verified" = QA Director; "Approved" = Campus Director.
    final signatories = await SignatoryLookup.fetch(preparedByUid: report!.submittedBy);

    final html = await ReportHtmlGenerator.build(
      reportType: reportType,
      year: report!.reportYear,
      month: report!.reportMonth,
      breakdowns: _displayBreakdowns,
      overall: report!.overallBreakdown,
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

  List<OfficeReportBreakdown> get _allBreakdowns => report?.officeBreakdowns ?? [];

  List<OfficeReportBreakdown> get _displayBreakdowns {
    if (officeFilter == 'All Offices') return _allBreakdowns;
    return _allBreakdowns
        .where((b) => b.officeName.trim() == officeFilter)
        .toList();
  }

  // Keep office dropdown values unique and remove blank names. Duplicate names
  // can cause Flutter's DropdownButton assertion to fail.
  List<String> _officeNames() {
    final names = _allBreakdowns
        .map((b) => b.officeName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    names.sort();
    return names;
  }

  TextEditingController _ctrlFor(Map<String, TextEditingController> map, String key) {
    return map.putIfAbsent(key, () => TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Report Preview',
      selectedIndex: 3,
      body: isLoading
          ? const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      )
          : report == null
          ? const Padding(
        padding: EdgeInsets.all(30),
        child: Text('Report not found.', style: TextStyle(color: AppColors.textSecondary)),
      )
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
                    child: reportType == 'CSF Summary Report'
                        ? _summaryReportBody()
                        : _reportCardBody(),
                  ),
                ],
              ),
            ),
          ),
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
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            '${report!.reportTitle} — ${monthNames[report!.reportMonth]} ${report!.reportYear}',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          _smallLabel('Report:'),
          _dropdown<String>(
            value: reportType,
            items: reportTypes,
            labelBuilder: (t) => t,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                reportType = value;
                final offices = _officeNames();

                if (reportType == 'Monthly Report Card') {
                  officeFilter = offices.isNotEmpty
                      ? offices.first
                      : 'All Offices';
                } else if (officeFilter != 'All Offices' &&
                    !offices.contains(officeFilter)) {
                  officeFilter = 'All Offices';
                }
              });
            },
          ),
          _smallLabel('Office:'),
          _builderOfficeDropdown(),
          ElevatedButton.icon(
            onPressed: _printReport,
            icon: const Icon(Icons.print_rounded, size: 17),
            label: const Text('Print'),
            style: AppDecorations.primaryButton(),
          ),
        ],
      ),
    );
  }

  Widget _builderOfficeDropdown() {
    final offices = _officeNames();
    final items = <String>[
      if (reportType == 'CSF Summary Report' || offices.isEmpty) 'All Offices',
      ...offices,
    ].toSet().toList();

    // DropdownButton.value must match exactly one item in items.
    final selectedOffice = items.contains(officeFilter)
        ? officeFilter
        : items.first;

    return _dropdown<String>(
      value: selectedOffice,
      items: items,
      labelBuilder: (office) => office,
      onChanged: (value) {
        if (value == null) return;
        setState(() => officeFilter = value);
      },
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
    // DropdownButton requires its selected value to occur exactly once.
    // Deduplicate items and fall back to the first valid item if a report/month
    // change leaves the previous selection unavailable.
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
            child: Text('Month: ${monthNames[report!.reportMonth]} ${report!.reportYear}',
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
            Text('Month: ${monthNames[report!.reportMonth]} ${report!.reportYear}',
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

    final showOverall = rows.length > 1 && report!.overallBreakdown != null;
    final displayRows = [...rows, if (showOverall) report!.overallBreakdown!];

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
        1: FlexColumnWidth(1.4),
        2: FlexColumnWidth(1.4),
        3: FlexColumnWidth(1.4),
        4: FlexColumnWidth(1.2),
        5: FlexColumnWidth(1.3),
        6: FlexColumnWidth(1.2),
        7: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.background),
          children: [
            _commHeaderCell('Office'),
            _commHeaderCell('Commendations'),
            _commHeaderCell('Suggestions'),
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
      _commListCell(b.suggestions),
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
            _cardHeaderCell('Suggestions'),
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
            _cardTextCell(office.suggestions.isEmpty
                ? '—'
                : office.suggestions.take(3).toList().asMap().entries
                .map((e) => '${e.key + 1}. ${e.value}').join('\\n')),
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
}
