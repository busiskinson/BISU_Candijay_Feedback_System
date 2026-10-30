import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../utils/app_theme.dart';

class StaffShell extends StatelessWidget {
  final String title;
  final Widget body;

  const StaffShell({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            width: 220,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          child: ClipOval(
                            child: Image.asset('image/img.png', width: 34, height: 34, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'BISU Candijay\nFeedback System',
                            style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Row(children: [
                      Icon(Icons.dashboard_rounded, color: Colors.white, size: 19),
                      SizedBox(width: 12),
                      Text('Dashboard', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  const Spacer(),
                  Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                  InkWell(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      child: const Row(children: [
                        Icon(Icons.logout_rounded, color: Colors.white, size: 19),
                        SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(),
                Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: body)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFEDEDED)))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search feedback...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      border: InputBorder.none, isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 20),
          const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
          const SizedBox(width: 20),
          if (uid != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final name = data?['name'] ?? 'Staff';
                final initial = name.toString().isNotEmpty ? name[0].toUpperCase() : '?';
                return Row(children: [
                  CircleAvatar(radius: 16, backgroundColor: AppColors.primary,
                      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                  const SizedBox(width: 10),
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ]);
              },
            ),
        ],
      ),
    );
  }
}