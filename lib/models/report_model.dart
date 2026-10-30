import 'package:cloud_firestore/cloud_firestore.dart';

class OfficeReportBreakdown {
  final String officeId;
  final String officeName;
  final int numberOfCustomers;
  final int sexMale;
  final int sexFemale;
  final int clientCitizen;
  final int clientBusiness;
  final int clientGovernment;
  final int clientStudent;

  // Citizen's Charter tallies: option code -> count
  final Map<int, int> cc1Counts; // 1-4
  final Map<int, int> cc2Counts; // 1-5
  final Map<int, int> cc3Counts; // 1-4

  // Dimension means, converted to 1-5 stars scale (5 = best)
  final Map<String, double?> dimensionMeans;
  final double? meanSatisfaction;
  final String description;

  final List<String> commendations;
  final List<String> suggestions;

  OfficeReportBreakdown({
    required this.officeId,
    required this.officeName,
    required this.numberOfCustomers,
    required this.sexMale,
    required this.sexFemale,
    required this.clientCitizen,
    required this.clientBusiness,
    required this.clientGovernment,
    required this.clientStudent,
    required this.cc1Counts,
    required this.cc2Counts,
    required this.cc3Counts,
    required this.dimensionMeans,
    required this.meanSatisfaction,
    required this.description,
    required this.commendations,
    required this.suggestions,
  });

  Map<String, dynamic> toMap() {
    return {
      'officeId': officeId,
      'officeName': officeName,
      'numberOfCustomers': numberOfCustomers,
      'sexMale': sexMale,
      'sexFemale': sexFemale,
      'clientCitizen': clientCitizen,
      'clientBusiness': clientBusiness,
      'clientGovernment': clientGovernment,
      'clientStudent': clientStudent,
      'cc1Counts': cc1Counts.map((k, v) => MapEntry('$k', v)),
      'cc2Counts': cc2Counts.map((k, v) => MapEntry('$k', v)),
      'cc3Counts': cc3Counts.map((k, v) => MapEntry('$k', v)),
      'dimensionMeans': dimensionMeans,
      'meanSatisfaction': meanSatisfaction,
      'description': description,
      'commendations': commendations,
      'suggestions': suggestions,
    };
  }

  factory OfficeReportBreakdown.fromMap(Map<String, dynamic> map) {
    Map<int, int> parseCounts(dynamic raw) {
      final result = <int, int>{};
      if (raw is Map) {
        raw.forEach((k, v) {
          result[int.parse(k.toString())] = (v as num).toInt();
        });
      }
      return result;
    }

    return OfficeReportBreakdown(
      officeId: map['officeId'] ?? '',
      officeName: map['officeName'] ?? '',
      numberOfCustomers: map['numberOfCustomers'] ?? 0,
      sexMale: map['sexMale'] ?? 0,
      sexFemale: map['sexFemale'] ?? 0,
      clientCitizen: map['clientCitizen'] ?? 0,
      clientBusiness: map['clientBusiness'] ?? 0,
      clientGovernment: map['clientGovernment'] ?? 0,
      clientStudent: map['clientStudent'] ?? 0,
      cc1Counts: parseCounts(map['cc1Counts']),
      cc2Counts: parseCounts(map['cc2Counts']),
      cc3Counts: parseCounts(map['cc3Counts']),
      dimensionMeans: Map<String, double?>.from(
        (map['dimensionMeans'] as Map? ?? {}).map(
              (k, v) => MapEntry(k.toString(), (v as num?)?.toDouble()),
        ),
      ),
      meanSatisfaction: (map['meanSatisfaction'] as num?)?.toDouble(),
      description: map['description'] ?? '—',
      commendations: List<String>.from(map['commendations'] ?? []),
      suggestions: List<String>.from(map['suggestions'] ?? []),
    );
  }
}

class ReportModel {
  final String? id;
  final String reportTitle;
  final int reportMonth; // 1-12
  final int reportYear;
  final String reportNotes;
  final String reportType; // 'monthly'
  final String submittedBy;
  final String status;
  final String? approvedBy;
  final String? approvalRemarks;

  final int totalFeedback;
  final double? averageRating;
  final double? satisfactionRate;

  final List<OfficeReportBreakdown> officeBreakdowns;
  final OfficeReportBreakdown? overallBreakdown;

  final Timestamp? submittedAt;
  final Timestamp? approvedAt;
  final Timestamp? createdAt;

  ReportModel({
    this.id,
    required this.reportTitle,
    required this.reportMonth,
    required this.reportYear,
    required this.reportNotes,
    required this.reportType,
    required this.submittedBy,
    this.status = 'Pending Review',
    this.approvedBy,
    this.approvalRemarks,
    required this.totalFeedback,
    this.averageRating,
    this.satisfactionRate,
    required this.officeBreakdowns,
    this.overallBreakdown,
    this.submittedAt,
    this.approvedAt,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reportTitle': reportTitle,
      'reportMonth': reportMonth,
      'reportYear': reportYear,
      'reportNotes': reportNotes,
      'reportType': reportType,
      'submittedBy': submittedBy,
      'status': status,
      'approvedBy': approvedBy,
      'approvalRemarks': approvalRemarks,
      'totalFeedback': totalFeedback,
      'averageRating': averageRating,
      'satisfactionRate': satisfactionRate,
      'officeBreakdowns': officeBreakdowns.map((o) => o.toMap()).toList(),
      'overallBreakdown': overallBreakdown?.toMap(),
      'submittedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ReportModel.fromMap(String id, Map<String, dynamic> map) {
    return ReportModel(
      id: id,
      reportTitle: map['reportTitle'] ?? '',
      reportMonth: map['reportMonth'] ?? 1,
      reportYear: map['reportYear'] ?? DateTime.now().year,
      reportNotes: map['reportNotes'] ?? '',
      reportType: map['reportType'] ?? 'monthly',
      submittedBy: map['submittedBy'] ?? '',
      status: map['status'] ?? 'Pending Review',
      approvedBy: map['approvedBy'],
      approvalRemarks: map['approvalRemarks'],
      totalFeedback: map['totalFeedback'] ?? 0,
      averageRating: (map['averageRating'] as num?)?.toDouble(),
      satisfactionRate: (map['satisfactionRate'] as num?)?.toDouble(),
      officeBreakdowns: (map['officeBreakdowns'] as List? ?? [])
          .map((o) => OfficeReportBreakdown.fromMap(Map<String, dynamic>.from(o)))
          .toList(),
      overallBreakdown: map['overallBreakdown'] != null
          ? OfficeReportBreakdown.fromMap(Map<String, dynamic>.from(map['overallBreakdown']))
          : null,
      submittedAt: map['submittedAt'],
      approvedAt: map['approvedAt'],
      createdAt: map['createdAt'],
    );
  }
}