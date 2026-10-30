import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/secondary_firebase.dart';
import '../../widgets/admin_shell.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  static const roleOptions = [
    'admin',
    'qa_director',
    'campus_director',
    'faculty_staff',
  ];

  String searchQuery = '';
  String roleFilter = 'All Roles';
  String officeFilter = 'All Offices';
  String statusFilter = 'All Status';

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'qa_director':
        return 'QA Director';
      case 'campus_director':
        return 'Campus Director';
      case 'faculty_staff':
        return 'Faculty/Staff';
      default:
        return role;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.danger;
      case 'qa_director':
        return AppColors.accentDark;
      case 'campus_director':
        return AppColors.primary;
      default:
        return AppColors.success;
    }
  }

  Future<void> _showAddUserDialog(Map<String, String> officeNames) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'faculty_staff';
    String? selectedOfficeId;
    bool isSaving = false;
    String? errorText;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New User'),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: AppDecorations.input('Full Name'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: AppDecorations.input('Email'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      decoration: AppDecorations.input('Temporary Password'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      isExpanded: true,
                      decoration: AppDecorations.input('Role'),
                      items: roleOptions
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(_roleLabel(r)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setDialogState(() {
                        selectedRole = v!;
                        if (selectedRole != 'faculty_staff') {
                          selectedOfficeId = null;
                        }
                      }),
                    ),
                    if (selectedRole == 'faculty_staff') ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedOfficeId,
                        isExpanded: true,
                        decoration: AppDecorations.input('Office'),
                        items: officeNames.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedOfficeId = v),
                      ),
                    ],
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
                          if (nameController.text.trim().isEmpty ||
                              emailController.text.trim().isEmpty ||
                              passwordController.text.trim().length < 6) {
                            setDialogState(
                              () => errorText =
                                  'Name, email required; password must be 6+ characters.',
                            );
                            return;
                          }
                          if (selectedRole == 'faculty_staff' &&
                              selectedOfficeId == null) {
                            setDialogState(
                              () => errorText = 'Please select an office.',
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            errorText = null;
                          });

                          try {
                            final uid =
                                await SecondaryFirebase.createStaffAccount(
                                  email: emailController.text.trim(),
                                  password: passwordController.text.trim(),
                                );

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .set({
                                  'name': nameController.text.trim(),
                                  'email': emailController.text.trim(),
                                  'role': selectedRole,
                                  'officeId': selectedRole == 'faculty_staff'
                                      ? selectedOfficeId
                                      : null,
                                  'status': 'active',
                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              errorText = 'Failed: $e';
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
                      : const Text('Create User'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> _showEditUserDialog(
      BuildContext context,
      Map<String, String> officeNames, {
        required String docId,
        required String currentName,
        required String currentEmail,
        required String currentRole,
        String? currentOfficeId,
        required String currentStatus,
      }) async {
    final nameController = TextEditingController(text: currentName);
    String selectedRole = currentRole;
    String? selectedOfficeId = currentOfficeId;
    bool isActive = currentStatus == 'active';
    bool isSaving = false;
    bool isSendingReset = false;
    String? errorText;
    String? infoText;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit User'),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(currentEmail,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.only(left: 2, top: 4),
                      child: Text(
                        'Login email cannot be changed here.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameController,
                      decoration: AppDecorations.input('Full Name'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      isExpanded: true,
                      decoration: AppDecorations.input('Role'),
                      items: roleOptions
                          .map((r) => DropdownMenuItem(value: r, child: Text(_roleLabel(r))))
                          .toList(),
                      onChanged: (v) => setDialogState(() {
                        selectedRole = v!;
                        if (selectedRole != 'faculty_staff') selectedOfficeId = null;
                      }),
                    ),
                    if (selectedRole == 'faculty_staff') ...[
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedOfficeId,
                        isExpanded: true,
                        decoration: AppDecorations.input('Office'),
                        items: officeNames.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => setDialogState(() => selectedOfficeId = v),
                      ),
                    ],
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
                    const Divider(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Reset this user\'s password via email link.',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: isSendingReset
                              ? null
                              : () async {
                            setDialogState(() {
                              isSendingReset = true;
                              infoText = null;
                              errorText = null;
                            });
                            try {
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: currentEmail);
                              setDialogState(() => infoText = 'Reset email sent to $currentEmail.');
                            } catch (e) {
                              setDialogState(() => errorText = 'Failed to send reset email: $e');
                            } finally {
                              setDialogState(() => isSendingReset = false);
                            }
                          },
                          icon: isSendingReset
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.lock_reset_rounded, size: 16),
                          label: const Text('Reset Password'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    if (infoText != null) ...[
                      const SizedBox(height: 10),
                      Text(infoText!, style: const TextStyle(color: AppColors.success, fontSize: 12.5)),
                    ],
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                ElevatedButton(
                  style: AppDecorations.primaryButton(),
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (nameController.text.trim().isEmpty) {
                      setDialogState(() => errorText = 'Name is required.');
                      return;
                    }
                    if (selectedRole == 'faculty_staff' && selectedOfficeId == null) {
                      setDialogState(() => errorText = 'Please select an office.');
                      return;
                    }

                    setDialogState(() {
                      isSaving = true;
                      errorText = null;
                    });

                    try {
                      await FirebaseFirestore.instance.collection('users').doc(docId).update({
                        'name': nameController.text.trim(),
                        'role': selectedRole,
                        'officeId': selectedRole == 'faculty_staff' ? selectedOfficeId : null,
                        'status': isActive ? 'active' : 'inactive',
                      });

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
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> _confirmDeleteUser(BuildContext context, String docId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete "$name"? This removes their profile and access to the system immediately. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" has been deleted.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Users',
      selectedIndex: 4,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('offices').snapshots(),
        builder: (context, officeSnapshot) {
          final Map<String, String> officeNames = {};
          if (officeSnapshot.hasData) {
            for (final doc in officeSnapshot.data!.docs) {
              officeNames[doc.id] = (doc.data() as Map)['name'] ?? 'Unnamed';
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final allUsers = snapshot.data!.docs;
              final total = allUsers.length;
              final active = allUsers
                  .where(
                    (d) =>
                        ((d.data() as Map)['status'] ?? 'active') == 'active',
                  )
                  .length;
              final admins = allUsers
                  .where((d) => (d.data() as Map)['role'] == 'admin')
                  .length;
              final facultyStaff = allUsers
                  .where((d) => (d.data() as Map)['role'] == 'faculty_staff')
                  .length;

              final filtered = allUsers.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                final role = data['role'] ?? '';
                final officeId = data['officeId'];
                final status = data['status'] ?? 'active';

                final matchesSearch =
                    searchQuery.isEmpty ||
                    name.contains(searchQuery.toLowerCase()) ||
                    email.contains(searchQuery.toLowerCase());
                final matchesRole =
                    roleFilter == 'All Roles' || role == roleFilter;
                final matchesOffice =
                    officeFilter == 'All Offices' || officeId == officeFilter;
                final matchesStatus =
                    statusFilter == 'All Status' || status == statusFilter;

                return matchesSearch &&
                    matchesRole &&
                    matchesOffice &&
                    matchesStatus;
              }).toList();

              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.groups_rounded,
                            color: AppColors.primary,
                            label: 'TOTAL USERS',
                            value: '$total',
                            sub: 'All registered accounts',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                            label: 'ACTIVE',
                            value: '$active',
                            sub: total == 0
                                ? '—'
                                : '${(active / total * 100).toStringAsFixed(0)}% of total',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.shield_rounded,
                            color: AppColors.danger,
                            label: 'ADMINS',
                            value: '$admins',
                            sub: 'Full system access',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.badge_rounded,
                            color: AppColors.accentDark,
                            label: 'FACULTY/STAFF',
                            value: '$facultyStaff',
                            sub: 'Assigned to offices',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppDecorations.adminPanel(),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add New User',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Create a new user account',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _showAddUserDialog(officeNames),
                            style: AppDecorations.primaryButton(),
                            child: const Text('Add User'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

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
                                    'Filter & Search',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${filtered.length} users match',
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
                            children: [
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: AppDecorations.softField(),
                                  child: TextField(
                                    onChanged: (v) =>
                                        setState(() => searchQuery = v),
                                    decoration: const InputDecoration(
                                      hintText: 'Name, email, username...',
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _dropdown(
                                  roleFilter,
                                  ['All Roles', ...roleOptions],
                                  (v) => setState(() => roleFilter = v!),
                                  labelBuilder: (r) =>
                                      r == 'All Roles' ? r : _roleLabel(r),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _dropdown(
                                  officeFilter,
                                  ['All Offices', ...officeNames.keys],
                                  (v) => setState(() => officeFilter = v!),
                                  labelBuilder: (id) => id == 'All Offices'
                                      ? id
                                      : officeNames[id]!,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _dropdown(
                                  statusFilter,
                                  const ['All Status', 'active', 'inactive'],
                                  (v) => setState(() => statusFilter = v!),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Showing ${filtered.length} of $total users',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: AppDecorations.adminPanel(),
                      child: filtered.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: Text(
                                  'No users match these filters.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
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
                                dividerThickness: 0.7,
                                headingRowHeight: 44,
                                dataRowMinHeight: 56,
                                dataRowMaxHeight: 64,
                                border: TableBorder(
                                  horizontalInside: BorderSide(
                                    color: AppColors.border.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                                columns: const [
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('USER')),
                                  DataColumn(label: Text('ROLE')),
                                  DataColumn(label: Text('OFFICE')),
                                  DataColumn(label: Text('STATUS')),
                                  DataColumn(label: Text('ACTIONS')),
                                ],
                                rows: filtered.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final role = data['role'] ?? '';
                                  final officeId = data['officeId'];
                                  final status = data['status'] ?? 'active';
                                  return DataRow(cells: [
                                    DataCell(Text('#${doc.id.substring(0, 6).toUpperCase()}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                                    DataCell(Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(data['name'] ?? '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                        Text(data['email'] ?? '—', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                                      ],
                                    )),
                                    DataCell(Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: _roleColor(role).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                      child: Text(_roleLabel(role), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _roleColor(role))),
                                    )),
                                    DataCell(Text(officeId != null ? (officeNames[officeId] ?? '—') : '—', style: const TextStyle(fontSize: 12.5))),
                                    DataCell(Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (status == 'active' ? AppColors.success : Colors.black45).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(status == 'active' ? 'Active' : 'Inactive',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: status == 'active' ? AppColors.success : Colors.black45)),
                                    )),
                                    DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                          onPressed: () => _showEditUserDialog(
                                            context,
                                            officeNames,
                                            docId: doc.id,
                                            currentName: data['name'] ?? '',
                                            currentEmail: data['email'] ?? '',
                                            currentRole: role,
                                            currentOfficeId: officeId,
                                            currentStatus: status,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                          onPressed: () => _confirmDeleteUser(context, doc.id, data['name'] ?? 'this user'),
                                        ),
                                      ],
                                    )),
                                  ]);
                                }).toList(),
                              ),
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

  Widget _dropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    String Function(String)? labelBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: AppDecorations.softField(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    labelBuilder?.call(i) ?? i,
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
