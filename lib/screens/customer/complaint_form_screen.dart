import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/feedback_model.dart';
import '../../widgets/official_letterhead.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_keys.dart';

class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? selectedOfficeId;

  // Complainant / person details
  final complainantNameController = TextEditingController();
  final addressController = TextEditingController();
  String? sex;
  final ageController = TextEditingController();
  String? civilStatus;
  final contactDetailsController = TextEditingController();

  // Complaint details
  final personComplainedOfController = TextEditingController();
  DateTime? dateOfIncident;
  TimeOfDay? timeOfIncident;
  final placeOfIncidentController = TextEditingController();
  final actComplainedController = TextEditingController();
  final narrativeReportController = TextEditingController();
  final expectedOutcomeController = TextEditingController();

  bool isSubmitting = false;

  final List<String> civilStatusOptions = [
    'Single',
    'Married',
    'Widowed',
    'Separated',
  ];

  @override
  void dispose() {
    complainantNameController.dispose();
    addressController.dispose();
    ageController.dispose();
    contactDetailsController.dispose();
    personComplainedOfController.dispose();
    placeOfIncidentController.dispose();
    actComplainedController.dispose();
    narrativeReportController.dispose();
    expectedOutcomeController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => dateOfIncident = picked);
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => timeOfIncident = picked);
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedOfficeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the office involved')),
      );
      return;
    }
    if (dateOfIncident == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the date of incident')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final feedback = FeedbackModel(
        feedbackType: 'complaint',
        officeId: selectedOfficeId!,
        servicesAvailed: '',
        sex: sex,
        age: int.tryParse(ageController.text.trim()),
        address: addressController.text.trim(),
        civilStatus: civilStatus,
        contactDetails: contactDetailsController.text.trim(),
        complaintDetails: ComplaintDetails(
          personComplainedOf: personComplainedOfController.text.trim(),
          complainantName: complainantNameController.text.trim(),
          dateOfIncident: Timestamp.fromDate(dateOfIncident!),
          timeOfIncident: timeOfIncident?.format(context),
          placeOfIncident: placeOfIncidentController.text.trim(),
          actComplained: actComplainedController.text.trim(),
          narrativeReport: narrativeReportController.text.trim(),
          expectedOutcome: expectedOutcomeController.text.trim(),
        ),
      );

      await FirebaseFirestore.instance
          .collection('feedback')
          .add(feedback.toMap());

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Your complaint was submitted. We will review it.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('File a Complaint'),
        backgroundColor: AppColors.danger,
        foregroundColor: Colors.white,
      ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
                padding: EdgeInsets.zero,
                children: [
                const OfficialLetterhead(officeName: 'Quality Assurance'),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _noticeBox(),
              const SizedBox(height: 20),

              _sectionTitle('Complainant Details'),
              const SizedBox(height: 12),

              TextFormField(
                controller: complainantNameController,
                decoration: _inputDecoration('Name of Complainant'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: addressController,
                decoration: _inputDecoration('Address'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              RadioGroup<String>(
                groupValue: sex,
                onChanged: (v) => setState(() => sex = v),
                child: Row(
                  children: const [
                    Expanded(
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Male'),
                        value: 'Male',
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Female'),
                        value: 'Female',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Age'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: civilStatus,
                isExpanded: true,
                decoration: _inputDecoration('Civil Status'),
                items: civilStatusOptions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => civilStatus = v),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: contactDetailsController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Contact Details'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 28),
              _sectionTitle('Complaint Details'),
              const SizedBox(height: 12),

              _officeDropdown(),
              const SizedBox(height: 12),

              TextFormField(
                controller: personComplainedOfController,
                decoration: _inputDecoration('Name of Person Complained Of'),
              ),
              const SizedBox(height: 12),

              _pickerTile(
                label: dateOfIncident == null
                    ? 'Date of Incident'
                    : '${dateOfIncident!.month}/${dateOfIncident!.day}/${dateOfIncident!.year}',
                icon: Icons.event_rounded,
                onTap: pickDate,
              ),
              const SizedBox(height: 12),

              _pickerTile(
                label: timeOfIncident == null
                    ? 'Time of Incident'
                    : timeOfIncident!.format(context),
                icon: Icons.access_time_rounded,
                onTap: pickTime,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: placeOfIncidentController,
                decoration: _inputDecoration('Place of Incident'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: actComplainedController,
                maxLines: 3,
                decoration: _inputDecoration('Act/s Complained Of'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: narrativeReportController,
                maxLines: 5,
                decoration: _inputDecoration('Narrative Report of Complaint'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: expectedOutcomeController,
                maxLines: 3,
                decoration: _inputDecoration(
                    'Expected Outcome (what would you like to happen?)'),
              ),

              const SizedBox(height: 8),
              const Text(
                'Note: attaching proof/evidence files will be added in a later step.',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    'Submit Complaint',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
                ],
            ),
          ),
        ),
    );
  }

  Widget _noticeBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: const Text(
        'This form is for reporting dissatisfaction with a service. '
            'Information provided is handled confidentially in accordance '
            'with the Data Privacy Act.',
        style: TextStyle(fontSize: 12.5, color: Color(0xFF8D5A00)),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return AppDecorations.input(label);
  }

  Widget _pickerTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black45, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _officeDropdown() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('offices')
          .where('active', isEqualTo: true)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading offices...'),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          initialValue: selectedOfficeId,
          isExpanded: true,
          decoration: _inputDecoration('Office Involved'),
          items: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: Text(data['name'] ?? 'Unnamed office',
                  overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (v) => setState(() => selectedOfficeId = v),
        );
      },
    );
  }
}