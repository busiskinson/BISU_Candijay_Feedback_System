import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import 'satisfaction_form_screen.dart';
import 'dart:convert';

class SelectPersonnelScreen extends StatelessWidget {
  final String officeId;
  final String officeName;

  const SelectPersonnelScreen({super.key, required this.officeId, required this.officeName});

  void _proceed(BuildContext context, {String? servedByName}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SatisfactionFormScreen(
          initialOfficeId: officeId,
          initialOfficeName: officeName,
          initialServedBy: servedByName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Who served you?'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('personnel')
            .where('officeId', isEqualTo: officeId)
            .where('active', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final docs = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select the staff member who assisted you at $officeName.',
                    style: AppTextStyles.subheading),
                const SizedBox(height: 20),
                Expanded(
                  child: docs.isEmpty
                      ? const Center(
                    child: Text('No personnel listed for this office yet.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                      : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Unnamed';
                      final photoBase64 = data['photoBase64'];

                      return GestureDetector(
                        onTap: () => _proceed(context, servedByName: name),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 38,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: photoBase64 != null ? MemoryImage(base64Decode(photoBase64)) : null,
                              child: photoBase64 == null
                                  ? const Icon(Icons.person_rounded, size: 34, color: AppColors.primary)
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => _proceed(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Not sure / Skip'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}