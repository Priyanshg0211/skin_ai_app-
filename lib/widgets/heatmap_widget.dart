import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/heatmap_data.dart';

class HeatmapWidget extends StatelessWidget {
  final List<List<double>> heatmapData;
  final int gridSize;
  final String title;
  final ColorScheme colorScheme;
  final bool showLegend;
  final bool showGrid;
  final Function(int x, int y, double intensity)? onCellTap;

  const HeatmapWidget({
    super.key,
    required this.heatmapData,
    this.gridSize = 20,
    this.title = 'Heat Map',
    this.colorScheme = const ColorScheme.light(),
    this.showLegend = true,
    this.showGrid = true,
    this.onCellTap,
  });

  Color _getColorForIntensity(double intensity) {
    // Normalize intensity to 0-1 range
    final normalized = intensity.clamp(0.0, 1.0);
    
    // Create gradient from blue (low) -> green -> yellow -> red (high)
    if (normalized < 0.25) {
      // Blue to Cyan
      final t = normalized / 0.25;
      return Color.lerp(
        const Color(0xFF2196F3), // Blue
        const Color(0xFF00BCD4), // Cyan
        t,
      )!;
    } else if (normalized < 0.5) {
      // Cyan to Green
      final t = (normalized - 0.25) / 0.25;
      return Color.lerp(
        const Color(0xFF00BCD4), // Cyan
        const Color(0xFF4CAF50), // Green
        t,
      )!;
    } else if (normalized < 0.75) {
      // Green to Yellow
      final t = (normalized - 0.5) / 0.25;
      return Color.lerp(
        const Color(0xFF4CAF50), // Green
        const Color(0xFFFFEB3B), // Yellow
        t,
      )!;
    } else {
      // Yellow to Red
      final t = (normalized - 0.75) / 0.25;
      return Color.lerp(
        const Color(0xFFFFEB3B), // Yellow
        const Color(0xFFF44336), // Red
        t,
      )!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = heatmapData.length;
    final cols = rows > 0 ? heatmapData[0].length : 0;
    
    if (rows == 0 || cols == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No heatmap data available',
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ),
      );
    }

    // Find min and max for normalization
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;
    
    for (var row in heatmapData) {
      for (var val in row) {
        if (val < minVal) minVal = val;
        if (val > maxVal) maxVal = val;
      }
    }

    final range = maxVal - minVal;
    final normalizedData = heatmapData.map((row) {
      return row.map((val) {
        return range > 0 ? (val - minVal) / range : 0.0;
      }).toList();
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Heatmap Grid
          Container(
            decoration: BoxDecoration(
              border: showGrid
                  ? Border.all(color: Colors.grey[300]!, width: 1)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
                children: List.generate(rows, (rowIndex) {
                  return Row(
                    children: List.generate(cols, (colIndex) {
                      final intensity = normalizedData[rowIndex][colIndex];
                      final color = _getColorForIntensity(intensity);
                      
                      return GestureDetector(
                        onTap: onCellTap != null
                            ? () => onCellTap!(colIndex, rowIndex, intensity)
                            : null,
                        child: Container(
                          width: gridSize.toDouble(),
                          height: gridSize.toDouble(),
                          color: color,
                          child: showGrid
                              ? Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
          // Legend
          if (showLegend) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Low',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2196F3), // Blue
                          const Color(0xFF00BCD4), // Cyan
                          const Color(0xFF4CAF50), // Green
                          const Color(0xFFFFEB3B), // Yellow
                          const Color(0xFFF44336), // Red
                        ],
                      ),
                    ),
                  ),
                ),
                Text(
                  'High',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min: ${minVal.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Max: ${maxVal.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

