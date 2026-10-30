import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class SatisfactionTrendChart extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;

  const SatisfactionTrendChart({super.key, required this.docs});

  @override
  State<SatisfactionTrendChart> createState() =>
      _SatisfactionTrendChartState();
}

class _SatisfactionTrendChartState extends State<SatisfactionTrendChart> {
  bool showMonthly = true;

  static const monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const dimensionKeys = [
    'responsiveness', 'reliability', 'accessFacilities', 'communication',
    'costs', 'integrity', 'assurance', 'outcome',
  ];

  // Returns the average "satisfaction stars" (1-5) for a list of feedback docs
  double? _averageStarsFor(List<Map<String, dynamic>> entries) {
    final List<int> scores = [];
    for (final data in entries) {
      final details = data['satisfactionDetails'] as Map<String, dynamic>?;
      if (details == null) continue;
      for (final key in dimensionKeys) {
        final value = details[key];
        if (value is int && value != 6) {
          scores.add(value);
        }
      }
    }
    if (scores.isEmpty) return null;
    final avgCode = scores.reduce((a, b) => a + b) / scores.length;
    return 6 - avgCode;
  }

  DateTime? _entryDate(Map<String, dynamic> data) {
    final ts = (data['dateOfVisit'] ?? data['createdAt']) as Timestamp?;
    return ts?.toDate();
  }

  List<Map<String, dynamic>> get _satisfactionEntries {
    return widget.docs
        .map((d) => d.data() as Map<String, dynamic>)
        .where((d) => d['feedbackType'] == 'satisfaction')
        .toList();
  }

  // Monthly data for the current year: one avg-star value per month (null if no data)
  List<double?> _monthlyData() {
    final now = DateTime.now();
    final entries = _satisfactionEntries;

    return List.generate(12, (monthIndex) {
      final monthEntries = entries.where((data) {
        final date = _entryDate(data);
        return date != null &&
            date.year == now.year &&
            date.month == monthIndex + 1;
      }).toList();
      return _averageStarsFor(monthEntries);
    });
  }

  // Annual data: one avg-star value per year that has data, sorted ascending
  Map<int, double> _annualData() {
    final entries = _satisfactionEntries;
    final Map<int, List<Map<String, dynamic>>> byYear = {};

    for (final data in entries) {
      final date = _entryDate(data);
      if (date == null) continue;
      byYear.putIfAbsent(date.year, () => []).add(data);
    }

    final Map<int, double> result = {};
    byYear.forEach((year, list) {
      final avg = _averageStarsFor(list);
      if (avg != null) result[year] = avg;
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final hasAnySatisfactionData = _satisfactionEntries.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Satisfaction Trend',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              _toggle(),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasAnySatisfactionData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No satisfaction ratings yet.',
                  style: TextStyle(color: Colors.black45, fontSize: 13),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: showMonthly ? _monthlyChart() : _annualChart(),
            ),
        ],
      ),
    );
  }

  Widget _toggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _toggleButton('Monthly', showMonthly),
          _toggleButton('Annual', !showMonthly),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => showMonthly = label == 'Monthly'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _monthlyChart() {
    final data = _monthlyData();

    final spots = <FlSpot>[
      for (int i = 0; i < 12; i++)
        if (data[i] != null) FlSpot(i.toDouble(), data[i]!),
    ];

    if (spots.isEmpty) {
      return const Center(
        child: Text(
          'No ratings yet this year.',
          style: TextStyle(color: Colors.black45, fontSize: 13),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: 1,
        maxY: 5,
        gridData: const FlGridData(show: true, horizontalInterval: 1),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i > 11) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(monthLabels[i],
                      style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _annualChart() {
    final data = _annualData();

    if (data.isEmpty) {
      return const Center(
        child: Text(
          'Not enough data yet.',
          style: TextStyle(color: Colors.black45, fontSize: 13),
        ),
      );
    }

    final years = data.keys.toList()..sort();

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 5,
        gridData: const FlGridData(show: true, horizontalInterval: 1),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= years.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${years[i]}',
                      style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < years.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[years[i]]!,
                  color: AppColors.primary,
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }
}