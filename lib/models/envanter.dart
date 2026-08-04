import 'dart:convert';
import '../core/constants.dart';

class Envanter {
  final int? id;
  final String recordUserId;
  final String geometryType;
  final String? inventoryType;
  final String name;
  final String? description;
  final String status;
  final String geometryWkt;
  final Map<String, dynamic> attributes;
  final String? createdAt;

  Envanter({
    this.id,
    required this.recordUserId,
    required this.geometryType,
    this.inventoryType,
    required this.name,
    this.description,
    this.status = EnvanterStatus.aktif,
    required this.geometryWkt,
    this.attributes = const {},
    this.createdAt,
  });

  Envanter copyWith({
    int? id,
    String? recordUserId,
    String? geometryType,
    String? inventoryType,
    String? name,
    String? description,
    String? status,
    String? geometryWkt,
    Map<String, dynamic>? attributes,
    String? createdAt,
  }) => Envanter(
    id: id ?? this.id,
    recordUserId: recordUserId ?? this.recordUserId,
    geometryType: geometryType ?? this.geometryType,
    inventoryType: inventoryType ?? this.inventoryType,
    name: name ?? this.name,
    description: description ?? this.description,
    status: status ?? this.status,
    geometryWkt: geometryWkt ?? this.geometryWkt,
    attributes: attributes ?? this.attributes,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'record_user_id': recordUserId,
    'geometry_type': geometryType,
    'inventory_type': inventoryType,
    'name': name,
    'description': description,
    'status': status,
    'geometry_wkt': geometryWkt,
    'attributes': jsonEncode(attributes),
    'created_at': createdAt,
  };

  factory Envanter.fromMap(Map<String, dynamic> m) => Envanter(
    id: m['id'] as int?,
    recordUserId: m['record_user_id'] as String,
    geometryType: m['geometry_type'] as String,
    inventoryType: m['inventory_type'] as String?,
    name: m['name'] as String,
    description: m['description'] as String?,
    status: m['status'] as String? ?? EnvanterStatus.aktif,
    geometryWkt: m['geometry_wkt'] as String,
    attributes:
        (m['attributes'] != null && (m['attributes'] as String).isNotEmpty)
        ? jsonDecode(m['attributes'] as String) as Map<String, dynamic>
        : const {},
    createdAt: m['created_at'] as String?,
  );
}
