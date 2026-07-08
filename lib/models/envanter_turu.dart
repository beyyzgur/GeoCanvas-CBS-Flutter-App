class EnvanterTuru {
  final int id;
  final String geometryType;
  final String name;
  final String? icon;
  final int sortOrder;

  EnvanterTuru({
    required this.id,
    required this.geometryType,
    required this.name,
    required this.icon,
    this.sortOrder = 0,
  });

  @override
  bool operator ==(Object other) => other is EnvanterTuru && other.id == id;

  @override
  int get hashCode => id.hashCode;

  factory EnvanterTuru.fromMap(Map<String, dynamic> m) => EnvanterTuru(
    id: m['id'] as int,
    geometryType: m['geometry_type'] as String,
    name: m['name'] as String,
    icon: m['icon'] as String?,
    sortOrder: m['sort_order'] as int? ?? 0,
  );
}
