import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class FeedbackDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const FeedbackDetailScreen({super.key, required this.data});

  static const Map<int, String> ratingLabels = {
    1: 'Very Satisfied',
    2: 'Satisfied',
    3: 'Neither Satisfied nor Dissatisfied',
    4: 'Dissatisfied',
    5: 'Very Dissatisfied',
    6: 'N/A',
  };

  static const Map<String, String> dimensionLabels = {
    'responsiveness': 'Responsiveness',
    'reliability': 'Reliability (Quality)',
    'accessFacilities': 'Access & Facilities',
    'communication': 'Communication',
    'costs': 'Costs',
    'integrity': 'Integrity',
    'assurance': 'Assurance',
    'outcome': 'Outcome',
  };

  String _formatDate(dynamic ts) {
    if (ts == null || ts is! Timestamp) return '—';
    final d = ts.toDate();
    return '${d.month}/${d.day}/${d.year}';
  }

  String _text(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '—';
    return value.toString();
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

  @override
  Widget build(BuildContext context) {
    final isComplaint = data['feedbackType'] == 'complaint';
    final status = data['status'] ?? 'Submitted';
    final satisfactionDetails =
    data['satisfactionDetails'] as Map<String, dynamic>?;
    final complaintDetails = data['complaintDetails'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isComplaint ? 'Complaint Details' : 'Feedback Details'),
        backgroundColor: isComplaint ? AppColors.danger : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Status badge
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(status),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _sectionCard(
            title: 'Submission Info',
            rows: [
              _row('Submitted On', _formatDate(data['createdAt'])),
              if (!isComplaint) ...[
                _row('Date of Visit', _formatDate(data['dateOfVisit'])),
                _row('Time of Visit', _text(data['timeOfVisit'])),
                _row('Services Availed', _text(data['servicesAvailed'])),
                _row('Served By', _text(data['servedBy'])),
                _row('Client Type', _text(data['clientType'])),
                _row('Sex', _text(data['sex'])),
                _row('Region of Residence', _text(data['regionOfResidence'])),
              ],
            ],
          ),

          if (!isComplaint && satisfactionDetails != null) ...[
            const SizedBox(height: 16),
            _sectionCard(
              title: "Citizen's Charter",
              rows: [
                _row('CC1', _text(satisfactionDetails['cc1'])),
                _row('CC2', _text(satisfactionDetails['cc2'])),
                _row('CC3', _text(satisfactionDetails['cc3'])),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Ratings',
              rows: dimensionLabels.entries.map((e) {
                final code = satisfactionDetails[e.key];
                final label =
                code is int ? (ratingLabels[code] ?? '—') : '—';
                return _row(e.value, label);
              }).toList(),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Comments',
              rows: [
                _row('Commendations', _text(satisfactionDetails['commendations'])),
                _row('Suggestions', _text(satisfactionDetails['suggestions'])),
              ],
            ),
          ],

          if (isComplaint) ...[
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Complainant Details',
              rows: [
                _row('Name', _text(complaintDetails?['complainantName'])),
                _row('Address', _text(data['address'])),
                _row('Sex', _text(data['sex'])),
                _row('Age', _text(data['age'])),
                _row('Civil Status', _text(data['civilStatus'])),
                _row('Contact Details', _text(data['contactDetails'])),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Incident Details',
              rows: [
                _row('Person Complained Of',
                    _text(complaintDetails?['personComplainedOf'])),
                _row('Date of Incident',
                    _formatDate(complaintDetails?['dateOfIncident'])),
                _row('Time of Incident',
                    _text(complaintDetails?['timeOfIncident'])),
                _row('Place of Incident',
                    _text(complaintDetails?['placeOfIncident'])),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Complaint',
              rows: [
                _row('Act/s Complained Of',
                    _text(complaintDetails?['actComplained'])),
                _row('Narrative Report',
                    _text(complaintDetails?['narrativeReport'])),
                _row('Expected Outcome',
                    _text(complaintDetails?['expectedOutcome'])),
              ],
            ),
          ],

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 16, color: Colors.black45),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Submitted feedback cannot be edited or deleted.',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> rows}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}