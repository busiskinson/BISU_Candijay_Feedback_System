import 'package:cloud_firestore/cloud_firestore.dart';

class SatisfactionDetails {
  // CC1: 1-4, CC2: 1-5, CC3: 1-4 (matches the official form's numbered choices)
  final int? cc1;
  final int? cc2;
  final int? cc3;

  // Each rated 1-6: 1=Very Satisfied, 2=Satisfied, 3=Neither Satisfied nor
  // Dissatisfied, 4=Dissatisfied, 5=Very Dissatisfied, 6=Not Applicable
  final int? responsiveness;
  final int? reliability;
  final int? accessFacilities;
  final int? communication;
  final int? costs;
  final int? integrity;
  final int? assurance;
  final int? outcome;

  final String? commendations;
  final String? suggestions;

  SatisfactionDetails({
    this.cc1,
    this.cc2,
    this.cc3,
    this.responsiveness,
    this.reliability,
    this.accessFacilities,
    this.communication,
    this.costs,
    this.integrity,
    this.assurance,
    this.outcome,
    this.commendations,
    this.suggestions,
  });

  Map<String, dynamic> toMap() {
    return {
      'cc1': cc1,
      'cc2': cc2,
      'cc3': cc3,
      'responsiveness': responsiveness,
      'reliability': reliability,
      'accessFacilities': accessFacilities,
      'communication': communication,
      'costs': costs,
      'integrity': integrity,
      'assurance': assurance,
      'outcome': outcome,
      'commendations': commendations,
      'suggestions': suggestions,
    };
  }

  factory SatisfactionDetails.fromMap(Map<String, dynamic> map) {
    return SatisfactionDetails(
      cc1: map['cc1'],
      cc2: map['cc2'],
      cc3: map['cc3'],
      responsiveness: map['responsiveness'],
      reliability: map['reliability'],
      accessFacilities: map['accessFacilities'],
      communication: map['communication'],
      costs: map['costs'],
      integrity: map['integrity'],
      assurance: map['assurance'],
      outcome: map['outcome'],
      commendations: map['commendations'],
      suggestions: map['suggestions'],
    );
  }
}

class ComplaintDetails {
  final String? personComplainedOf;
  final String? complainantName;
  final Timestamp? dateOfIncident;
  final String? timeOfIncident;
  final String? placeOfIncident;
  final String? actComplained;
  final String? narrativeReport;
  final String? proofEvidence;
  final String? expectedOutcome;

  ComplaintDetails({
    this.personComplainedOf,
    this.complainantName,
    this.dateOfIncident,
    this.timeOfIncident,
    this.placeOfIncident,
    this.actComplained,
    this.narrativeReport,
    this.proofEvidence,
    this.expectedOutcome,
  });

  Map<String, dynamic> toMap() {
    return {
      'personComplainedOf': personComplainedOf,
      'complainantName': complainantName,
      'dateOfIncident': dateOfIncident,
      'timeOfIncident': timeOfIncident,
      'placeOfIncident': placeOfIncident,
      'actComplained': actComplained,
      'narrativeReport': narrativeReport,
      'proofEvidence': proofEvidence,
      'expectedOutcome': expectedOutcome,
    };
  }

  factory ComplaintDetails.fromMap(Map<String, dynamic> map) {
    return ComplaintDetails(
      personComplainedOf: map['personComplainedOf'],
      complainantName: map['complainantName'],
      dateOfIncident: map['dateOfIncident'],
      timeOfIncident: map['timeOfIncident'],
      placeOfIncident: map['placeOfIncident'],
      actComplained: map['actComplained'],
      narrativeReport: map['narrativeReport'],
      proofEvidence: map['proofEvidence'],
      expectedOutcome: map['expectedOutcome'],
    );
  }
}

class FeedbackModel {
  final String? id;
  final String? userId; // null for anonymous/unauthenticated customer submissions
  final String feedbackType; // 'satisfaction' or 'complaint'
  final String officeId;
  final String servicesAvailed;
  final bool isAnonymous;
  final String status; // e.g. 'Submitted', 'Under Review', 'Resolved'

  // Shared header / person-details fields
  final Timestamp? dateOfVisit;
  final String? timeOfVisit;
  final String? servedBy;
  final String? clientType;
  final String? sex;
  final String? regionOfResidence;
  final int? age;
  final String? address;
  final String? civilStatus;
  final String? contactDetails;

  final SatisfactionDetails? satisfactionDetails;
  final ComplaintDetails? complaintDetails;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  FeedbackModel({
    this.id,
    this.userId,
    required this.feedbackType,
    required this.officeId,
    required this.servicesAvailed,
    this.isAnonymous = false,
    this.status = 'Submitted',
    this.dateOfVisit,
    this.timeOfVisit,
    this.servedBy,
    this.clientType,
    this.sex,
    this.regionOfResidence,
    this.age,
    this.address,
    this.civilStatus,
    this.contactDetails,
    this.satisfactionDetails,
    this.complaintDetails,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'feedbackType': feedbackType,
      'officeId': officeId,
      'servicesAvailed': servicesAvailed,
      'isAnonymous': isAnonymous,
      'status': status,
      'dateOfVisit': dateOfVisit,
      'timeOfVisit': timeOfVisit,
      'servedBy': servedBy,
      'clientType': clientType,
      'sex': sex,
      'regionOfResidence': regionOfResidence,
      'age': age,
      'address': address,
      'civilStatus': civilStatus,
      'contactDetails': contactDetails,
      'satisfactionDetails': satisfactionDetails?.toMap(),
      'complaintDetails': complaintDetails?.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory FeedbackModel.fromMap(String id, Map<String, dynamic> map) {
    return FeedbackModel(
      id: id,
      userId: map['userId'],
      feedbackType: map['feedbackType'] ?? 'satisfaction',
      officeId: map['officeId'] ?? '',
      servicesAvailed: map['servicesAvailed'] ?? '',
      isAnonymous: map['isAnonymous'] ?? false,
      status: map['status'] ?? 'Submitted',
      dateOfVisit: map['dateOfVisit'],
      timeOfVisit: map['timeOfVisit'],
      servedBy: map['servedBy'],
      clientType: map['clientType'],
      sex: map['sex'],
      regionOfResidence: map['regionOfResidence'],
      age: map['age'],
      address: map['address'],
      civilStatus: map['civilStatus'],
      contactDetails: map['contactDetails'],
      satisfactionDetails: map['satisfactionDetails'] != null
          ? SatisfactionDetails.fromMap(
          Map<String, dynamic>.from(map['satisfactionDetails']))
          : null,
      complaintDetails: map['complaintDetails'] != null
          ? ComplaintDetails.fromMap(
          Map<String, dynamic>.from(map['complaintDetails']))
          : null,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }
}