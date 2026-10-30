import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../utils/app_theme.dart';

class DirectorShell extends StatelessWidget {
  final String title;
  final int selectedIndex;
  final Widget body;

  const DirectorShell({super.key, required this.title, required this.selectedIndex, required this.body});

  static const _menuItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
    {'icon': Icons.verified_rounded, 'label': 'Approved Reports'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            width: 240,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                              child: Text('BISU Candijay\nFeedback System',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(6)),
                          child: const Text('CAMPUS DIRECTOR',
                              style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
                  const SizedBox(height: 12),
                  for (int i = 0; i < _menuItems.length; i++)
                    _NavItem(
                      icon: _menuItems[i]['icon'] as IconData,
                      label: _menuItems[i]['label'] as String,
                      selected: i == selectedIndex,
                      onTap: () {
                        if (i == selectedIndex) return;
                        if (i == 0) Navigator.pushReplacementNamed(context, '/directorDashboard');
                        if (i == 1) Navigator.pushReplacementNamed(context, '/directorReports');
                      },
                    ),
                  const Spacer(),
                  Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
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

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: widget.selected ? Colors.white.withValues(alpha: 0.16) : (_hovering ? Colors.white.withValues(alpha: 0.06) : null),
            borderRadius: BorderRadius.circular(10),
            border: widget.selected
                ? const Border(left: BorderSide(color: AppColors.accent, width: 3))
                : const Border(left: BorderSide(color: Colors.transparent, width: 3)),
          ),
          child: Row(children: [
            Icon(widget.icon, color: Colors.white.withValues(alpha: widget.selected ? 1 : 0.85), size: 19),
            const SizedBox(width: 12),
            Text(widget.label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: widget.selected ? 1 : 0.85),
                    fontSize: 13.5,
                    fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ),
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
          const Spacer(),
          if (uid != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final name = data?['name'] ?? 'Campus Director';
                final initial = name.toString().isNotEmpty ? name[0].toUpperCase() : '?';
                return Row(children: [
                  CircleAvatar(radius: 16, backgroundColor: AppColors.primary,
                      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Text('Campus Director', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ]);
              },
            ),
        ],
      ),
    );
  }
}