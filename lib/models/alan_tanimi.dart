class AlanTanimi {
  final int id;
  final int? turId;
  final String fieldKey;
  final String label;
  final String fieldType;
  final String? options;
  final int sortOrder;
  final bool isRequired;

  AlanTanimi({
    required this.id,
    required this.turId,
    required this.fieldKey,
    required this.label,
    required this.fieldType,
    this.options,
    this.sortOrder = 0,
    this.isRequired = false,
  });

  factory AlanTanimi.fromMap(Map<String, dynamic> m) => AlanTanimi(
    id: m['id'] as int,
    turId: m['tur_id'] as int?,
    fieldKey: m['field_key'] as String,
    label: m['label'] as String,
    fieldType: m['field_type'] as String,
    options: m['options'] as String?,
    sortOrder: m['sort_order'] as int? ?? 0,
    isRequired: m['is_required'] == true || m['is_required'] == 1,
  );

  List<String> get optionList => (options ?? '')
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
