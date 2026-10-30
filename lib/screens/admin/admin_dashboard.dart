import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/admin_shell.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int? _hoveredRow;
  int selectedYear = DateTime.now().year;
  String selectedMonth = _monthName(DateTime.now().month);

  static const List<String> monthNames = [
    'All Months',
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

  static const List<String> dimensionKeys = [
    'responsiveness',
    'reliability',
    'accessFacilities',
    'communication',
    'costs',
    'integrity',
    'assurance',
    'outcome',
  ];

  static const List<String> dimensionShortLabels = [
    'Responsiveness',
    'Reliability',
    'Access & Facilities',
    'Communication',
    'Costs',
    'Integrity',
    'Assurance',
    'Outcome',
  ];

  static String _monthName(int month) => monthNames[month];

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Dashboard',
      selectedIndex: 0,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('feedback').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final allDocs = snapshot.data!.docs;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pageHeader(),
                const SizedBox(height: 20),
                _filterToolbar(),
                const SizedBox(height: 20),
                _statCardsRow(allDocs),
                const SizedBox(height: 20),
                _annualSummaryCard(allDocs),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _monthlyTrendCard(allDocs)),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _serviceDimensionsCard(allDocs)),
                  ],
                ),
                const SizedBox(height: 20),
                _recentFeedbackCard(allDocs),
                const SizedBox(height: 28),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- Page Header ----------

  Widget _pageHeader() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
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
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour12:${now.minute.toString().padLeft(2, '0')} $ampm';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'DASHBOARD',
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
                  Text(
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
                'Feedback & Service Quality Overview',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Monitor customer satisfaction, complaints, and service performance across BISU Candijay offices.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: AppDecorations.card(radius: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${months[now.month]} ${now.day}, ${now.year}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${weekdays[now.weekday - 1]}, $timeStr',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Filter Toolbar ----------

  Widget _filterToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: AppDecorations.adminPanel(),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 17,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          _dropdown<int>(
            value: selectedYear,
            items: [
              for (
                int y = DateTime.now().year;
                y >= DateTime.now().year - 4;
                y--
              )
                y,
            ],
            labelBuilder: (y) =>
                y == DateTime.now().year ? '$y (Current)' : '$y',
            onChanged: (v) => setState(() => selectedYear = v!),
          ),
          const SizedBox(width: 10),
          _dropdown<String>(
            value: selectedMonth,
            items: monthNames,
            labelBuilder: (m) => m,
            onChanged: (v) => setState(() => selectedMonth = v!),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() {
              selectedYear = DateTime.now().year;
              selectedMonth = _monthName(DateTime.now().month);
            }),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items
              .map(
                (o) => DropdownMenuItem(
                  value: o,
                  child: Text(
                    labelBuilder(o),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ---------- Data helpers ----------

  List<Map<String, dynamic>> _docsFor(
    List<QueryDocumentSnapshot> docs,
    int year, {
    String month = 'All Months',
  }) {
    return docs.map((d) => d.data() as Map<String, dynamic>).where((data) {
      final ts = data['createdAt'] as Timestamp?;
      if (ts == null) return false;
      final date = ts.toDate();
      if (date.year != year) return false;
      if (month != 'All Months' && monthNames.indexOf(month) != date.month) {
        return false;
      }
      return true;
    }).toList();
  }

  Map<String, dynamic> _summaryFor(List<Map<String, dynamic>> entries) {
    final total = entries.length;
    final satisfaction = entries
        .where((e) => e['feedbackType'] == 'satisfaction')
        .length;
    final complaints = entries
        .where((e) => e['feedbackType'] == 'complaint')
        .length;
    final resolved = entries
        .where((e) => (e['status'] ?? 'Submitted') == 'Resolved')
        .length;

    final List<int> scores = [];
    for (final e in entries) {
      if (e['feedbackType'] != 'satisfaction') continue;
      final details = e['satisfactionDetails'] as Map<String, dynamic>?;
      if (details == null) continue;
      for (final key in dimensionKeys) {
        final v = details[key];
        if (v is int && v != 6) scores.add(v);
      }
    }

    double? avgStars;
    double? satisfactionRate;
    if (scores.isNotEmpty) {
      final avgCode = scores.reduce((a, b) => a + b) / scores.length;
      avgStars = 6 - avgCode;
      final satisfiedCount = scores.where((v) => v == 1 || v == 2).length;
      satisfactionRate = (satisfiedCount / scores.length) * 100;
    }

    return {
      'total': total,
      'satisfaction': satisfaction,
      'complaints': complaints,
      'resolved': resolved,
      'avgStars': avgStars,
      'satisfactionRate': satisfactionRate,
    };
  }

  /// Returns the previous period (year/month) relative to current selection.
  (int, String) _previousPeriod() {
    if (selectedMonth == 'All Months') {
      return (selectedYear - 1, 'All Months');
    }
    final monthIndex = monthNames.indexOf(selectedMonth); // 1-12
    if (monthIndex == 1) return (selectedYear - 1, monthNames[12]);
    return (selectedYear, monthNames[monthIndex - 1]);
  }

  String _deltaLabel(int current, int previous) {
    if (previous == 0) return current == 0 ? 'No change' : 'New activity';
    final pct = ((current - previous) / previous) * 100;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(0)}% vs previous period';
  }

  // ---------- Stat Cards ----------

  Widget _statCardsRow(List<QueryDocumentSnapshot> allDocs) {
    final entries = _docsFor(allDocs, selectedYear, month: selectedMonth);
    final s = _summaryFor(entries);
    final avgStars = s['avgStars'] as double?;
    final rate = s['satisfactionRate'] as double?;

    final (prevYear, prevMonth) = _previousPeriod();
    final prevEntries = _docsFor(allDocs, prevYear, month: prevMonth);
    final prevSummary = _summaryFor(prevEntries);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.forum_rounded,
            color: AppColors.primary,
            label: 'TOTAL FEEDBACK',
            value: '${s['total']}',
            delta: _deltaLabel(s['total'] as int, prevSummary['total'] as int),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.sentiment_satisfied_alt_rounded,
            color: AppColors.success,
            label: 'SATISFACTION',
            value: '${s['satisfaction']}',
            delta: rate == null
                ? 'No ratings yet'
                : '${rate.toStringAsFixed(0)}% satisfaction rate',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.report_problem_rounded,
            color: AppColors.danger,
            label: 'COMPLAINTS',
            value: '${s['complaints']}',
            delta: _deltaLabel(
              s['complaints'] as int,
              prevSummary['complaints'] as int,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            color: AppColors.accentDark,
            label: 'AVERAGE RATING',
            value: avgStars == null ? '—' : avgStars.toStringAsFixed(1),
            delta: avgStars == null ? 'No ratings yet' : 'out of 5.0',
          ),
        ),
      ],
    );
  }

  // ---------- Annual Summary ----------

  Widget _annualSummaryCard(List<QueryDocumentSnapshot> allDocs) {
    final entries = _docsFor(allDocs, selectedYear);
    final summary = _summaryFor(entries);
    final rate = summary['satisfactionRate'] as double?;
    final avgStars = summary['avgStars'] as double?;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppDecorations.adminPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Annual Feedback Summary — $selectedYear',
                style: AppTextStyles.sectionTitle,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _summaryMetric(
                'Total Feedback',
                '${summary['total']}',
                AppColors.primary,
              ),
              _summaryDivider(),
              _summaryMetric(
                'Satisfaction',
                '${summary['satisfaction']}',
                AppColors.success,
              ),
              _summaryDivider(),
              _summaryMetric(
                'Complaints',
                '${summary['complaints']}',
                AppColors.danger,
              ),
              _summaryDivider(),
              _summaryMetric(
                'Resolved',
                '${summary['resolved']}',
                AppColors.accentDark,
              ),
              _summaryDivider(),
              _summaryMetric(
                'Avg. Rating',
                avgStars == null ? '—' : avgStars.toStringAsFixed(2),
                AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Satisfaction Rate',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                rate == null ? '—' : '${rate.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate == null ? 0 : (rate / 100).clamp(0, 1),
              minHeight: 9,
              backgroundColor: AppColors.background,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() => Container(
    width: 1,
    height: 40,
    color: const Color(0xFFEDEAF2),
    margin: const EdgeInsets.symmetric(horizontal: 18),
  );

  Widget _summaryMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Monthly Trend Chart ----------

  Widget _monthlyTrendCard(List<QueryDocumentSnapshot> allDocs) {
    final entries = _docsFor(allDocs, selectedYear);

    final List<int> satisfactionByMonth = List.filled(12, 0);
    final List<int> complaintsByMonth = List.filled(12, 0);

    for (final e in entries) {
      final ts = e['createdAt'] as Timestamp?;
      if (ts == null) continue;
      final m = ts.toDate().month - 1;
      if (e['feedbackType'] == 'satisfaction') {
        satisfactionByMonth[m]++;
      } else if (e['feedbackType'] == 'complaint') {
        complaintsByMonth[m]++;
      }
    }

    final maxY = ([...satisfactionByMonth, ...complaintsByMonth].fold<int>(
      0,
      (a, b) => a > b ? a : b,
    )).toDouble().clamp(5.0, double.infinity).toDouble();

    const monthShort = [
      'J',
      'F',
      'M',
      'A',
      'M',
      'J',
      'J',
      'A',
      'S',
      'O',
      'N',
      'D',
    ];

    return Container(
      height: 320,
      padding: const EdgeInsets.all(22),
      decoration: AppDecorations.adminPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Trend — $selectedYear',
                style: AppTextStyles.sectionTitle,
              ),
              Row(
                children: [
                  _legendDot(AppColors.success, 'Satisfaction'),
                  const SizedBox(width: 16),
                  _legendDot(AppColors.danger, 'Complaints'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: (maxY / 5).ceilToDouble().clamp(
                    1,
                    double.infinity,
                  ),
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: const Color(0xFFF0EDF5), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => AppColors.primary,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}',
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
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i > 11) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            monthShort[i],
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
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < 12; i++)
                        FlSpot(i.toDouble(), satisfactionByMonth[i].toDouble()),
                    ],
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 2.6,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.success.withValues(alpha: 0.07),
                    ),
                  ),
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < 12; i++)
                        FlSpot(i.toDouble(), complaintsByMonth[i].toDouble()),
                    ],
                    isCurved: true,
                    color: AppColors.danger,
                    barWidth: 2.6,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

  // ---------- Service Dimensions ----------

  Widget _serviceDimensionsCard(List<QueryDocumentSnapshot> allDocs) {
    final entries = _docsFor(allDocs, selectedYear, month: selectedMonth);

    final List<double?> dimensionAverages = [];
    for (final key in dimensionKeys) {
      final List<int> scores = [];
      for (final e in entries) {
        if (e['feedbackType'] != 'satisfaction') continue;
        final details = e['satisfactionDetails'] as Map<String, dynamic>?;
        final v = details?[key];
        if (v is int && v != 6) scores.add(v);
      }
      if (scores.isEmpty) {
        dimensionAverages.add(null);
      } else {
        final avgCode = scores.reduce((a, b) => a + b) / scores.length;
        dimensionAverages.add(6 - avgCode);
      }
    }

    final scopeLabel = selectedMonth == 'All Months'
        ? '$selectedYear'
        : '$selectedMonth $selectedYear';

    return Container(
      height: 320,
      padding: const EdgeInsets.all(22),
      decoration: AppDecorations.adminPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Service Dimensions', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          Text(
            scopeLabel,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: dimensionKeys.length,
              itemBuilder: (context, i) => _dimensionBar(
                dimensionShortLabels[i],
                dimensionAverages[i],
                isLast: i == dimensionKeys.length - 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dimensionBar(String label, double? value, {bool isLast = false}) {
    final fraction = (value ?? 0) / 5;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                value == null ? '—' : value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColors.background,
              color: label == 'Outcome' ? AppColors.accent : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Recent Feedback ----------

  Widget _recentFeedbackCard(List<QueryDocumentSnapshot> allDocs) {
    final sorted = List<QueryDocumentSnapshot>.from(allDocs)
      ..sort((a, b) {
        final ta =
            ((a.data() as Map)['createdAt'] as Timestamp?)?.toDate() ??
            DateTime(2000);
        final tb =
            ((b.data() as Map)['createdAt'] as Timestamp?)?.toDate() ??
            DateTime(2000);
        return tb.compareTo(ta);
      });
    final recent = sorted.take(6).toList();

    return Container(
      decoration: AppDecorations.adminPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Feedback', style: AppTextStyles.sectionTitle),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/adminFeedback'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          if (recent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Row(
                children: const [
                  SizedBox(width: 68),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'TYPE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'RATING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'SENTIMENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'DATE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'STATUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 36,
                      color: Color(0xFFCFC9DC),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No feedback available yet.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (int i = 0; i < recent.length; i++)
              _recentRow(recent[i], index: i, isLast: i == recent.length - 1),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _recentRow(
    QueryDocumentSnapshot doc, {
    required int index,
    required bool isLast,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final isComplaint = data['feedbackType'] == 'complaint';
    final status = data['status'] ?? 'Submitted';
    final ts = data['createdAt'] as Timestamp?;
    final dateStr = ts == null
        ? '—'
        : '${ts.toDate().month}/${ts.toDate().day}/${ts.toDate().year}';

    double? meanRating;
    if (!isComplaint) {
      final details = data['satisfactionDetails'] as Map<String, dynamic>?;
      if (details != null) {
        final scores = <int>[];
        for (final key in dimensionKeys) {
          final v = details[key];
          if (v is int && v != 6) {
            scores.add(v);
          }
        }
        if (scores.isNotEmpty) {
          meanRating = 6 - (scores.reduce((a, b) => a + b) / scores.length);
        }
      }
    }

    String sentiment;
    Color sentimentColor;
    if (isComplaint) {
      sentiment = 'Negative';
      sentimentColor = AppColors.danger;
    } else if (meanRating == null) {
      sentiment = 'Neutral';
      sentimentColor = Colors.blueGrey;
    } else if (meanRating >= 4) {
      sentiment = 'Positive';
      sentimentColor = AppColors.success;
    } else if (meanRating >= 3) {
      sentiment = 'Neutral';
      sentimentColor = Colors.blueGrey;
    } else {
      sentiment = 'Negative';
      sentimentColor = AppColors.danger;
    }

    Color statusColor;
    switch (status) {
      case 'Resolved':
        statusColor = AppColors.success;
        break;
      case 'Under Review':
        statusColor = AppColors.primary;
        break;
      case 'Archived':
        statusColor = Colors.blueGrey;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRow = index),
      onExit: (_) => setState(() => _hoveredRow = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: _hoveredRow == index
              ? AppColors.background
              : Colors.transparent,
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFF3F1F7))),
        ),
        child: Row(
          children: [
            Text(
              '#${doc.id.substring(0, 6).toUpperCase()}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(
                    isComplaint
                        ? Icons.report_problem_rounded
                        : Icons.sentiment_satisfied_alt_rounded,
                    size: 15,
                    color: isComplaint ? AppColors.danger : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isComplaint ? 'Complaint' : 'Satisfaction',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Expanded(
              child: meanRating == null
                  ? const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.accentDark,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          meanRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
            Expanded(child: _badge(sentiment, sentimentColor)),
            Expanded(
              child: Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(child: _badge(status, statusColor)),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
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
  final String delta;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.delta,
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
            ? (Matrix4.identity()..translateByDouble(0.0, -2.0, 0.0, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: _hovering ? 0.10 : 0.05),
              blurRadius: _hovering ? 22 : 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.4,
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
            const SizedBox(height: 6),
            Text(
              widget.delta,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
