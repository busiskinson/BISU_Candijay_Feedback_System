import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/director_shell.dart';
import 'approved_report_view_screen.dart';

class DirectorDashboard extends StatefulWidget {
  const DirectorDashboard({super.key});

  @override
  State<DirectorDashboard> createState() => _DirectorDashboardState();
}

class _DirectorDashboardState extends State<DirectorDashboard> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = 0; // 0 means all months in the selected year

  static const monthNames = ['', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'];

  @override
  Widget build(BuildContext context) {
    return DirectorShell(
      title: 'Dashboard',
      selectedIndex: 0,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('submitted_reports')
            .where('status', isEqualTo: 'Approved')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(30),
              child: Text('Error loading reports: ${snapshot.error}', style: const TextStyle(color: AppColors.danger)),
            );
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }

          final docs = snapshot.data!.docs;
          final reports = docs.map((d) => ReportModel.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();
          final thisYearReports = reports.where((r) => r.reportYear == selectedYear).toList();
          final selectedPeriodReports = thisYearReports
              .where((r) => selectedMonth == 0 || r.reportMonth == selectedMonth)
              .toList();

          final Map<String, List<double>> officeRatings = {};
          for (final r in selectedPeriodReports) {
            for (final office in r.officeBreakdowns) {
              if (office.meanSatisfaction != null) {
                officeRatings.putIfAbsent(office.officeName, () => []).add(office.meanSatisfaction!);
              }
            }
          }
          final officePerformance = officeRatings.entries
              .map((e) => MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length))
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final totalFeedbackThisYear = selectedPeriodReports.fold<int>(0, (total, r) => total + r.totalFeedback);
          final ratedReports = selectedPeriodReports.where((r) => r.averageRating != null).toList();
          final avgRatingThisYear = ratedReports.isEmpty
              ? null
              : ratedReports.map((r) => r.averageRating!).reduce((a, b) => a + b) / ratedReports.length;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('CAMPUS DIRECTOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
                    const SizedBox(width: 8),
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success, letterSpacing: 0.6)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Campus Satisfaction Overview',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.4)),
                const SizedBox(height: 6),
                const Text('Monitor approved reports and satisfaction performance across BISU Candijay offices.',
                    style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                _yearMonthFilter(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _StatCard(icon: Icons.verified_rounded, color: AppColors.success, label: 'APPROVED REPORTS', value: '${selectedPeriodReports.length}')),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(icon: Icons.forum_rounded, color: AppColors.primary, label: 'TOTAL FEEDBACK COVERED', value: '$totalFeedbackThisYear')),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(icon: Icons.star_rounded, color: AppColors.accentDark, label: 'AVG. RATING', value: avgRatingThisYear == null ? '—' : avgRatingThisYear.toStringAsFixed(2))),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(icon: Icons.apartment_rounded, color: AppColors.secondary, label: 'OFFICES REPORTED', value: '${officePerformance.length}')),
                  ],
                ),
                const SizedBox(height: 20),
                _monthlyReportCard(thisYearReports),
                const SizedBox(height: 20),
                _officePerformanceCard(officePerformance),
                const SizedBox(height: 20),
                _recentApprovedCard(context, docs, selectedPeriodReports),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _yearMonthFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: AppDecorations.card(),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_month_rounded, size: 17, color: AppColors.primary),
          ),
          const Text('Year:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          _filterDropdown<int>(
            value: selectedYear,
            items: [for (int y = DateTime.now().year; y >= DateTime.now().year - 4; y--) y],
            labelBuilder: (year) => year == DateTime.now().year ? '$year (Current)' : '$year',
            onChanged: (value) => setState(() => selectedYear = value!),
          ),
          const Text('Month:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          _filterDropdown<int>(
            value: selectedMonth,
            items: [0, ...List.generate(12, (index) => index + 1)],
            labelBuilder: (month) => month == 0 ? 'All Months' : monthNames[month],
            onChanged: (value) => setState(() => selectedMonth = value!),
          ),
          if (selectedMonth != 0)
            TextButton.icon(
              onPressed: () => setState(() => selectedMonth = 0),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear month'),
            ),
        ],
      ),
    );
  }

  Widget _filterDropdown<T>({
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
              .map((item) => DropdownMenuItem<T>(
            value: item,
            child: Text(labelBuilder(item), style: const TextStyle(fontSize: 12.5)),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _monthlyReportCard(List<ReportModel> yearReports) {
    final countByMonth = List.filled(12, 0);
    for (final r in yearReports) {
      final m = r.reportMonth - 1;
      if (m >= 0 && m <= 11) countByMonth[m]++;
    }
    final maxY = countByMonth.fold<int>(0, (a, b) => a > b ? a : b).toDouble().clamp(4.0, double.infinity).toDouble();
    const monthShort = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    return Container(
      height: 300,
      padding: const EdgeInsets.all(22),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Report Trend — $selectedYear', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          const Text('Annual view: number of approved reports received in each month. Use the month filter above to view a single month in the summary cards and office rankings.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY + 1,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: (maxY / 4).ceilToDouble().clamp(1, double.infinity),
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFF0EDF5), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, m) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)))),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                    final i = v.toInt();
                    if (i < 0 || i > 11) return const SizedBox.shrink();
                    return Padding(padding: const EdgeInsets.only(top: 8), child: Text(monthShort[i], style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)));
                  })),
                ),
                barGroups: [
                  for (int i = 0; i < 12; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: countByMonth[i].toDouble(),
                        width: 16,
                        borderRadius: BorderRadius.circular(5),
                        color: AppColors.success,
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _officePerformanceCard(List<MapEntry<String, double>> officePerformance) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Office Performance — ${selectedMonth == 0 ? '$selectedYear (Annual)' : '${monthNames[selectedMonth]} $selectedYear'}', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          const Text('Average satisfaction rating per office, based on approved reports.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          if (officePerformance.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No approved reports with ratings for this year yet.', style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            for (int i = 0; i < officePerformance.length; i++) _officeBar(officePerformance[i].key, officePerformance[i].value, isTop: i == 0),
        ],
      ),
    );
  }

  Widget _officeBar(String office, double rating, {bool isTop = false}) {
    final fraction = rating / 5;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isTop) ...[
                const Icon(Icons.emoji_events_rounded, size: 15, color: AppColors.accentDark),
                const SizedBox(width: 6),
              ],
              Expanded(child: Text(office, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              Text(rating.toStringAsFixed(2), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppColors.background,
              color: isTop ? AppColors.accent : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentApprovedCard(BuildContext context, List<QueryDocumentSnapshot> docs, List<ReportModel> reports) {
    final recent = reports.take(6).toList();

    return Container(
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(selectedMonth == 0 ? 'Approved Reports for $selectedYear' : 'Approved Reports — ${monthNames[selectedMonth]} $selectedYear', style: AppTextStyles.sectionTitle),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/directorReports'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('No approved reports yet.', style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            for (int i = 0; i < recent.length; i++)
              _reportTile(context, recent[i], docs.firstWhere((d) => d.id == recent[i].id).id, isLast: i == recent.length - 1),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _reportTile(BuildContext context, ReportModel report, String docId, {required bool isLast}) {
    final officeLabel = report.officeBreakdowns.length == 1
        ? report.officeBreakdowns.first.officeName
        : '${report.officeBreakdowns.length} Office(s)';

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ApprovedReportViewScreen(reportId: docId)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF2F2F2)))),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.reportTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text('${monthNames[report.reportMonth]} ${report.reportYear} • $officeLabel',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
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

  const _StatCard({required this.icon, required this.color, required this.label, required this.value});

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
        transform: _hovering ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: _hovering ? 0.12 : 0.06),
              blurRadius: _hovering ? 18 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3)),
              Container(width: 32, height: 32, decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
                  child: Icon(widget.icon, color: widget.color, size: 16)),
            ]),
            const SizedBox(height: 12),
            Text(widget.value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
