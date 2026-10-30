import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportAggregator {
  static const List<String> dimensionKeys = [
    'responsiveness', 'reliability', 'accessFacilities', 'communication',
    'costs', 'integrity', 'assurance', 'outcome',
  ];

  /// Standard 5-point descriptive banding (higher = better).
  static String describeRating(double? mean) {
    if (mean == null) return '—';
    if (mean >= 4.51) return 'Excellent';
    if (mean >= 3.51) return 'Very Satisfactory';
    if (mean >= 2.51) return 'Satisfactory';
    if (mean >= 1.51) return 'Fair';
    return 'Poor';
  }

  /// Builds a breakdown for one group of satisfaction feedback entries.
  static OfficeReportBreakdown _buildBreakdown({
    required String officeId,
    required String officeName,
    required List<Map<String, dynamic>> entries,
  }) {
    int sexMale = 0, sexFemale = 0;
    int citizen = 0, business = 0, government = 0, student = 0;
    final Map<int, int> cc1 = {1: 0, 2: 0, 3: 0, 4: 0};
    final Map<int, int> cc2 = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    final Map<int, int> cc3 = {1: 0, 2: 0, 3: 0, 4: 0};

    final Map<String, List<int>> dimensionScores = {
      for (final k in dimensionKeys) k: <int>[],
    };
    final List<int> allScoresForMean = [];

    final List<String> commendations = [];
    final List<String> suggestions = [];

    for (final e in entries) {
      if (e['sex'] == 'Male') sexMale++;
      if (e['sex'] == 'Female') sexFemale++;

      switch (e['clientType']) {
        case 'Citizen':
          citizen++;
          break;
        case 'Business':
          business++;
          break;
        case 'Government (Employee or another agency)':
          government++;
          break;
        case 'Student':
          student++;
          break;
      }

      final details = e['satisfactionDetails'] as Map<String, dynamic>?;
      if (details == null) continue;

      final c1 = details['cc1'];
      if (c1 is int && cc1.containsKey(c1)) cc1[c1] = cc1[c1]! + 1;
      final c2 = details['cc2'];
      if (c2 is int && cc2.containsKey(c2)) cc2[c2] = cc2[c2]! + 1;
      final c3 = details['cc3'];
      if (c3 is int && cc3.containsKey(c3)) cc3[c3] = cc3[c3]! + 1;

      for (final key in dimensionKeys) {
        final v = details[key];
        if (v is int && v != 6) {
          dimensionScores[key]!.add(v);
          allScoresForMean.add(v);
        }
      }

      final comm = (details['commendations'] as String?)?.trim();
      if (comm != null && comm.isNotEmpty) commendations.add(comm);
      final sugg = (details['suggestions'] as String?)?.trim();
      if (sugg != null && sugg.isNotEmpty) suggestions.add(sugg);
    }

    final Map<String, double?> dimensionMeans = {};
    for (final key in dimensionKeys) {
      final scores = dimensionScores[key]!;
      dimensionMeans[key] = scores.isEmpty
          ? null
          : 6 - (scores.reduce((a, b) => a + b) / scores.length);
    }

    double? meanSatisfaction;
    if (allScoresForMean.isNotEmpty) {
      meanSatisfaction =
          6 - (allScoresForMean.reduce((a, b) => a + b) / allScoresForMean.length);
    }

    return OfficeReportBreakdown(
      officeId: officeId,
      officeName: officeName,
      numberOfCustomers: entries.length,
      sexMale: sexMale,
      sexFemale: sexFemale,
      clientCitizen: citizen,
      clientBusiness: business,
      clientGovernment: government,
      clientStudent: student,
      cc1Counts: cc1,
      cc2Counts: cc2,
      cc3Counts: cc3,
      dimensionMeans: dimensionMeans,
      meanSatisfaction: meanSatisfaction,
      description: describeRating(meanSatisfaction),
      commendations: commendations,
      suggestions: suggestions,
    );
  }

  /// Aggregates all satisfaction feedback for [year]/[month] into
  /// one breakdown per office, plus an overall combined breakdown.
  static Future<Map<String, dynamic>> aggregate({
    required int year,
    required int month,
  }) async {
    final feedbackSnapshot =
    await FirebaseFirestore.instance.collection('feedback').get();
    final officesSnapshot =
    await FirebaseFirestore.instance.collection('offices').get();

    final Map<String, String> officeNames = {
      for (final doc in officesSnapshot.docs)
        doc.id: (doc.data())['name'] ?? 'Unnamed',
    };

    final allEntries = feedbackSnapshot.docs.map((d) => d.data()).where((data) {
      if (data['feedbackType'] != 'satisfaction') return false;
      final ts = data['createdAt'] as Timestamp?;
      if (ts == null) return false;
      final date = ts.toDate();
      return date.year == year && date.month == month;
    }).toList();

    final Map<String, List<Map<String, dynamic>>> byOffice = {};
    for (final e in allEntries) {
      final officeId = e['officeId'] ?? 'unknown';
      byOffice.putIfAbsent(officeId, () => []).add(e);
    }

    final List<OfficeReportBreakdown> breakdowns = [];
    for (final entry in byOffice.entries) {
      breakdowns.add(_buildBreakdown(
        officeId: entry.key,
        officeName: officeNames[entry.key] ?? 'Unknown Office',
        entries: entry.value,
      ));
    }
    breakdowns.sort((a, b) => a.officeName.compareTo(b.officeName));

    final overall = _buildBreakdown(
      officeId: 'overall',
      officeName: 'Overall',
      entries: allEntries,
    );

    return {
      'breakdowns': breakdowns,
      'overall': overall,
      'totalFeedback': feedbackSnapshot.docs.where((d) {
        final data = d.data();
        final ts = data['createdAt'] as Timestamp?;
        if (ts == null) return false;
        final date = ts.toDate();
        return date.year == year && date.month == month;
      }).length,
    };
  }
}