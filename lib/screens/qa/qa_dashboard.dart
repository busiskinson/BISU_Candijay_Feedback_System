import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/report_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/qa_shell.dart';
import 'qa_report_review_screen.dart';

class QaDashboard extends StatefulWidget {
  const QaDashboard({super.key});

  @override
  State<QaDashboard> createState() => _QaDashboardState();
}

class _QaDashboardState extends State<QaDashboard> {
  int selectedYear = DateTime.now().year;
  // 0 means All Months.
  int selectedMonth = 0;

  static const List<String> monthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    return QaShell(
      title: 'Dashboard',
      selectedIndex: 0,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('submitted_reports')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, reportSnapshot) {
          if (reportSnapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Unable to load reports. Please try again.'),
              ),
            );
          }

          if (!reportSnapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            );
          }

          final reportDocs = reportSnapshot.data!.docs;

          // Keep each Firestore document paired with its parsed report.
          // This ensures navigation always uses the non-null Firestore ID,
          // instead of a possibly nullable ID property in ReportModel.
          final reportEntries = reportDocs.map((document) {
            final report = ReportModel.fromMap(
              document.id,
              document.data(),
            );
            return MapEntry(document, report);
          }).toList();

          final allReports = reportEntries.map((entry) => entry.value).toList();

          final filteredEntries = reportEntries.where((entry) {
            final report = entry.value;
            final matchesYear = report.reportYear == selectedYear;
            final matchesMonth =
                selectedMonth == 0 || report.reportMonth == selectedMonth;
            return matchesYear && matchesMonth;
          }).toList();

          final filteredReports =
          filteredEntries.map((entry) => entry.value).toList();

          final pendingEntries = filteredEntries
              .where((entry) => entry.value.status == 'Pending Review')
              .toList();

          final approved = filteredReports
              .where((report) => report.status == 'Approved')
              .length;
          final rejected = filteredReports
              .where((report) => report.status == 'Rejected')
              .length;
          final returned = filteredReports
              .where((report) => report.status == 'Returned for Revision')
              .length;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'QA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Report Review Overview',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Review submitted reports and approve, reject, or return them for revision.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 700;
                    final cardWidth = isNarrow
                        ? (constraints.maxWidth - 16) / 2
                        : (constraints.maxWidth - 48) / 4;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _StatCard(
                            icon: Icons.hourglass_top_rounded,
                            color: AppColors.warning,
                            label: 'PENDING REVIEW',
                            value: '${pendingEntries.length}',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _StatCard(
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                            label: 'APPROVED',
                            value: '$approved',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _StatCard(
                            icon: Icons.cancel_rounded,
                            color: AppColors.danger,
                            label: 'REJECTED',
                            value: '$rejected',
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _StatCard(
                            icon: Icons.undo_rounded,
                            color: AppColors.primary,
                            label: 'RETURNED',
                            value: '$returned',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _yearFilter(),
                const SizedBox(height: 20),
                _monthlyReportActivityCard(allReports),
                const SizedBox(height: 24),

                Container(
                  decoration: AppDecorations.card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reports Awaiting Review',
                              style: AppTextStyles.sectionTitle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedMonth == 0
                                  ? 'Showing reports for $selectedYear'
                                  : 'Showing reports for ${monthNames[selectedMonth]} $selectedYear',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (pendingEntries.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(30),
                          child: Center(
                            child: Text(
                              'No reports awaiting review for this period.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        for (int i = 0; i < pendingEntries.length; i++)
                          _reportTile(
                            context,
                            pendingEntries[i].value,
                            pendingEntries[i].key.id,
                            isLast: i == pendingEntries.length - 1,
                          ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _yearFilter() {
    final currentYear = DateTime.now().year;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: AppDecorations.card(),
      child: Wrap(
        spacing: 20,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Year:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedYear,
                    items: [
                      for (int year = currentYear;
                      year >= currentYear - 4;
                      year--)
                        DropdownMenuItem<int>(
                          value: year,
                          child: Text(
                            year == currentYear ? '$year (Current)' : '$year',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedYear = value);
                    },
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Month:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedMonth,
                    items: [
                      const DropdownMenuItem<int>(
                        value: 0,
                        child: Text(
                          'All Months',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                      for (int month = 1; month <= 12; month++)
                        DropdownMenuItem<int>(
                          value: month,
                          child: Text(
                            monthNames[month],
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedMonth = value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthlyReportActivityCard(List<ReportModel> reports) {
    final yearReports = reports
        .where((report) => report.reportYear == selectedYear)
        .toList();

    final approvedByMonth = List<int>.filled(12, 0);
    final rejectedByMonth = List<int>.filled(12, 0);
    final returnedByMonth = List<int>.filled(12, 0);
    final pendingByMonth = List<int>.filled(12, 0);

    for (final report in yearReports) {
      final monthIndex = report.reportMonth - 1;
      if (monthIndex < 0 || monthIndex > 11) continue;

      switch (report.status) {
        case 'Approved':
          approvedByMonth[monthIndex]++;
          break;
        case 'Rejected':
          rejectedByMonth[monthIndex]++;
          break;
        case 'Returned for Revision':
          returnedByMonth[monthIndex]++;
          break;
        case 'Pending Review':
          pendingByMonth[monthIndex]++;
          break;
      }
    }

    const monthShort = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final chartMonths = selectedMonth == 0
        ? List<int>.generate(12, (index) => index)
        : <int>[selectedMonth - 1];

    final totals = chartMonths.map((index) {
      return approvedByMonth[index] +
          rejectedByMonth[index] +
          returnedByMonth[index] +
          pendingByMonth[index];
    }).toList();

    final largestTotal = totals.fold<int>(
      0,
          (largest, total) => total > largest ? total : largest,
    );
    final maxY = (largestTotal + 1).toDouble().clamp(4.0, double.infinity);

    final chartTitle = selectedMonth == 0
        ? 'Monthly Report Activity — $selectedYear'
        : 'Report Activity — ${monthNames[selectedMonth]} $selectedYear';

    return Container(
      height: 340,
      padding: const EdgeInsets.all(22),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(chartTitle, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _legendDot(AppColors.success, 'Approved'),
              _legendDot(AppColors.danger, 'Rejected'),
              _legendDot(AppColors.warning, 'Returned'),
              _legendDot(AppColors.primary, 'Pending'),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval:
                  (maxY / 4).ceilToDouble().clamp(1.0, double.infinity),
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFF0EDF5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final position = value.toInt();
                        if (position < 0 || position >= chartMonths.length) {
                          return const SizedBox.shrink();
                        }
                        final monthIndex = chartMonths[position];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            monthShort[monthIndex],
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int position = 0; position < chartMonths.length; position++)
                    _buildBarGroup(
                      position: position,
                      approved: approvedByMonth[chartMonths[position]],
                      rejected: rejectedByMonth[chartMonths[position]],
                      returned: returnedByMonth[chartMonths[position]],
                      pending: pendingByMonth[chartMonths[position]],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup({
    required int position,
    required int approved,
    required int rejected,
    required int returned,
    required int pending,
  }) {
    final approvedEnd = approved.toDouble();
    final rejectedEnd = approvedEnd + rejected;
    final returnedEnd = rejectedEnd + returned;
    final pendingEnd = returnedEnd + pending;

    return BarChartGroupData(
      x: position,
      barRods: [
        BarChartRodData(
          toY: pendingEnd,
          width: selectedMonth == 0 ? 14 : 36,
          borderRadius: BorderRadius.circular(4),
          rodStackItems: [
            BarChartRodStackItem(0, approvedEnd, AppColors.success),
            BarChartRodStackItem(approvedEnd, rejectedEnd, AppColors.danger),
            BarChartRodStackItem(rejectedEnd, returnedEnd, AppColors.warning),
            BarChartRodStackItem(returnedEnd, pendingEnd, AppColors.primary),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _reportTile(
      BuildContext context,
      ReportModel report,
      String docId, {
        required bool isLast,
      }) {
    final officeLabel = report.officeBreakdowns.length == 1
        ? report.officeBreakdowns.first.officeName
        : '${report.officeBreakdowns.length} Office(s)';

    final validMonth = report.reportMonth >= 1 && report.reportMonth <= 12;
    final monthLabel = validMonth
        ? monthNames[report.reportMonth]
        : 'Unknown Month';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QaReportReviewScreen(reportId: docId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
            bottom: BorderSide(color: Color(0xFFF2F2F2)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.reportTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$monthLabel ${report.reportYear} • $officeLabel • '
                        '${report.totalFeedback} feedback entries',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        transform: _hovering
            ? (Matrix4.identity()..translate(0.0, -2.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(
                alpha: _hovering ? 0.12 : 0.06,
              ),
              blurRadius: _hovering ? 18 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

