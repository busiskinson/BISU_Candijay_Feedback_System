import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/feedback_model.dart';
import '../../widgets/official_letterhead.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_keys.dart';

class SatisfactionFormScreen extends StatefulWidget {
  final String? initialOfficeId;
  final String? initialOfficeName;
  final String? initialServedBy;

  const SatisfactionFormScreen({
    super.key,
    this.initialOfficeId,
    this.initialOfficeName,
    this.initialServedBy,
  });

  @override
  State<SatisfactionFormScreen> createState() =>
      _SatisfactionFormScreenState();
}

class _SatisfactionFormScreenState extends State<SatisfactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Header fields
  DateTime? dateOfVisit;
  TimeOfDay? timeOfVisit;
  String? selectedOfficeId;
  String? lockedOfficeName; // set when arriving via QR scan
  String? sex;
  String? clientType;
  final regionController = TextEditingController();
  final servicesController = TextEditingController();
  final servedByController = TextEditingController();

  // Citizen's Charter
  int? cc1;
  int? cc2;
  int? cc3;

  // 8 dimension ratings (1-6)
  final Map<String, int?> ratings = {
    'responsiveness': null,
    'reliability': null,
    'accessFacilities': null,
    'communication': null,
    'costs': null,
    'integrity': null,
    'assurance': null,
    'outcome': null,
  };

  final commendationsController = TextEditingController();
  final suggestionsController = TextEditingController();

  bool isSubmitting = false;

  final List<String> clientTypes = [
    'Citizen',
    'Business',
    'Government (Employee or another agency)',
    'Student',
  ];

  final List<Map<String, String>> dimensions = [
    {'key': 'responsiveness', 'label': 'Responsiveness'},
    {'key': 'reliability', 'label': 'Reliability (Quality)'},
    {'key': 'accessFacilities', 'label': 'Access & Facilities'},
    {'key': 'communication', 'label': 'Communication'},
    {'key': 'costs', 'label': 'Costs'},
    {'key': 'integrity', 'label': 'Integrity'},
    {'key': 'assurance', 'label': 'Assurance'},
    {'key': 'outcome', 'label': 'Outcome'},
  ];

  final List<Map<String, String>> ratingScale = [
    {'value': '1', 'emoji': '😄', 'label': 'Very Satisfied'},
    {'value': '2', 'emoji': '🙂', 'label': 'Satisfied'},
    {'value': '3', 'emoji': '😐', 'label': 'Neutral'},
    {'value': '4', 'emoji': '🙁', 'label': 'Dissatisfied'},
    {'value': '5', 'emoji': '😠', 'label': 'Very Dissatisfied'},
    {'value': '6', 'emoji': '❌', 'label': 'N/A'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialOfficeId != null) {
      selectedOfficeId = widget.initialOfficeId;
      lockedOfficeName = widget.initialOfficeName;
      final now = DateTime.now();
      dateOfVisit = now;
      timeOfVisit = TimeOfDay.fromDateTime(now);
    }
    if (widget.initialServedBy != null) {
      servedByController.text = widget.initialServedBy!;
    }
  }

  @override
  void dispose() {
    regionController.dispose();
    servicesController.dispose();
    servedByController.dispose();
    commendationsController.dispose();
    suggestionsController.dispose();
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
      setState(() => dateOfVisit = picked);
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => timeOfVisit = picked);
    }
  }

  bool get allRatingsFilled => ratings.values.every((v) => v != null);

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (dateOfVisit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the date of visit')),
      );
      return;
    }
    if (selectedOfficeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the office visited')),
      );
      return;
    }
    if (cc1 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer CC1')),
      );
      return;
    }
    if (!allRatingsFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate all 8 dimensions before submitting'),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final feedback = FeedbackModel(
        feedbackType: 'satisfaction',
        officeId: selectedOfficeId!,
        servicesAvailed: servicesController.text.trim(),
        dateOfVisit: Timestamp.fromDate(dateOfVisit!),
        timeOfVisit: timeOfVisit?.format(context),
        servedBy: servedByController.text.trim(),
        clientType: clientType,
        sex: sex,
        regionOfResidence: regionController.text.trim(),
        satisfactionDetails: SatisfactionDetails(
          cc1: cc1,
          cc2: cc2,
          cc3: cc3,
          responsiveness: ratings['responsiveness'],
          reliability: ratings['reliability'],
          accessFacilities: ratings['accessFacilities'],
          communication: ratings['communication'],
          costs: ratings['costs'],
          integrity: ratings['integrity'],
          assurance: ratings['assurance'],
          outcome: ratings['outcome'],
          commendations: commendationsController.text.trim(),
          suggestions: suggestionsController.text.trim(),
        ),
      );

      await FirebaseFirestore.instance
          .collection('feedback')
          .add(feedback.toMap());

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your feedback was submitted successfully.'),
          backgroundColor: AppColors.success,
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
        title: const Text('Satisfaction Feedback'),
        backgroundColor: AppColors.primary,
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
                  _sectionTitle('Visit Details'),
              const SizedBox(height: 12),

              // Date of Visit
              _pickerTile(
                label: dateOfVisit == null
                    ? 'Date of Visit'
                    : '${dateOfVisit!.month}/${dateOfVisit!.day}/${dateOfVisit!.year}',
                icon: Icons.calendar_today_rounded,
                onTap: pickDate,
              ),
              const SizedBox(height: 12),

              // Time of Visit
              _pickerTile(
                label: timeOfVisit == null
                    ? 'Time of Visit'
                    : timeOfVisit!.format(context),
                icon: Icons.access_time_rounded,
                onTap: pickTime,
              ),
              const SizedBox(height: 12),

                  // Office dropdown (or locked display if arrived via QR scan)
                  if (lockedOfficeName != null) _lockedOfficeDisplay() else _officeDropdown(),
                  const SizedBox(height: 12),

              // Services Availed
              TextFormField(
                controller: servicesController,
                decoration: _inputDecoration('Services Availed'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Served By
              TextFormField(
                controller: servedByController,
                decoration: _inputDecoration('Served By'),
              ),
              const SizedBox(height: 12),

              // Sex
              // Sex
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

              // Client Type
              DropdownButtonFormField<String>(
                initialValue: clientType,
                isExpanded: true,
                decoration: _inputDecoration('Client Type'),
                items: clientTypes
                    .map((t) => DropdownMenuItem(
                    value: t, child: Text(t, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => clientType = v),
              ),
              const SizedBox(height: 12),

              // Region of Residence
              TextFormField(
                controller: regionController,
                decoration: _inputDecoration('Region of Residence'),
              ),

              const SizedBox(height: 28),
              _sectionTitle("Citizen's Charter (CC)"),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                initialValue: cc1,
                isExpanded: true,
                decoration: _inputDecoration('CC1: Awareness of CC'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1. I know what a CC is and I saw this office\'s CC')),
                  DropdownMenuItem(value: 2, child: Text('2. I know what a CC is but did not see its CC')),
                  DropdownMenuItem(value: 3, child: Text('3. I learned of the CC only when I saw it')),
                  DropdownMenuItem(value: 4, child: Text('4. I do not know what a CC is')),
                ],
                onChanged: (v) {
                  setState(() {
                    cc1 = v;
                    if (v == 4) {
                      cc2 = 5; // N/A
                      cc3 = 4; // N/A
                    } else {
                      cc2 = null;
                      cc3 = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                initialValue: cc2,
                isExpanded: true,
                decoration: _inputDecoration('CC2: Was the CC easy to see?'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1. Easy to see')),
                  DropdownMenuItem(value: 2, child: Text('2. Somewhat easy to see')),
                  DropdownMenuItem(value: 3, child: Text('3. Difficult to see')),
                  DropdownMenuItem(value: 4, child: Text('4. Not visible at all')),
                  DropdownMenuItem(value: 5, child: Text('5. N/A')),
                ],
                onChanged: cc1 == 4
                    ? null
                    : (v) => setState(() => cc2 = v),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                initialValue: cc3,
                isExpanded: true,
                decoration: _inputDecoration('CC3: Did the CC help in your transaction?'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1. Helped very much')),
                  DropdownMenuItem(value: 2, child: Text('2. Somewhat helped')),
                  DropdownMenuItem(value: 3, child: Text('3. Did not help')),
                  DropdownMenuItem(value: 4, child: Text('4. N/A')),
                ],
                onChanged: cc1 == 4
                    ? null
                    : (v) => setState(() => cc3 = v),
              ),

              const SizedBox(height: 28),
              _sectionTitle('Rate Your Experience'),
              const SizedBox(height: 4),
              const Text(
                'Tap a face to rate each item.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),

              ...dimensions.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _dimensionRating(d['key']!, d['label']!),
              )),

              const SizedBox(height: 12),
              _sectionTitle('Additional Comments'),
              const SizedBox(height: 12),

              TextFormField(
                controller: commendationsController,
                maxLines: 3,
                decoration: _inputDecoration('Commendations (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: suggestionsController,
                maxLines: 3,
                decoration: _inputDecoration('Suggestions (optional)'),
              ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                    'Submit Feedback',
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
  Widget _lockedOfficeDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lockedOfficeName!,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const Text('Office selected via QR scan',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => lockedOfficeName = null),
            child: const Text('Change'),
          ),
        ],
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
          decoration: _inputDecoration('Unit/Office Visited'),
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

  Widget _dimensionRating(String key, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ratingScale.map((option) {
              final value = int.parse(option['value']!);
              final isSelected = ratings[key] == value;
              return GestureDetector(
                onTap: () => setState(() => ratings[key] = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.accentDark : Colors.black12,
                    ),
                  ),
                  child: Text(
                    option['emoji']!,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}