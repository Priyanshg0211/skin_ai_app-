import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import '../models/patient_visit.dart';

class FirebasePatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get all patients (with access control)
  Future<List<Patient>> getAllPatients({String? userId}) async {
    try {
      QuerySnapshot snapshot;
      
      if (userId != null) {
        // Get patient's own record
        snapshot = await _firestore
            .collection('patients')
            .where('userId', isEqualTo: userId)
            .get();
      } else {
        // Get all patients (for clinicians/admins)
        snapshot = await _firestore.collection('patients').get();
      }

      final patients = <Patient>[];
      
      for (var doc in snapshot.docs) {
        final patient = Patient.fromJson(doc.data() as Map<String, dynamic>);
        // Load visits
        final visits = await getPatientVisits(patient.id);
        patients.add(patient.copyWith(visits: visits));
      }

      return patients;
    } catch (e) {
      debugPrint('Error loading patients: $e');
      return [];
    }
  }

  // Get patient by ID
  Future<Patient?> getPatientById(String id) async {
    try {
      final doc = await _firestore.collection('patients').doc(id).get();
      if (doc.exists) {
        final patient = Patient.fromJson(doc.data()!);
        final visits = await getPatientVisits(id);
        return patient.copyWith(visits: visits);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading patient: $e');
      return null;
    }
  }

  // Save patient
  Future<bool> savePatient(Patient patient) async {
    try {
      await _firestore.collection('patients').doc(patient.id).set(patient.toJson());
      return true;
    } catch (e) {
      debugPrint('Error saving patient: $e');
      return false;
    }
  }

  // Delete patient
  Future<bool> deletePatient(String id) async {
    try {
      // Delete all visits first
      await deletePatientVisits(id);
      
      // Delete patient images from storage
      final visits = await getPatientVisits(id);
      for (var visit in visits) {
        if (visit.imageBytes.isNotEmpty) {
          try {
            await _storage.ref('patients/$id/visits/${visit.date.millisecondsSinceEpoch}.jpg').delete();
          } catch (e) {
            debugPrint('Error deleting image: $e');
          }
        }
      }
      
      // Delete patient document
      await _firestore.collection('patients').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting patient: $e');
      return false;
    }
  }

  // Get visits for a patient
  Future<List<PatientVisit>> getPatientVisits(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('visits')
          .orderBy('date', descending: true)
          .get();

      final visits = <PatientVisit>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Load image from storage if URL exists
        Uint8List imageBytes = Uint8List(0);
        if (data['imageUrl'] != null) {
          try {
            final ref = _storage.refFromURL(data['imageUrl'] as String);
            final bytes = await ref.getData();
            if (bytes != null) {
              imageBytes = bytes;
            }
          } catch (e) {
            debugPrint('Error loading image: $e');
          }
        } else if (data['imageBytes'] != null) {
          // Fallback to base64 if URL not available
          imageBytes = base64Decode(data['imageBytes'] as String);
        }

        visits.add(PatientVisit(
          date: (data['date'] as Timestamp).toDate(),
          imageBytes: imageBytes,
          rednessIndex: (data['rednessIndex'] as num).toDouble(),
          lesionArea: (data['lesionArea'] as num).toDouble(),
          pigmentation: (data['pigmentation'] as num).toDouble(),
          condition: data['condition'] as String,
          confidence: (data['confidence'] as num).toDouble(),
          notes: data['notes'] as String?,
          symptoms: (data['symptoms'] as List<dynamic>?)?.cast<String>() ?? [],
          additionalData: data['additionalData'] as Map<String, dynamic>?,
        ));
      }

      return visits;
    } catch (e) {
      debugPrint('Error loading visits: $e');
      return [];
    }
  }

  // Save visit for a patient
  Future<bool> savePatientVisit(String patientId, PatientVisit visit) async {
    try {
      // Upload image to storage
      String? imageUrl;
      if (visit.imageBytes.isNotEmpty) {
        try {
          final ref = _storage
              .ref('patients/$patientId/visits/${visit.date.millisecondsSinceEpoch}.jpg');
          await ref.putData(visit.imageBytes);
          imageUrl = await ref.getDownloadURL();
        } catch (e) {
          debugPrint('Error uploading image: $e');
        }
      }

      // Save visit to Firestore
      final visitData = {
        'date': Timestamp.fromDate(visit.date),
        'imageUrl': imageUrl,
        'rednessIndex': visit.rednessIndex,
        'lesionArea': visit.lesionArea,
        'pigmentation': visit.pigmentation,
        'condition': visit.condition,
        'confidence': visit.confidence,
        'notes': visit.notes,
        'symptoms': visit.symptoms,
        'additionalData': visit.additionalData,
      };

      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('visits')
          .add(visitData);

      // Update patient's last visit
      await _firestore.collection('patients').doc(patientId).update({
        'lastVisit': Timestamp.fromDate(visit.date),
      });

      return true;
    } catch (e) {
      debugPrint('Error saving visit: $e');
      return false;
    }
  }

  // Delete all visits for a patient
  Future<bool> deletePatientVisits(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('visits')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error deleting visits: $e');
      return false;
    }
  }

  // Search patients
  Future<List<Patient>> searchPatients(String query, {String? userId}) async {
    try {
      QuerySnapshot snapshot;
      
      if (userId != null) {
        snapshot = await _firestore
            .collection('patients')
            .where('userId', isEqualTo: userId)
            .get();
      } else {
        snapshot = await _firestore.collection('patients').get();
      }

      if (query.isEmpty) {
        final patients = <Patient>[];
        for (var doc in snapshot.docs) {
          final patient = Patient.fromJson(doc.data() as Map<String, dynamic>);
          final visits = await getPatientVisits(patient.id);
          patients.add(patient.copyWith(visits: visits));
        }
        return patients;
      }

      final lowerQuery = query.toLowerCase();
      final patients = <Patient>[];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] as String? ?? '').toLowerCase();
        final phone = data['phoneNumber'] as String? ?? '';
        final email = (data['email'] as String? ?? '').toLowerCase();
        final id = (data['id'] as String? ?? '').toLowerCase();

        if (name.contains(lowerQuery) ||
            phone.contains(query) ||
            email.contains(lowerQuery) ||
            id.contains(lowerQuery)) {
          final patient = Patient.fromJson(data);
          final visits = await getPatientVisits(patient.id);
          patients.add(patient.copyWith(visits: visits));
        }
      }

      return patients;
    } catch (e) {
      debugPrint('Error searching patients: $e');
      return [];
    }
  }

  // Stream patients (real-time updates)
  Stream<List<Patient>> streamPatients({String? userId}) {
    try {
      Query query;
      
      if (userId != null) {
        query = _firestore
            .collection('patients')
            .where('userId', isEqualTo: userId);
      } else {
        query = _firestore.collection('patients');
      }

      return query.snapshots().asyncMap((snapshot) async {
        final patients = <Patient>[];
        for (var doc in snapshot.docs) {
          final patient = Patient.fromJson(doc.data() as Map<String, dynamic>);
          final visits = await getPatientVisits(patient.id);
          patients.add(patient.copyWith(visits: visits));
        }
        return patients;
      });
    } catch (e) {
      debugPrint('Error streaming patients: $e');
      return Stream.value([]);
    }
  }
}

