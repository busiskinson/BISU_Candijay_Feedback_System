import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/staff_shell.dart';
import 'staff_report_card_screen.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  static const dimKeys = [
    'responsiveness', 'reliability', 'accessFacilities', 'communication',
    'costs', 'integrity', 'assurance', 'outcome',
  ];
  static const dimLabels = [
    'Responsiveness', 'Reliability', 'Access & Facilities', 'Communication',
    'Costs', 'Integrity', 'Assurance', 'Outcome',
  ];
  static const monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  int selectedYear = DateTime.now().year;
  String selectedMonth = 'All Months';
  int currentPage = 0;
  static const pageSize = 10;
  String submittedFormSearch = '';
  final TextEditingController submittedFormSearchController = TextEditingController();
  String submittedClientType = 'All Client Types';
  String submittedService = 'All Services';
  String submittedStatus = 'All Statuses';

  String? officeId;
  String officeName = '';
  bool isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (mounted) {
      setState(() {
        officeId = data?['officeId'];
        isLoadingProfile = false;
      });
    }
    if (officeId != null) {
      final officeDoc = await FirebaseFirestore.instance.collection('offices').doc(officeId).get();
      if (mounted) setState(() => officeName = (officeDoc.data()?['name']) ?? 'Office');
    }
  }

  @override
  void dispose() {
    submittedFormSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingProfile) {
      return const StaffShell(title: 'Dashboard', body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (officeId == null) {
      return const StaffShell(
        title: 'Dashboard',
        body: Padding(
          padding: EdgeInsets.all(30),
          child: Text('No office assigned to this account. Contact an Admin.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return StaffShell(
      title: 'Dashboard',
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('feedback').where('officeId', isEqualTo: officeId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
          }

          final allDocs = snapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();

          final total = allDocs.length;
          final satisfaction = allDocs.where((d) => d['feedbackType'] == 'satisfaction').toList();
          final complaints = allDocs.where((d) => d['feedbackType'] == 'complaint').length;

          final now = DateTime.now();
          final thisMonth = allDocs.where((d) {
            final ts = d['createdAt'] as Timestamp?;
            if (ts == null) return false;
            final date = ts.toDate();
            return date.year == now.year && date.month == now.month;
          }).length;

          final List<int> allScores = [];
          for (final d in satisfaction) {
            final details = d['satisfactionDetails'] as Map<String, dynamic>?;
            if (details == null) continue;
            for (final k in dimKeys) {
              final v = details[k];
              if (v is int && v != 6) allScores.add(v);
            }
          }
          double? avgStars;
          double? satisfactionRate;
          if (allScores.isNotEmpty) {
            final avgCode = allScores.reduce((a, b) => a + b) / allScores.length;
            avgStars = 6 - avgCode;
            final satisfiedCount = allScores.where((v) => v == 1 || v == 2).length;
            satisfactionRate = (satisfiedCount / allScores.length) * 100;
          }

          // Filtered by year/month for trend + dimensions + table
          final scopedDocs = allDocs.where((d) {
            final ts = d['createdAt'] as Timestamp?;
            if (ts == null) return false;
            final date = ts.toDate();
            if (date.year != selectedYear) return false;
            if (selectedMonth != 'All Months' && monthNames.indexOf(selectedMonth) != date.month) return false;
            return true;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _welcomeCard(officeName, total, satisfactionRate),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _StatCard(icon: Icons.forum_rounded, color: AppColors.primary, value: '$total', label: 'TOTAL FEEDBACK', sub: '$selectedYear')),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(icon: Icons.sentiment_satisfied_alt_rounded, color: AppColors.success, value: satisfactionRate == null ? '—' : '${satisfactionRate.toStringAsFixed(0)}%', label: 'SATISFACTION RATE', sub: '${satisfaction.length} positive/rated')),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(icon: Icons.star_rounded, color: AppColors.accentDark, value: avgStars == null ? '—' : avgStars.toStringAsFixed(1), label: 'AVERAGE RATING', sub: avgStars == null ? '—' : '${avgStars.toStringAsFixed(1)} / 5')),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(icon: Icons.report_problem_rounded, color: AppColors.danger, value: '$complaints', label: 'COMPLAINTS', sub: 'All time')),
              ]),
              const SizedBox(height: 16),
              _yearMonthFilter(),
              const SizedBox(height: 16),
              _monthlyTrendCard(allDocs),
              const SizedBox(height: 16),
              _dimensionsCard(scopedDocs),
              const SizedBox(height: 16),
              _qrCodeCard(),
              const SizedBox(height: 16),
              _personnelCard(),
              const SizedBox(height: 16),
              _generateReportCard(),
              const SizedBox(height: 16),
              _feedbackDetailsTable(scopedDocs),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _welcomeCard(String officeName, int total, double? rate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.forum_rounded, color: AppColors.primary, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back, $officeName!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Monitor customer satisfaction feedback for your office.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.apartment_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(officeName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 16),
                const Icon(Icons.forum_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Total $total', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 16),
                const Icon(Icons.star_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(rate == null ? 'No ratings yet' : 'Satisfaction ${rate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
  Widget _qrCodeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Your Office QR Code', style: AppTextStyles.sectionTitle),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Print and post this at your counter. Customers scan it to auto-fill your office on the Satisfaction Feedback form.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => _showQrDialog(context),
                  icon: const Icon(Icons.fullscreen_rounded, size: 16),
                  label: const Text('View / Print QR Code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (officeId != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEDEAF2)),
              ),
              child: QrImageView(
                data: 'bisu-office:$officeId',
                version: QrVersions.auto,
                size: 84,
              ),
            ),
        ],
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(officeName.isEmpty ? 'Office QR Code' : 'QR Code — $officeName'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: QrImageView(
                  data: 'bisu-office:$officeId',
                  version: QrVersions.auto,
                  size: 240,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Right-click the QR code and choose "Save image as..." to download, or use your browser\'s print option.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
  Widget _yearMonthFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        const Text('Year:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        _dropdown<int>(selectedYear, [for (int y = DateTime.now().year; y >= DateTime.now().year - 3; y--) y],
                (y) => y == DateTime.now().year ? '$y (Current)' : '$y', (v) => setState(() => selectedYear = v!)),
        const SizedBox(width: 24),
        const Text('Month:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        _dropdown<String>(selectedMonth, const ['All Months', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
                (m) => m, (v) => setState(() => selectedMonth = v!)),
      ]),
    );
  }

  Widget _dropdown<T>(T value, List<T> items, String Function(T) labelBuilder, ValueChanged<T?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items.map((o) => DropdownMenuItem(value: o, child: Text(labelBuilder(o), style: const TextStyle(fontSize: 12.5)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _monthlyTrendCard(List<Map<String, dynamic>> allDocs) {
    final counts = List.filled(12, 0);
    for (final d in allDocs) {
      final ts = d['createdAt'] as Timestamp?;
      if (ts == null) continue;
      final date = ts.toDate();
      if (date.year == selectedYear) counts[date.month - 1]++;
    }
    const monthShort = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    final maxY = (counts.reduce((a, b) => a > b ? a : b)).toDouble().clamp(5.0, double.infinity).toDouble();

    return Container(
      height: 280,
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Satisfaction Trend — $selectedYear', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(LineChartData(
              minY: 0, maxY: maxY,
              gridData: const FlGridData(show: true, horizontalInterval: 1),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, m) {
                  final i = v.toInt();
                  if (i < 0 || i > 11) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 6), child: Text(monthShort[i], style: const TextStyle(fontSize: 10)));
                })),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [for (int i = 0; i < 12; i++) FlSpot(i.toDouble(), counts[i].toDouble())],
                  isCurved: true, color: AppColors.primary, barWidth: 2.5,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.08)),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _dimensionsCard(List<Map<String, dynamic>> scopedDocs) {
    final satisfaction = scopedDocs.where((d) => d['feedbackType'] == 'satisfaction').toList();
    final List<double?> means = [];
    int ratedCount = 0;
    for (final key in dimKeys) {
      final scores = <int>[];
      for (final d in satisfaction) {
        final details = d['satisfactionDetails'] as Map<String, dynamic>?;
        final v = details?[key];
        if (v is int && v != 6) scores.add(v);
      }
      ratedCount = scores.length > ratedCount ? scores.length : ratedCount;
      means.add(scores.isEmpty ? null : 6 - (scores.reduce((a, b) => a + b) / scores.length));
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              const Icon(Icons.star_rounded, color: AppColors.accentDark, size: 18),
              const SizedBox(width: 8),
              Text('Satisfaction Dimensions', style: AppTextStyles.sectionTitle),
            ]),
            Text('Based on $ratedCount ratings', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 5.2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 8,
            children: [
              for (int i = 0; i < dimKeys.length; i++) _dimensionBar(dimLabels[i], means[i]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dimensionBar(String label, double? value) {
    final fraction = (value ?? 0) / 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 12.5)),
          Text(value == null ? '—' : '${value.toStringAsFixed(1)}/5', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction.clamp(0, 1),
            minHeight: 7,
            backgroundColor: AppColors.background,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _generateReportCard() {
    int genMonth = DateTime.now().month;
    int genYear = DateTime.now().year;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: AppDecorations.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.summarize_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('Generate Monthly Report Card', style: AppTextStyles.sectionTitle),
              ]),
              const SizedBox(height: 4),
              const Text('Create a formatted monthly report card for your office.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _dropdown<int>(genMonth, [for (int m = 1; m <= 12; m++) m],
                          (m) => monthNames[m], (v) => setLocalState(() => genMonth = v!)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdown<int>(genYear, [for (int y = DateTime.now().year; y >= DateTime.now().year - 3; y--) y],
                          (y) => '$y', (v) => setLocalState(() => genYear = v!)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StaffReportCardScreen(officeId: officeId!, year: genYear, month: genMonth),
                      ),
                    );
                  },
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text('Generate Report'),
                  style: AppDecorations.primaryButton(),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }  Widget _personnelCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.badge_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('Office Personnel', style: AppTextStyles.sectionTitle),
              ]),
              ElevatedButton.icon(
                onPressed: () => _showAddEditPersonnelDialog(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add'),
                style: AppDecorations.primaryButton(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Staff listed here appear on the "Who served you?" screen when customers scan your office QR code.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('personnel')
                .where('officeId', isEqualTo: officeId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No personnel added yet.', style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              return Column(
                children: [
                  for (final doc in docs) _personnelTile(doc),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deactivatePersonnel(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final name = (data['name'] ?? 'this personnel').toString();
    final personnelOfficeId = data['officeId']?.toString();

    // Client-side safeguard. Firestore Security Rules must enforce this too.
    if (officeId == null || personnelOfficeId != officeId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only manage personnel assigned to your office.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Office Personnel?'),
        content: Text(
          'Deactivate $name? They will no longer appear in new customer feedback '
              'submissions. Existing feedback and reports will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.person_remove_alt_1_rounded, size: 17),
            label: const Text('Deactivate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('personnel')
          .doc(doc.id)
          .update({
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name has been deactivated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to deactivate personnel: $e')),
      );
    }
  }

  Widget _personnelTile(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unnamed';
    final photoBase64 = data['photoBase64'];
    final active = data['active'] ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: photoBase64 != null ? MemoryImage(base64Decode(photoBase64)) : null,
            child: photoBase64 == null ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 20) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (active ? AppColors.success : Colors.black45).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(active ? 'Active' : 'Inactive',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? AppColors.success : Colors.black45)),
          ),
          const SizedBox(width: 10),
          if (active)
            IconButton(
              tooltip: 'Deactivate personnel',
              icon: const Icon(
                Icons.person_remove_alt_1_rounded,
                size: 19,
                color: AppColors.danger,
              ),
              onPressed: () => _deactivatePersonnel(doc),
            ),
          IconButton(
            tooltip: 'Edit personnel',
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
            onPressed: () => _showAddEditPersonnelDialog(
              context,
              docId: doc.id,
              currentName: name,
              currentPhotoBase64: photoBase64,
              currentActive: active,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditPersonnelDialog(
      BuildContext context, {
        String? docId,
        String? currentName,
        String? currentPhotoBase64,
        bool currentActive = true,
      }) async {
    final nameController = TextEditingController(text: currentName ?? '');
    bool isActive = currentActive;
    bool isSaving = false;
    Uint8List? pickedBytes;
    String? errorText;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(docId == null ? 'Add Personnel' : 'Edit Personnel'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300);
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          setDialogState(() => pickedBytes = bytes);
                        }
                      },
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.background,
                        backgroundImage: pickedBytes != null
                            ? MemoryImage(pickedBytes!)
                            : (currentPhotoBase64 != null ? MemoryImage(base64Decode(currentPhotoBase64)) : null),
                        child: (pickedBytes == null && currentPhotoBase64 == null)
                            ? const Icon(Icons.add_a_photo_rounded, color: AppColors.textSecondary)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Tap to select photo', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: AppDecorations.input('Full Name'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Switch(
                          value: isActive,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setDialogState(() => isActive = v),
                        ),
                        const SizedBox(width: 6),
                        Text(isActive ? 'Active' : 'Inactive', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: AppDecorations.primaryButton(),
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (nameController.text.trim().isEmpty) {
                      setDialogState(() => errorText = 'Name is required.');
                      return;
                    }
                    setDialogState(() {
                      isSaving = true;
                      errorText = null;
                    });

                    try {
                      String? photoBase64 = currentPhotoBase64;
                      if (pickedBytes != null) {
                        photoBase64 = base64Encode(pickedBytes!);
                      }

                      final data = {
                        'name': nameController.text.trim(),
                        'officeId': officeId,
                        'photoBase64': photoBase64,
                        'active': isActive,
                      };

                      if (docId == null) {
                        await FirebaseFirestore.instance.collection('personnel').add(data);
                      } else {
                        await FirebaseFirestore.instance.collection('personnel').doc(docId).update(data);
                      }

                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      setDialogState(() {
                        isSaving = false;
                        errorText = 'Failed to save: $e';
                      });
                    }
                  },
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _feedbackDetailsTable(List<Map<String, dynamic>> scopedDocs) {
    final satisfaction = scopedDocs
        .where((d) => d['feedbackType'] == 'satisfaction')
        .toList()
      ..sort((a, b) {
        final ta = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final tb = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return tb.compareTo(ta);
      });

    final clientTypes = <String>{
      'All Client Types',
      ...satisfaction.map((d) => (d['clientType'] ?? '').toString().trim())
          .where((v) => v.isNotEmpty),
    }.toList();
    final services = <String>{
      'All Services',
      ...satisfaction.map((d) => (d['servicesAvailed'] ?? '').toString().trim())
          .where((v) => v.isNotEmpty),
    }.toList();
    if (!clientTypes.contains(submittedClientType)) {
      submittedClientType = 'All Client Types';
    }
    if (!services.contains(submittedService)) {
      submittedService = 'All Services';
    }

    final query = submittedFormSearch.trim().toLowerCase();
    final filtered = satisfaction.where((d) {
      final clientType = (d['clientType'] ?? '—').toString();
      final service = (d['servicesAvailed'] ?? '—').toString();
      final status = (d['status'] ?? 'Submitted').toString();
      final ts = (d['createdAt'] as Timestamp?)?.toDate();
      final dateText = ts == null
          ? ''
          : '${ts.month}/${ts.day}/${ts.year} ${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
      final matchesSearch = query.isEmpty ||
          clientType.toLowerCase().contains(query) ||
          service.toLowerCase().contains(query) ||
          status.toLowerCase().contains(query) ||
          dateText.toLowerCase().contains(query);
      final matchesClient = submittedClientType == 'All Client Types' ||
          clientType == submittedClientType;
      final matchesService = submittedService == 'All Services' ||
          service == submittedService;
      final matchesStatus = submittedStatus == 'All Statuses' ||
          status.toLowerCase() == submittedStatus.toLowerCase();
      return matchesSearch && matchesClient && matchesService && matchesStatus;
    }).toList();

    final totalPages = filtered.isEmpty ? 1 : (filtered.length / pageSize).ceil();
    final safePage = currentPage.clamp(0, totalPages - 1);
    final start = safePage * pageSize;
    final end = (start + pageSize).clamp(0, filtered.length);
    final pageDocs = filtered.sublist(start.clamp(0, filtered.length), end);

    return Container(
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Submitted Form Details', style: AppTextStyles.sectionTitle),
                Text(
                  '${filtered.length} records (Page ${safePage + 1} of $totalPages)',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: submittedFormSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search submitted forms...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 19),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (value) => setState(() {
                        submittedFormSearch = value;
                        currentPage = 0;
                      }),
                    ),
                  ),
                  _filterDropdown<String>(
                    value: submittedClientType,
                    options: clientTypes,
                    label: 'Client Type',
                    onChanged: (value) => setState(() {
                      submittedClientType = value ?? 'All Client Types';
                      currentPage = 0;
                    }),
                  ),
                  _filterDropdown<String>(
                    value: submittedService,
                    options: services,
                    label: 'Service',
                    onChanged: (value) => setState(() {
                      submittedService = value ?? 'All Services';
                      currentPage = 0;
                    }),
                  ),
                  _filterDropdown<String>(
                    value: submittedStatus,
                    options: const ['All Statuses', 'Submitted', 'Reviewed', 'In Progress', 'Resolved'],
                    label: 'Status',
                    onChanged: (value) => setState(() {
                      submittedStatus = value ?? 'All Statuses';
                      currentPage = 0;
                    }),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      submittedFormSearchController.clear();
                      setState(() {
                        submittedFormSearch = '';
                        submittedClientType = 'All Client Types';
                        submittedService = 'All Services';
                        submittedStatus = 'All Statuses';
                        currentPage = 0;
                      });
                    },
                    icon: const Icon(Icons.restart_alt_rounded, size: 17),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: Text('No submitted forms match your filters.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
          // Make the table fill the available card width on wide screens,
          // while retaining horizontal scrolling on smaller screens.
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 28,
                    horizontalMargin: 24,
                    headingRowColor: WidgetStateProperty.all(AppColors.background),
                    columns: const [
                      DataColumn(label: Text('DATE')),
                      DataColumn(label: Text('CLIENT TYPE')),
                      DataColumn(label: Text('SERVICE')),
                      DataColumn(label: Text('MEAN RATING')),
                      DataColumn(label: Text('STATUS')),
                    ],
                    rows: pageDocs.map((d) {
                      final ts = d['createdAt'] as Timestamp?;
                      final date = ts == null
                          ? '—'
                          : '${ts.toDate().month}/${ts.toDate().day}/${ts.toDate().year}';
                      final details = d['satisfactionDetails'] as Map<String, dynamic>?;
                      final scores = <int>[];
                      if (details != null) {
                        for (final k in dimKeys) {
                          final v = details[k];
                          if (v is int && v != 6) scores.add(v);
                        }
                      }
                      final mean = scores.isEmpty
                          ? null
                          : 6 - (scores.reduce((a, b) => a + b) / scores.length);
                      return DataRow(cells: [
                        DataCell(Text(date, style: const TextStyle(fontSize: 12))),
                        DataCell(Text(d['clientType'] ?? '—', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(d['servicesAvailed'] ?? '—', style: const TextStyle(fontSize: 12))),
                        DataCell(Text(mean == null ? '—' : mean.toStringAsFixed(2), style: const TextStyle(fontSize: 12))),
                        DataCell(Text(d['status'] ?? 'Submitted', style: const TextStyle(fontSize: 12))),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          if (filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: safePage > 0
                        ? () => setState(() => currentPage = safePage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: const Text('Previous'),
                  ),
                  Text(
                    'Showing ${start + 1}–$end of ${filtered.length} forms',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  TextButton.icon(
                    onPressed: safePage < totalPages - 1
                        ? () => setState(() => currentPage = safePage + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Next'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterDropdown<T>({
    required T value,
    required List<T> options,
    required String label,
    required ValueChanged<T?> onChanged,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 220),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
        items: options.map((option) => DropdownMenuItem<T>(
          value: option,
          child: Text(option.toString(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String sub;

  const _StatCard({required this.icon, required this.color, required this.value, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3)),
            Icon(icon, color: color, size: 18),
          ]),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
