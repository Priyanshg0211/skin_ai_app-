import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_visit.dart';

class PatientSummaryScreen extends StatelessWidget {
  // For direct analysis view
  final String? result;
  final double? confidence;
  final List<String>? symptoms;
  final Uint8List? imageBytes;
  
  // For patient visit view
  final String? patientName;
  final String? patientId;
  final PatientVisit? visit;

  const PatientSummaryScreen({
    super.key,
    // Direct analysis parameters
    this.result,
    this.confidence,
    this.symptoms,
    this.imageBytes,
    // Patient visit parameters
    this.patientName,
    this.patientId,
    this.visit,
  }) : assert(
          (result != null && confidence != null && symptoms != null) ||
          (patientName != null && patientId != null && visit != null),
          'Either provide analysis data or visit data',
        );

  // Helper getters to handle both cases
  String get _displayResult => visit?.condition ?? result ?? 'N/A';
  double get _displayConfidence => visit?.confidence ?? confidence ?? 0.0;
  List<String> get _displaySymptoms => visit?.symptoms ?? symptoms ?? [];
  Uint8List? get _displayImageBytes => visit?.imageBytes ?? imageBytes;
  String get _displayTitle => patientName != null ? '$patientName\'s Visit Summary' : 'Your Progress Summary';
  String get _displayDate => visit != null 
      ? 'Visit Date: ${visit!.date.day}/${visit!.date.month}/${visit!.date.year}'
      : 'Generated: ${DateTime.now().toString().substring(0, 16)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _displayTitle,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.medical_information,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    visit != null ? 'Visit Report' : 'Treatment Progress Report',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _displayDate,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_displayImageBytes != null && _displayImageBytes!.isNotEmpty) ...[
              Text(
                'Visual Progress',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  _displayImageBytes!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Condition/Result Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.medical_services, color: Colors.blue[700], size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Condition',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                        Text(
                          _displayResult,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: ${(_displayConfidence * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (visit != null) ...[
              _buildVisitMetrics(),
              const SizedBox(height: 24),
            ],
            if (visit?.notes != null && visit!.notes!.isNotEmpty) ...[
              Text(
                'Notes',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  visit!.notes!,
                  style: GoogleFonts.inter(fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (_displaySymptoms.isNotEmpty) ...[
              Text(
                'Reported Symptoms',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _displaySymptoms
                    .map(
                      (s) => Chip(
                        label: Text(s, style: GoogleFonts.inter(fontSize: 12)),
                        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Text(
                        'Progress Update',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your treatment is progressing well. Continue following your prescribed regimen.',
                    style: GoogleFonts.inter(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Important Disclaimer',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This summary is for informational purposes only. It does NOT include medical diagnoses, condition names, or treatment recommendations. Please consult your dermatologist for all medical decisions.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.red[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitMetrics() {
    if (visit == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visit Metrics',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Redness',
                '${visit!.rednessIndex.toStringAsFixed(1)}%',
                Colors.red,
                Icons.water_drop,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Lesion Area',
                '${visit!.lesionArea.toStringAsFixed(1)}%',
                Colors.blue,
                Icons.area_chart,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Pigmentation',
                '${visit!.pigmentation.toStringAsFixed(1)}%',
                Colors.brown,
                Icons.palette,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Confidence',
                '${(visit!.confidence * 100).toStringAsFixed(1)}%',
                Colors.green,
                Icons.check_circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

