import 'package:flutter/material.dart';

/// Reproduces the official BISU document letterhead used on the
/// printed Customer Satisfaction Feedback Form and Complaint Form.
class OfficialLetterhead extends StatelessWidget {
  final String officeName;

  const OfficialLetterhead({super.key, required this.officeName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // BISU seal
          Image.asset('image/img.png', width: 46, height: 46),
          const SizedBox(width: 10),

          // Center text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Republic of the Philippines',
                  style: TextStyle(fontSize: 9.5, color: Colors.black87),
                ),
                const Text(
                  'BOHOL ISLAND STATE UNIVERSITY',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  'Candijay Campus, Bohol, Philippines',
                  style: TextStyle(fontSize: 9, color: Colors.black54),
                ),
                Text(
                  'Office of the $officeName',
                  style: const TextStyle(fontSize: 9, color: Colors.black54),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Balance | Integrity | Stewardship | Uprightness',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Bagong Pilipinas + ISO certification badges
          Image.asset('image/img_1.png', width: 40, height: 40),
          const SizedBox(width: 6),
          Image.asset('image/img.jpeg', width: 40, height: 40),
        ],
      ),
    );
  }
}