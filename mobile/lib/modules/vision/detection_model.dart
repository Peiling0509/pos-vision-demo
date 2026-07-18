class DetectionModel {
  final String label;
  final double confidence;
  final List<double> box;

  DetectionModel({
    required this.label,
    required this.confidence,
    required this.box,
  });

  factory DetectionModel.fromJson(Map<String, dynamic> json) {
    return DetectionModel(
      // We check for both 'label' and 'item_name' to ensure compatibility with your Python AI
      label: json['label'] ?? json['item_name'] ?? 'Unknown',

      // Safely parse the confidence to a double
      confidence: (json['confidence'] ?? 0.0).toDouble(),

      // Safely map the dynamic list to a List<double>
      box: (json['box'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
          [0.0, 0.0, 0.0, 0.0],
    );
  }
}