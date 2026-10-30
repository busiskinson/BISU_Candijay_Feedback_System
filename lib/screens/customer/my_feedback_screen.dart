import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'feedback_detail_screen.dart';

class MyFeedbackScreen extends StatefulWidget {
  const MyFeedbackScreen({super.key});

  @override
  State<MyFeedbackScreen> createState() => _MyFeedbackScreenState();
}

class _MyFeedbackScreenState extends State<MyFeedbackScreen> {
  static const int pageSize = 5;

  String typeFilter = 'All';
  String statusFilter = 'All';
  int currentPage = 0;

  final List<String> typeOptions = ['All', 'Satisfaction', 'Complaint'];
  final List<String> statusOptions = [
    'All',
    'Submitted',
    'Under Review',
    'Resolved',
    'Archived',
  ];

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
    if (ts == null) return '';
    final d = ts.toDate();
    return '${d.month}/${d.day}/${d.year}';
  }

  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final feedbackType = data['feedbackType'] ?? 'satisfaction';
      final status = data['status'] ?? 'Submitted';

      final matchesType = typeFilter == 'All' ||
          (typeFilter == 'Satisfaction' && feedbackType == 'satisfaction') ||
          (typeFilter == 'Complaint' && feedbackType == 'complaint');

      final matchesStatus = statusFilter == 'All' || status == statusFilter;

      return matchesType && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Feedback'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: uid == null
          ? const Center(child: Text('Please log in to view your feedback.'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedback')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Something went wrong loading your feedback.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final allDocs = snapshot.data!.docs;
          final filteredDocs = _applyFilters(allDocs);

          final totalPages = filteredDocs.isEmpty
              ? 1
              : (filteredDocs.length / pageSize).ceil();

          // Keep currentPage in range if filters just shrank the list
          final safePage = currentPage.clamp(0, totalPages - 1);
          if (safePage != currentPage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => currentPage = safePage);
            });
          }

          final startIndex = safePage * pageSize;
          final endIndex = (startIndex + pageSize)
              .clamp(0, filteredDocs.length);
          final pageDocs = filteredDocs.sublist(
            startIndex.clamp(0, filteredDocs.length),
            endIndex,
          );

          return Column(
            children: [
              _filterBar(),
              Expanded(
                child: filteredDocs.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No feedback matches your filters.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15),
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  itemCount: pageDocs.length,
                  itemBuilder: (context, index) {
                    final data = pageDocs[index].data()
                    as Map<String, dynamic>;
                    return _feedbackCard(data);
                  },
                ),
              ),
              if (filteredDocs.isNotEmpty)
                _paginationBar(safePage, totalPages),
            ],
          );
        },
      ),
    );
  }

  Widget _filterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppColors.background,
      child: Row(
        children: [
          Expanded(
            child: _filterDropdown(
              label: 'Type',
              value: typeFilter,
              options: typeOptions,
              onChanged: (v) {
                setState(() {
                  typeFilter = v!;
                  currentPage = 0;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _filterDropdown(
              label: 'Status',
              value: statusFilter,
              options: statusOptions,
              onChanged: (v) {
                setState(() {
                  statusFilter = v!;
                  currentPage = 0;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: AppDecorations.card(radius: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: const TextStyle(
              fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text('$label: $o')))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _feedbackCard(Map<String, dynamic> data) {
    final feedbackType = data['feedbackType'] ?? 'satisfaction';
    final status = data['status'] ?? 'Submitted';
    final createdAt = data['createdAt'] as Timestamp?;
    final isComplaint = feedbackType == 'complaint';

    final title = isComplaint ? 'Complaint' : 'Satisfaction Feedback';
    final subtitle = isComplaint
        ? (data['complaintDetails']?['actComplained'] ?? '')
        : (data['servicesAvailed'] ?? '');

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FeedbackDetailScreen(data: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card(radius: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isComplaint ? AppColors.danger : AppColors.primary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isComplaint
                    ? Icons.report_problem_rounded
                    : Icons.sentiment_satisfied_alt_rounded,
                color: isComplaint ? AppColors.danger : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  if (subtitle.toString().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginationBar(int safePage, int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
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
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          Text(
            'Page ${safePage + 1} of $totalPages',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          TextButton.icon(
            onPressed: safePage < totalPages - 1
                ? () => setState(() => currentPage = safePage + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Next'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}