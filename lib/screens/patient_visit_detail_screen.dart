import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import '../models/patient.dart';
import '../models/patient_visit.dart';
import '../widgets/heatmap_widget.dart';

class PatientVisitDetailScreen extends StatelessWidget {
  final Patient patient;
  final PatientVisit visit;

  const PatientVisitDetailScreen({
    super.key,
    required this.patient,
    required this.visit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Visit Details',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient Info Card
            _buildInfoCard(
              'Patient Information',
              [
                _buildInfoRow('Name', patient.name),
                _buildInfoRow('Age', '${patient.age} years'),
                _buildInfoRow('Gender', patient.gender),
                _buildInfoRow('Skin Type', 'Fitzpatrick ${patient.skinType}'),
              ],
            ),
            const SizedBox(height: 16),
            // Visit Date
            _buildInfoCard(
              'Visit Information',
              [
                _buildInfoRow(
                  'Date',
                  '${visit.date.day}/${visit.date.month}/${visit.date.year}',
                ),
                _buildInfoRow('Time', '${visit.date.hour}:${visit.date.minute.toString().padLeft(2, '0')}'),
                _buildInfoRow('Condition', visit.condition),
                _buildInfoRow('Confidence', '${visit.confidence.toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 16),
            // Image
            if (visit.imageBytes.isNotEmpty) ...[
              _buildImageSection(context),
              const SizedBox(height: 16),
            ],
            // Metrics
            _buildMetricsCard(),
            const SizedBox(height: 16),
            // Heatmap
            _buildHeatmapSection(),
            if (visit.notes != null && visit.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNotesCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Lesion Image',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Full Image'),
                      backgroundColor: Colors.black,
                    ),
                    backgroundColor: Colors.black,
                    body: PhotoView(
                      imageProvider: MemoryImage(visit.imageBytes),
                    ),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.memory(
                visit.imageBytes,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analysis Metrics',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Redness Index',
                    '${visit.rednessIndex.toStringAsFixed(1)}%',
                    Colors.red,
                    Icons.water_drop,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricItem(
                    'Lesion Area',
                    '${visit.lesionArea.toStringAsFixed(1)}%',
                    Colors.blue,
                    Icons.area_chart,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricItem(
              'Pigmentation',
              '${visit.pigmentation.toStringAsFixed(1)}%',
              Colors.brown,
              Icons.palette,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapSection() {
    // Generate heatmap data from visit metrics
    final heatmapData = List.generate(10, (i) {
      return List.generate(10, (j) {
        // Create a gradient pattern based on metrics
        final centerX = 5.0;
        final centerY = 5.0;
        final distance = math.sqrt((i - centerX) * (i - centerX) + (j - centerY) * (j - centerY));
        final maxDistance = math.sqrt(centerX * centerX + centerY * centerY);
        final normalizedDistance = (maxDistance - distance) / maxDistance;
        
        // Combine metrics for intensity
        final intensity = (visit.rednessIndex * 0.4 + 
                          visit.lesionArea * 0.3 + 
                          visit.pigmentation * 0.3) / 100.0;
        
        return (intensity * normalizedDistance).clamp(0.0, 1.0);
      });
    });

    return HeatmapWidget(
      heatmapData: heatmapData,
      title: 'Lesion Heat Map',
      gridSize: 25,
    );
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clinical Notes',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              visit.notes!,
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

