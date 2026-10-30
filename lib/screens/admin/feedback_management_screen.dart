import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/admin_shell.dart';
import 'admin_feedback_detail_screen.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  static const int pageSize = 10;

  int selectedYear = DateTime.now().year;
  String selectedMonth = 'All Months';

  String typeFilter = 'All Types';
  String statusFilter = 'All Status';
  String officeFilter = 'All Offices';
  final keywordController = TextEditingController();
  String appliedKeyword = '';

  int currentPage = 0;

  final List<String> monthOptions = const [
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

  @override
  void dispose() {
    keywordController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Resolved':
        return AppColors.success;
      case 'Under Review':
        return AppColors.warning;
      case 'Archived':
        return Colors.black45;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '—';
    final d = ts.toDate();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year}\n$hour:$minute $ampm';
  }

  String _shortId(String docId) {
    return '#${docId.substring(0, docId.length >= 6 ? 6 : docId.length).toUpperCase()}';
  }

  bool _matchesYearMonth(Timestamp? ts) {
    if (ts == null) return false;
    final d = ts.toDate();
    if (d.year != selectedYear) return false;
    if (selectedMonth == 'All Months') return true;
    final monthIndex = monthOptions.indexOf(selectedMonth); // 1-12
    return d.month == monthIndex;
  }

  List<QueryDocumentSnapshot> _applyAll(
    List<QueryDocumentSnapshot> docs,
    Map<String, String> officeNames,
  ) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final feedbackType = data['feedbackType'] ?? 'satisfaction';
      final status = data['status'] ?? 'Submitted';
      final officeId = data['officeId'] ?? '';
      final createdAt = data['createdAt'] as Timestamp?;

      if (!_matchesYearMonth(createdAt)) return false;

      final matchesType =
          typeFilter == 'All Types' ||
          (typeFilter == 'Satisfaction' && feedbackType == 'satisfaction') ||
          (typeFilter == 'Complaint' && feedbackType == 'complaint');
      if (!matchesType) return false;

      final matchesStatus =
          statusFilter == 'All Status' || status == statusFilter;
      if (!matchesStatus) return false;

      final matchesOffice =
          officeFilter == 'All Offices' ||
          officeNames[officeId] == officeFilter;
      if (!matchesOffice) return false;

      if (appliedKeyword.trim().isNotEmpty) {
        final keyword = appliedKeyword.trim().toLowerCase();
        final haystack = [
          data['servicesAvailed'],
          data['complaintDetails']?['actComplained'],
          data['complaintDetails']?['narrativeReport'],
          data['complaintDetails']?['complainantName'],
        ].where((v) => v != null).join(' ').toLowerCase();
        if (!haystack.contains(keyword)) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'All Feedback',
      selectedIndex: 1,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('offices').snapshots(),
        builder: (context, officeSnapshot) {
          final Map<String, String> officeNames = {};
          final List<String> officeNameList = [];
          if (officeSnapshot.hasData) {
            for (final doc in officeSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unnamed';
              officeNames[doc.id] = name;
              officeNameList.add(name);
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('feedback')
                .orderBy('createdAt', descending: true)
                .snapshots(),
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
              final filteredDocs = _applyAll(allDocs, officeNames);

              // Year-scoped totals for the stat cards (ignore type/status/office/keyword)
              final yearDocs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _matchesYearMonth(data['createdAt'] as Timestamp?);
              }).toList();
              final totalCount = yearDocs.length;
              final satisfactionCount = yearDocs
                  .where(
                    (d) => (d.data() as Map)['feedbackType'] == 'satisfaction',
                  )
                  .length;
              final complaintCount = yearDocs
                  .where(
                    (d) => (d.data() as Map)['feedbackType'] == 'complaint',
                  )
                  .length;
              final pendingCount = yearDocs
                  .where(
                    (d) =>
                        ((d.data() as Map)['status'] ?? 'Submitted') ==
                        'Submitted',
                  )
                  .length;

              final totalPages = filteredDocs.isEmpty
                  ? 1
                  : (filteredDocs.length / pageSize).ceil();
              final safePage = currentPage.clamp(0, totalPages - 1);
              if (safePage != currentPage) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() => currentPage = safePage);
                });
              }
              final startIndex = safePage * pageSize;
              final endIndex = (startIndex + pageSize).clamp(
                0,
                filteredDocs.length,
              );
              final pageDocs = filteredDocs.sublist(
                startIndex.clamp(0, filteredDocs.length),
                endIndex,
              );

              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Year / Month filter
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppDecorations.adminPanel(),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Year:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _smallDropdown<int>(
                            value: selectedYear,
                            items: [
                              for (
                                int y = DateTime.now().year;
                                y >= DateTime.now().year - 4;
                                y--
                              )
                                y,
                            ],
                            labelBuilder: (y) => y == DateTime.now().year
                                ? '$y (Current)'
                                : '$y',
                            onChanged: (v) => setState(() {
                              selectedYear = v!;
                              currentPage = 0;
                            }),
                          ),
                          const SizedBox(width: 24),
                          const Text(
                            'Month:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _smallDropdown<String>(
                            value: selectedMonth,
                            items: monthOptions,
                            labelBuilder: (m) => m,
                            onChanged: (v) => setState(() {
                              selectedMonth = v!;
                              currentPage = 0;
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stat cards
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.forum_rounded,
                            color: AppColors.primary,
                            label: 'TOTAL FEEDBACK',
                            value: '$totalCount',
                            sub: selectedMonth == 'All Months'
                                ? 'For all months $selectedYear'
                                : '$selectedMonth $selectedYear',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.star_rounded,
                            color: AppColors.success,
                            label: 'SATISFACTION',
                            value: '$satisfactionCount',
                            sub: totalCount == 0
                                ? '—'
                                : '${(satisfactionCount / totalCount * 100).toStringAsFixed(1)}% of total',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.report_problem_rounded,
                            color: AppColors.danger,
                            label: 'COMPLAINTS',
                            value: '$complaintCount',
                            sub: totalCount == 0
                                ? '—'
                                : '${(complaintCount / totalCount * 100).toStringAsFixed(1)}% of total',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.hourglass_top_rounded,
                            color: AppColors.warning,
                            label: 'PENDING REVIEW',
                            value: '$pendingCount',
                            sub: 'Awaiting action',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Advanced Filters
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppDecorations.adminPanel(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 17,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Advanced Filters',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${filteredDocs.length} records found',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _filterField(
                                  label: 'TYPE',
                                  child: _fullDropdown(
                                    value: typeFilter,
                                    items: const [
                                      'All Types',
                                      'Satisfaction',
                                      'Complaint',
                                    ],
                                    onChanged: (v) => setState(() {
                                      typeFilter = v!;
                                      currentPage = 0;
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _filterField(
                                  label: 'STATUS',
                                  child: _fullDropdown(
                                    value: statusFilter,
                                    items: const [
                                      'All Status',
                                      'Submitted',
                                      'Under Review',
                                      'Resolved',
                                      'Archived',
                                    ],
                                    onChanged: (v) => setState(() {
                                      statusFilter = v!;
                                      currentPage = 0;
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _filterField(
                                  label: 'OFFICE',
                                  child: _fullDropdown(
                                    value: officeFilter,
                                    items: ['All Offices', ...officeNameList],
                                    onChanged: (v) => setState(() {
                                      officeFilter = v!;
                                      currentPage = 0;
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _filterField(
                                  label: 'KEYWORD',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: TextField(
                                      controller: keywordController,
                                      onSubmitted: (v) => setState(() {
                                        appliedKeyword = v;
                                        currentPage = 0;
                                      }),
                                      decoration: const InputDecoration(
                                        hintText: 'Name, service, complaint...',
                                        hintStyle: TextStyle(fontSize: 12.5),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => setState(() {
                                  appliedKeyword = keywordController.text;
                                  currentPage = 0;
                                }),
                                icon: const Icon(
                                  Icons.filter_alt_rounded,
                                  size: 16,
                                ),
                                label: const Text('Apply'),
                                style: AppDecorations.primaryButton(),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => setState(() {
                                  typeFilter = 'All Types';
                                  statusFilter = 'All Status';
                                  officeFilter = 'All Offices';
                                  keywordController.clear();
                                  appliedKeyword = '';
                                  currentPage = 0;
                                }),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                                label: const Text('Clear'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Showing ${pageDocs.length} of ${filteredDocs.length} records',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Table
                    Container(
                      decoration: AppDecorations.adminPanel(),
                      child: Column(
                        children: [
                          if (filteredDocs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: Text(
                                  'No feedback matches these filters.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor:
                                    AppDecorations.tableHeadingColor(),
                                headingTextStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.4,
                                ),
                                dataTextStyle: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textPrimary,
                                ),
                                dividerThickness: 0.7,
                                headingRowHeight: 44,
                                dataRowMinHeight: 54,
                                dataRowMaxHeight: 62,
                                border: TableBorder(
                                  horizontalInside: BorderSide(
                                    color: AppColors.border.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                                columns: const [
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('TYPE')),
                                  DataColumn(label: Text('SUBMITTED BY')),
                                  DataColumn(label: Text('OFFICE/UNIT')),
                                  DataColumn(label: Text('STATUS')),
                                  DataColumn(label: Text('DATE')),
                                  DataColumn(label: Text('ACTIONS')),
                                ],
                                rows: pageDocs.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final isComplaint =
                                      data['feedbackType'] == 'complaint';
                                  final status = data['status'] ?? 'Submitted';
                                  final officeId = data['officeId'] ?? '';
                                  final officeName =
                                      officeNames[officeId] ?? '—';

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          _shortId(doc.id),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (isComplaint
                                                        ? AppColors.danger
                                                        : AppColors.success)
                                                    .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            isComplaint
                                                ? 'Complaint'
                                                : 'Satisfaction',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: isComplaint
                                                  ? AppColors.danger
                                                  : AppColors.success,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: const [
                                            Icon(
                                              Icons.visibility_off_rounded,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Anonymous',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          officeName,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(
                                              status,
                                            ).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _statusColor(status),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _formatDate(
                                            data['createdAt'] as Timestamp?,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        TextButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AdminFeedbackDetailScreen(
                                                      feedbackId: doc.id,
                                                      data: data,
                                                    ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.visibility_outlined,
                                            size: 15,
                                          ),
                                          label: const Text('View'),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          if (filteredDocs.isNotEmpty)
                            _paginationBar(safePage, totalPages),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _filterField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _fullDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map(
                (o) => DropdownMenuItem(
                  value: o,
                  child: Text(o, style: const TextStyle(fontSize: 12.5)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _smallDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
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

  Widget _paginationBar(int safePage, int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEDEDED))),
      ),
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
            'Page ${safePage + 1} of $totalPages',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
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
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.adminPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
