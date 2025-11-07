import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';
import '../models/patient_visit.dart';

class PatientService {
  static const String _patientsKey = 'sagalyze_patients';
  static const String _visitsKey = 'sagalyze_visits';

  // Get all patients
  Future<List<Patient>> getAllPatients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientsJson = prefs.getString(_patientsKey);
      
      if (patientsJson == null) return [];
      
      final List<dynamic> patientsList = json.decode(patientsJson);
      final List<Patient> patients = [];
      
      for (var patientJson in patientsList) {
        final patient = Patient.fromJson(patientJson);
        // Load visits for this patient
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
    final patients = await getAllPatients();
    try {
      return patients.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Save patient
  Future<bool> savePatient(Patient patient) async {
    try {
      final patients = await getAllPatients();
      
      // Remove existing patient if updating
      patients.removeWhere((p) => p.id == patient.id);
      
      // Add updated patient
      patients.add(patient);
      
      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      final patientsJson = json.encode(
        patients.map((p) => p.toJson()).toList(),
      );
      
      return await prefs.setString(_patientsKey, patientsJson);
    } catch (e) {
      debugPrint('Error saving patient: $e');
      return false;
    }
  }

  // Delete patient
  Future<bool> deletePatient(String id) async {
    try {
      final patients = await getAllPatients();
      patients.removeWhere((p) => p.id == id);
      
      // Also delete visits
      await deletePatientVisits(id);
      
      final prefs = await SharedPreferences.getInstance();
      final patientsJson = json.encode(
        patients.map((p) => p.toJson()).toList(),
      );
      
      return await prefs.setString(_patientsKey, patientsJson);
    } catch (e) {
      debugPrint('Error deleting patient: $e');
      return false;
    }
  }

  // Get visits for a patient
  Future<List<PatientVisit>> getPatientVisits(String patientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final visitsJson = prefs.getString('$_visitsKey$patientId');
      
      if (visitsJson == null) return [];
      
      final List<dynamic> visitsList = json.decode(visitsJson);
      return visitsList.map((v) => PatientVisit.fromJson(v as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading visits: $e');
      return [];
    }
  }

  // Save visit for a patient
  Future<bool> savePatientVisit(String patientId, PatientVisit visit) async {
    try {
      final visits = await getPatientVisits(patientId);
      visits.add(visit);
      
      final prefs = await SharedPreferences.getInstance();
      final visitsJson = json.encode(
        visits.map((v) => v.toJson()).toList(),
      );
      
      // Update patient's last visit
      final patient = await getPatientById(patientId);
      if (patient != null) {
        await savePatient(patient.copyWith(
          lastVisit: visit.date,
          visits: visits,
        ));
      }
      
      return await prefs.setString('$_visitsKey$patientId', visitsJson);
    } catch (e) {
      debugPrint('Error saving visit: $e');
      return false;
    }
  }

  // Delete all visits for a patient
  Future<bool> deletePatientVisits(String patientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove('$_visitsKey$patientId');
    } catch (e) {
      debugPrint('Error deleting visits: $e');
      return false;
    }
  }

  // Search patients
  Future<List<Patient>> searchPatients(String query) async {
    final patients = await getAllPatients();
    if (query.isEmpty) return patients;
    
    final lowerQuery = query.toLowerCase();
    return patients.where((patient) {
      return patient.name.toLowerCase().contains(lowerQuery) ||
          patient.phoneNumber.contains(query) ||
          patient.email.toLowerCase().contains(lowerQuery) ||
          patient.id.toLowerCase().contains(lowerQuery);
    }).toList();
  }

}

