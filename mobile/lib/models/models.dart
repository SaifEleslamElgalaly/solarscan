class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}

class ScanResult {
  final int id;
  final String imagePath;
  final String result;
  final double confidence;
  final String recommendation;
  final List<double>? box;
  final DateTime createdAt;

  ScanResult({
    required this.id,
    required this.imagePath,
    required this.result,
    required this.confidence,
    required this.recommendation,
    this.box,
    required this.createdAt,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    List<double>? boxCoords;
    if (json['box'] != null && json['box'] is List) {
      boxCoords = (json['box'] as List).map((b) => (b as num).toDouble()).toList();
    }
    return ScanResult(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      imagePath: json['image_path'] ?? '',
      result: json['result'] ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      recommendation: json['recommendation'] ?? '',
      box: boxCoords,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}
