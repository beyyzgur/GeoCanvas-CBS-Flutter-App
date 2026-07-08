import 'package:latlong2/latlong.dart';
import '../models/envanter.dart';
import '../models/kural.dart';
import 'geometry_rules.dart';
import '../core/constants.dart';

class GeometryValidator {
  final List<Kural> rules;
  final List<Envanter> existing;

  const GeometryValidator({required this.rules, required this.existing});

  String? validate({
    required String geometryType,
    required String wkt,
    required List<LatLng> points,
    int? excludeId,
    String? turName,
  }) {

    if (geometryType == GeometryTypes.polygon &&
        GeometryRules.isSelfIntersecting(points)) {
      return 'Geçersiz alan: kenarlar birbirini kesiyor. Köşeleri düzeltin.';
    }

    final tur = turName ?? '';

    bool sourceMatch(Kural k) =>
        k.sourceType == RuleScope.any || k.sourceType == tur;
    bool targetMatch(Kural k, Envanter e) =>
        k.targetType == RuleScope.any ||
        k.targetType == (e.inventoryType ?? '');
    bool holds(String predicate, String otherWkt) {
      switch (predicate) {
        case Predicate.within:
          return GeometryRules.within(wkt, otherWkt);
        case Predicate.contains:
          return GeometryRules.contains(wkt, otherWkt);
        default:
          return GeometryRules.intersects(wkt, otherWkt);
      }
    }

    final requiredTargets = rules
        .where((k) => k.ruleType == RuleType.required && sourceMatch(k))
        .map((k) => k.targetType)
        .toSet();

    for (final k in rules.where(
      (k) => k.ruleType == RuleType.required && sourceMatch(k),
    )) {
      final hedefler =
          existing.where((e) => e.id != excludeId && targetMatch(k, e));
      final ok = hedefler.any((e) => holds(k.predicate, e.geometryWkt));
      if (!ok) return k.message;
    }

    for (final k in rules.where(
      (k) => k.ruleType == RuleType.forbidden && sourceMatch(k),
    )) {
      for (final e in existing) {
        if (e.id == excludeId) continue;
        if (!targetMatch(k, e)) continue;
        if (requiredTargets.contains(e.inventoryType)) continue;
        if (holds(k.predicate, e.geometryWkt)) return k.message;
      }
    }
    return null;
  }
}

class GeoValidationRequest {
  final List<Map<String, String>> rules;
  final List<Map<String, dynamic>> existing;
  final String geometryType;
  final String wkt;
  final List<double> flatPoints;
  final int? excludeId;
  final String? turName;

  const GeoValidationRequest({
    required this.rules,
    required this.existing,
    required this.geometryType,
    required this.wkt,
    required this.flatPoints,
    this.excludeId,
    this.turName,
  });
}

String? runGeometryValidation(GeoValidationRequest r) {
  final rules = r.rules
      .map((m) => Kural(
            id: 0,
            sourceType: m['sourceType'] ?? RuleScope.any,
            targetType: m['targetType'] ?? RuleScope.any,
            predicate: m['predicate'] ?? Predicate.intersects,
            ruleType: m['ruleType'] ?? RuleType.forbidden,
            message: m['message'] ?? '',
          ))
      .toList();
  final existing = r.existing
      .map((m) => Envanter(
            id: m['id'] as int?,
            recordUserId: '',
            geometryType: '',
            inventoryType: m['inventoryType'] as String?,
            name: '',
            geometryWkt: m['wkt'] as String,
          ))
      .toList();
  final pts = <LatLng>[];
  for (var i = 0; i + 1 < r.flatPoints.length; i += 2) {
    pts.add(LatLng(r.flatPoints[i], r.flatPoints[i + 1]));
  }
  return GeometryValidator(rules: rules, existing: existing).validate(
    geometryType: r.geometryType,
    wkt: r.wkt,
    points: pts,
    excludeId: r.excludeId,
    turName: r.turName,
  );
}
