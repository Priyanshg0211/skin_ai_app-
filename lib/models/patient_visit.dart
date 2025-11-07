import 'dart:typed_data';
import 'dart:convert';

class PatientVisit {
  final DateTime date;
  final Uint8List imageBytes;
  final double rednessIndex;
  final double lesionArea;
  final double pigmentation;
  final String condition;
  final double confidence;
  final String? notes;
  final List<String> symptoms;
  final Map<String, dynamic>? additionalData;

  PatientVisit({
    required this.date,
    required this.imageBytes,
    required this.rednessIndex,
    required this.lesionArea,
    required this.pigmentation,
    required this.condition,
    required this.confidence,
    this.notes,
    this.symptoms = const [],
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'imageBytes': imageBytes.isEmpty
          ? null
          : base64Encode(imageBytes),
      'rednessIndex': rednessIndex,
      'lesionArea': lesionArea,
      'pigmentation': pigmentation,
      'condition': condition,
      'confidence': confidence,
      'notes': notes,
      'symptoms': symptoms,
      'additionalData': additionalData,
    };
  }

  factory PatientVisit.fromJson(Map<String, dynamic> json) {
    return PatientVisit(
      date: DateTime.parse(json['date'] as String),
      imageBytes: json['imageBytes'] != null
          ? base64Decode(json['imageBytes'] as String)
          : Uint8List(0),
      rednessIndex: (json['rednessIndex'] as num).toDouble(),
      lesionArea: (json['lesionArea'] as num).toDouble(),
      pigmentation: (json['pigmentation'] as num).toDouble(),
      condition: json['condition'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      notes: json['notes'] as String?,
      symptoms: (json['symptoms'] as List<dynamic>?)?.cast<String>() ?? [],
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }
}

