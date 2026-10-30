import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Signatories {
  final String? prepared; // Admin
  final String? verified; // QA Director
  final String? approved; // Campus Director

  const Signatories({this.prepared, this.verified, this.approved});
}

class SignatoryLookup {
  static Future<String?> _nameByUid(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final name = doc.data()?['name'];
      return (name is String && name.trim().isNotEmpty) ? name.trim() : null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _firstNameByRole(String role) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .limit(5)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        if ((data['status'] ?? 'active') != 'active') continue;
        final name = data['name'];
        if (name is String && name.trim().isNotEmpty) return name.trim();
      }
    } catch (_) {}
    return null;
  }

  /// [preparedByUid]: the admin who generated the report. If omitted,
  /// the currently logged-in user is used.
  static Future<Signatories> fetch({String? preparedByUid}) async {
    final uid = preparedByUid ?? FirebaseAuth.instance.currentUser?.uid;

    final results = await Future.wait<String?>([
      uid != null ? _nameByUid(uid) : Future.value(null),
      _firstNameByRole('qa_director'),
      _firstNameByRole('campus_director'),
    ]);

    String? prepared = results[0];
    prepared ??= await _firstNameByRole('admin');

    return Signatories(
      prepared: prepared,
      verified: results[1],
      approved: results[2],
    );
  }
}