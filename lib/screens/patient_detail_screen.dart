import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';
import '../services/firebase_patient_service.dart';
import 'patient_visit_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient? patient;

  const PatientDetailScreen({
    super.key,
    this.patient,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebasePatientService _patientService = FirebasePatientService();
  final _uuid = const Uuid();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _medicalHistoryController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;

  DateTime? _dateOfBirth;
  String _gender = 'Male';
  String _skinType = 'III';
  bool _isSaving = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _skinTypes = ['I', 'II', 'III', 'IV', 'V', 'VI'];

  @override
  void initState() {
    super.initState();
    final patient = widget.patient;
    _nameController = TextEditingController(text: patient?.name ?? '');
    _phoneController = TextEditingController(text: patient?.phoneNumber ?? '');
    _emailController = TextEditingController(text: patient?.email ?? '');
    _addressController = TextEditingController(text: patient?.address ?? '');
    _medicalHistoryController = TextEditingController(text: patient?.medicalHistory ?? '');
    _allergiesController = TextEditingController(text: patient?.allergies.join(', ') ?? '');
    _medicationsController = TextEditingController(text: patient?.medications.join(', ') ?? '');
    _dateOfBirth = patient?.dateOfBirth;
    _gender = patient?.gender ?? 'Male';
    _skinType = patient?.skinType ?? 'III';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final patient = Patient(
      id: widget.patient?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      dateOfBirth: _dateOfBirth!,
      gender: _gender,
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      medicalHistory: _medicalHistoryController.text.trim(),
      allergies: _allergiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      medications: _medicationsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      skinType: _skinType,
      createdAt: widget.patient?.createdAt ?? DateTime.now(),
      visits: widget.patient?.visits ?? [],
      lastVisit: widget.patient?.lastVisit,
    );

    final success = await _patientService.savePatient(patient);
    setState(() => _isSaving = false);

    if (success) {
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.patient == null
                ? 'Patient added successfully'
                : 'Patient updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving patient'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.patient != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Patient' : 'New Patient',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          if (isEditing && widget.patient!.visits.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientVisitScreen(
                      patient: widget.patient!,
                    ),
                  ),
                );
              },
              tooltip: 'View Visits',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Information
              _buildSectionHeader('Basic Information'),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter patient name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDateOfBirth,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date of Birth *',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _dateOfBirth != null
                              ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                              : 'Select date',
                          style: GoogleFonts.inter(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: InputDecoration(
                        labelText: 'Gender *',
                        prefixIcon: const Icon(Icons.wc),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _genders.map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _gender = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _skinType,
                decoration: InputDecoration(
                  labelText: 'Fitzpatrick Skin Type *',
                  prefixIcon: const Icon(Icons.color_lens),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'I (lightest) to VI (darkest)',
                ),
                items: _skinTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text('Type $type'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _skinType = value);
                },
              ),

              // Contact Information
              const SizedBox(height: 24),
              _buildSectionHeader('Contact Information'),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),

              // Medical Information
              const SizedBox(height: 24),
              _buildSectionHeader('Medical Information'),
              TextFormField(
                controller: _medicalHistoryController,
                decoration: InputDecoration(
                  labelText: 'Medical History',
                  prefixIcon: const Icon(Icons.medical_services),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  labelText: 'Allergies (comma-separated)',
                  prefixIcon: const Icon(Icons.warning),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'e.g., Penicillin, Latex, Pollen',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _medicationsController,
                decoration: InputDecoration(
                  labelText: 'Current Medications (comma-separated)',
                  prefixIcon: const Icon(Icons.medication),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  helperText: 'e.g., Aspirin, Metformin',
                ),
              ),

              // Save Button
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing ? 'Update Patient' : 'Save Patient',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF6C63FF),
        ),
      ),
    );
  }
}

