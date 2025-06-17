class Level {
  final int level;
  final String category;
  final List<String> instructions;
  final String solution;

  Level({
    required this.level,
    required this.category,
    required this.instructions,
    required this.solution,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      level: json['level'] as int,
      category: json['category'] as String,
      instructions: List<String>.from(json['instructions'] as List<dynamic>),
      solution: json['solution'] as String,
    );
  }
}
