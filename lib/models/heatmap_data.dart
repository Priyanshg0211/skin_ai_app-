class HeatmapData {
  final int x;
  final int y;
  final double intensity; // 0.0 to 1.0
  final String? label;

  HeatmapData({
    required this.x,
    required this.y,
    required this.intensity,
    this.label,
  });
}

class HeatmapRegion {
  final List<HeatmapData> dataPoints;
  final String regionName;
  final double averageIntensity;
  final double maxIntensity;
  final double minIntensity;

  HeatmapRegion({
    required this.dataPoints,
    required this.regionName,
    required this.averageIntensity,
    required this.maxIntensity,
    required this.minIntensity,
  });

  static HeatmapRegion fromDataPoints(List<HeatmapData> points, String name) {
    if (points.isEmpty) {
      return HeatmapRegion(
        dataPoints: [],
        regionName: name,
        averageIntensity: 0.0,
        maxIntensity: 0.0,
        minIntensity: 0.0,
      );
    }

    final intensities = points.map((p) => p.intensity).toList();
    final sum = intensities.fold(0.0, (a, b) => a + b);
    final avg = sum / intensities.length;
    final max = intensities.reduce((a, b) => a > b ? a : b);
    final min = intensities.reduce((a, b) => a < b ? a : b);

    return HeatmapRegion(
      dataPoints: points,
      regionName: name,
      averageIntensity: avg,
      maxIntensity: max,
      minIntensity: min,
    );
  }
}

