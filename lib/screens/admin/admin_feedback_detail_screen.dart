import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class AdminFeedbackDetailScreen extends StatefulWidget {
  final String feedbackId;
  final Map<String, dynamic> data;

  const AdminFeedbackDetailScreen({
    super.key,
    required this.feedbackId,
    required this.data,
  });

  @override
  State<AdminFeedbackDetailScreen> createState() =>
      _AdminFeedbackDetailScreenState();
}

class _AdminFeedbackDetailScreenState extends State<AdminFeedbackDetailScreen> {
  late String selectedStatus;
  bool isSaving = false;

  final List<String> statusOptions = [
    'Submitted',
    'Under Review',
    'Resolved',
    'Archived',
  ];

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

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.data['status'] ?? 'Submitted';
  }

  Future<void> _saveStatus() async {
    setState(() => isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(widget.feedbackId)
          .update({
            'status': selectedStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status updated.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  String _formatDate(dynamic ts) {
    if (ts == null || ts is! Timestamp) return '—';
    final d = ts.toDate();
    return '${d.month}/${d.day}/${d.year}';
  }

  String _text(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '—';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isComplaint = data['feedbackType'] == 'complaint';
    final satisfactionDetails =
        data['satisfactionDetails'] as Map<String, dynamic>?;
    final complaintDetails = data['complaintDetails'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isComplaint ? 'Complaint Details' : 'Feedback Details'),
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecorations.adminPanel(),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: AppDecorations.input('Status'),
                        items: statusOptions
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selectedStatus = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isSaving ? null : _saveStatus,
                      style: AppDecorations.primaryButton(),
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ],
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
                    _row(
                      'Region of Residence',
                      _text(data['regionOfResidence']),
                    ),
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
                    final label = code is int
                        ? (ratingLabels[code] ?? '—')
                        : '—';
                    return _row(e.value, label);
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Comments',
                  rows: [
                    _row(
                      'Commendations',
                      _text(satisfactionDetails['commendations']),
                    ),
                    _row(
                      'Suggestions',
                      _text(satisfactionDetails['suggestions']),
                    ),
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
                    _row(
                      'Person Complained Of',
                      _text(complaintDetails?['personComplainedOf']),
                    ),
                    _row(
                      'Date of Incident',
                      _formatDate(complaintDetails?['dateOfIncident']),
                    ),
                    _row(
                      'Time of Incident',
                      _text(complaintDetails?['timeOfIncident']),
                    ),
                    _row(
                      'Place of Incident',
                      _text(complaintDetails?['placeOfIncident']),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Complaint',
                  rows: [
                    _row(
                      'Act/s Complained Of',
                      _text(complaintDetails?['actComplained']),
                    ),
                    _row(
                      'Narrative Report',
                      _text(complaintDetails?['narrativeReport']),
                    ),
                    _row(
                      'Expected Outcome',
                      _text(complaintDetails?['expectedOutcome']),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> rows}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.adminPanel(radius: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
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
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
