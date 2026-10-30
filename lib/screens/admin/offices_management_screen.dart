import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/admin_shell.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class OfficesManagementScreen extends StatelessWidget {
  const OfficesManagementScreen({super.key});

  Future<void> _showOfficeDialog(
    BuildContext context, {
    String? docId,
    String? currentName,
    String? currentDescription,
    bool currentActive = true,
  }) async {
    final nameController = TextEditingController(text: currentName ?? '');
    final descController = TextEditingController(
      text: currentDescription ?? '',
    );
    bool isActive = currentActive;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Text(docId == null ? 'Add Office' : 'Edit Office'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: AppDecorations.input('Office Name'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: AppDecorations.input('Description'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Switch(
                          value: isActive,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) => setDialogState(() => isActive = v),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: AppDecorations.primaryButton(),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Office name is required'),
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isSaving = true);

                          final data = {
                            'name': nameController.text.trim(),
                            'description': descController.text.trim(),
                            'active': isActive,
                          };

                          try {
                            if (docId == null) {
                              await FirebaseFirestore.instance
                                  .collection('offices')
                                  .add(data);
                            } else {
                              await FirebaseFirestore.instance
                                  .collection('offices')
                                  .doc(docId)
                                  .update(data);
                            }
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to save: $e')),
                              );
                            }
                          }
                        },
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Offices',
      selectedIndex: 2,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('offices').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${docs.length} office(s)',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showOfficeDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Office'),
                      style: AppDecorations.primaryButton(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: AppDecorations.adminPanel(),
                  child: docs.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'No offices yet. Add one to get started.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < docs.length; i++)
                              _officeTile(
                                context,
                                docs[i],
                                isLast: i == docs.length - 1,
                              ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showQrDialog(BuildContext context, String officeId, String officeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('QR Code — $officeName'),
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
                  size: 220,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Print and post this at $officeName\'s counter. Customers scan it to auto-fill this office on the feedback form.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPersonnelListDialog(
    BuildContext context,
    String officeId,
    String officeName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Personnel — $officeName'),
        content: SizedBox(
          width: 420,
          height: 420,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showAddEditPersonnelDialog(context, officeId),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add'),
                  style: AppDecorations.primaryButton(),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('personnel')
                      .where('officeId', isEqualTo: officeId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No personnel added yet.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final name = data['name'] ?? 'Unnamed';
                        final photoBase64 = data['photoBase64'];
                        final active = data['active'] ?? true;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            backgroundImage: photoBase64 != null
                                ? MemoryImage(base64Decode(photoBase64))
                                : null,
                            child: photoBase64 == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primary,
                                  )
                                : null,
                          ),
                          title: Text(name),
                          subtitle: Text(
                            active ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: active
                                  ? AppColors.success
                                  : Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => _showAddEditPersonnelDialog(
                              context,
                              officeId,
                              docId: docs[index].id,
                              currentName: name,
                              currentPhotoBase64: photoBase64,
                              currentActive: active,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditPersonnelDialog(
    BuildContext context,
    String officeId, {
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Text(docId == null ? 'Add Personnel' : 'Edit Personnel'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 300,
                        );
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
                            : (currentPhotoBase64 != null
                                  ? MemoryImage(
                                      base64Decode(currentPhotoBase64),
                                    )
                                  : null),
                        child:
                            (pickedBytes == null && currentPhotoBase64 == null)
                            ? const Icon(
                                Icons.add_a_photo_rounded,
                                color: AppColors.textSecondary,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap to select photo',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
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
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) => setDialogState(() => isActive = v),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: AppDecorations.primaryButton(),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) {
                            setDialogState(
                              () => errorText = 'Name is required.',
                            );
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
                              await FirebaseFirestore.instance
                                  .collection('personnel')
                                  .add(data);
                            } else {
                              await FirebaseFirestore.instance
                                  .collection('personnel')
                                  .doc(docId)
                                  .update(data);
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
            );
          },
        );
      },
    );
  }

  Widget _officeTile(
    BuildContext context,
    QueryDocumentSnapshot doc, {
    required bool isLast,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unnamed';
    final description = data['description'] ?? '';
    final active = data['active'] ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF2F2F2))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description.toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (active ? AppColors.success : Colors.black45).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (active ? AppColors.success : Colors.black45).withValues(
                  alpha: 0.16,
                ),
              ),
            ),
            child: Text(
              active ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.success : Colors.black45,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(
              Icons.qr_code_2_rounded,
              size: 19,
              color: AppColors.primary,
            ),
            tooltip: 'View QR Code',
            onPressed: () => _showQrDialog(context, doc.id, name),
          ),
          IconButton(
            icon: const Icon(
              Icons.groups_2_outlined,
              size: 19,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Manage Personnel',
            onPressed: () => _showPersonnelListDialog(context, doc.id, name),
          ),

          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              size: 19,
              color: AppColors.textSecondary,
            ),
            onPressed: () => _showOfficeDialog(
              context,
              docId: doc.id,
              currentName: name,
              currentDescription: description,
              currentActive: active,
            ),
          ),
        ],
      ),
    );
  }
}
