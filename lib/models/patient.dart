import 'dart:typed_data';
import 'patient_visit.dart';

class Patient {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final String phoneNumber;
  final String email;
  final String address;
  final String medicalHistory;
  final List<String> allergies;
  final List<String> medications;
  final String skinType; // Fitzpatrick scale I-VI
  final DateTime createdAt;
  final DateTime? lastVisit;
  final List<PatientVisit> visits;
  final Map<String, dynamic> additionalNotes;
  final String? userId; // Link to Firebase Auth user (for patient portal)

  Patient({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.phoneNumber,
    this.email = '',
    this.address = '',
    this.medicalHistory = '',
    this.allergies = const [],
    this.medications = const [],
    this.skinType = 'III',
    required this.createdAt,
    this.lastVisit,
    this.visits = const [],
    this.additionalNotes = const {},
    this.userId,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  Patient copyWith({
    String? id,
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? email,
    String? address,
    String? medicalHistory,
    List<String>? allergies,
    List<String>? medications,
    String? skinType,
    DateTime? createdAt,
    DateTime? lastVisit,
    List<PatientVisit>? visits,
    Map<String, dynamic>? additionalNotes,
    String? userId,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      skinType: skinType ?? this.skinType,
      createdAt: createdAt ?? this.createdAt,
      lastVisit: lastVisit ?? this.lastVisit,
      visits: visits ?? this.visits,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'medications': medications,
      'skinType': skinType,
      'createdAt': createdAt.toIso8601String(),
      'lastVisit': lastVisit?.toIso8601String(),
      'visits': visits.length, // Store count, actual visits stored separately
      'additionalNotes': additionalNotes,
      'userId': userId,
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      gender: json['gender'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      medicalHistory: json['medicalHistory'] as String? ?? '',
      allergies: (json['allergies'] as List<dynamic>?)?.cast<String>() ?? [],
      medications: (json['medications'] as List<dynamic>?)?.cast<String>() ?? [],
      skinType: json['skinType'] as String? ?? 'III',
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastVisit: json['lastVisit'] != null
          ? DateTime.parse(json['lastVisit'] as String)
          : null,
      visits: [], // Loaded separately
      additionalNotes: (json['additionalNotes'] as Map<String, dynamic>?) ?? {},
      userId: json['userId'] as String?,
    );
  }
}

