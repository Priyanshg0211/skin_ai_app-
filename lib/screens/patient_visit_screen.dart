import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient.dart';
import '../models/patient_visit.dart';
import 'patient_visit_detail_screen.dart';

class PatientVisitScreen extends StatelessWidget {
  final Patient patient;

  const PatientVisitScreen({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final visits = patient.visits..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${patient.name}\'s Visits',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: visits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No visits recorded yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visits.length,
              itemBuilder: (context, index) {
                final visit = visits[index];
                return _buildVisitCard(context, visit, index);
              },
            ),
    );
  }

  Widget _buildVisitCard(BuildContext context, PatientVisit visit, int index) {
    final daysAgo = DateTime.now().difference(visit.date).inDays;
    String timeAgo;
    if (daysAgo == 0) {
      timeAgo = 'Today';
    } else if (daysAgo == 1) {
      timeAgo = 'Yesterday';
    } else if (daysAgo < 7) {
      timeAgo = '$daysAgo days ago';
    } else if (daysAgo < 30) {
      final weeks = (daysAgo / 7).floor();
      timeAgo = '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (daysAgo / 30).floor();
      timeAgo = '$months month${months > 1 ? 's' : ''} ago';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientVisitDetailScreen(
                patient: patient,
                visit: visit,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Visit Image
              if (visit.imageBytes.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    visit.imageBytes,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(width: 16),
              // Visit Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            visit.condition,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${visit.confidence.toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMetricChip(
                          'Redness',
                          '${visit.rednessIndex.toStringAsFixed(0)}%',
                          Colors.red,
                        ),
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          'Area',
                          '${visit.lesionArea.toStringAsFixed(0)}%',
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

