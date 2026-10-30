import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/report_html_generator.dart';
import '../../utils/report_print.dart';
import '../../utils/report_aggregator.dart';
import '../../widgets/staff_shell.dart';
class StaffReportCardScreen extends StatefulWidget {
  final String officeId;
  final int year;
  final int month;

  const StaffReportCardScreen({super.key, required this.officeId, required this.year, required this.month});

  @override
  State<StaffReportCardScreen> createState() => _StaffReportCardScreenState();
}

class _StaffReportCardScreenState extends State<StaffReportCardScreen> {
  bool isLoading = true;
  OfficeReportBreakdown? officeBreakdown;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ReportAggregator.aggregate(year: widget.year, month: widget.month);
    final breakdowns = result['breakdowns'] as List<OfficeReportBreakdown>;
    officeBreakdown = breakdowns.where((b) => b.officeId == widget.officeId).isNotEmpty
        ? breakdowns.firstWhere((b) => b.officeId == widget.officeId)
        : null;
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _print() async {
    if (officeBreakdown == null) return;
    final html = await ReportHtmlGenerator.build(
      reportType: 'Monthly Report Card',
      year: widget.year,
      month: widget.month,
      breakdowns: [officeBreakdown!],
      detailSuggestions: const {},
      rootCauses: const {},
      actionPlans: const {},
      targets: const {},
      statuses: const {},
    );
    printReportHtml(html);
  }

  @override
  Widget build(BuildContext context) {
    return StaffShell(
      title: 'Report Card',
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : officeBreakdown == null
          ? const Padding(
        padding: EdgeInsets.all(30),
        child: Text('No satisfaction feedback for this period.', style: TextStyle(color: AppColors.textSecondary)),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _print,
              icon: const Icon(Icons.print_rounded, size: 17),
              label: const Text('Print'),
              style: AppDecorations.primaryButton(),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppDecorations.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${officeBreakdown!.officeName} — Report Card', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 8),
                Text('Customers: ${officeBreakdown!.numberOfCustomers}', style: const TextStyle(fontSize: 13)),
                Text('Mean Satisfaction: ${officeBreakdown!.meanSatisfaction?.toStringAsFixed(2) ?? '—'} (${officeBreakdown!.description})', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                const Text('Click Print above to view the full formatted report.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}