class Kural {
  final int id;
  final String sourceType;
  final String targetType;
  final String predicate;
  final String ruleType;
  final String message;
  final bool isActive;

  Kural({
    required this.id,
    required this.sourceType,
    required this.targetType,
    required this.predicate,
    required this.ruleType,
    required this.message,
    this.isActive = true,
  });

  factory Kural.fromMap(Map<String, dynamic> m) => Kural(
        id: m['id'] as int,
        sourceType: m['source_type'] as String,
        targetType: m['target_type'] as String,
        predicate: m['predicate'] as String,
        ruleType: m['rule_type'] as String,
        message: m['message'] as String,
        isActive: m['is_active'] == true || m['is_active'] == 1,
      );
}
