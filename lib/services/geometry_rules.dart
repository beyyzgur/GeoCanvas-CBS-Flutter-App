import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:projection_cs/projection_cs.dart';

class GeometryRules {
  static bool intersects(String wktA, String wktB) {
    try {
      return WktGenerator.intersects(wktGeometry1: wktA, wktGeometry2: wktB);
    } catch (e) {
      debugPrint('GeometryRules.intersects hatası: $e');
      return false;
    }
  }

  static bool within(String wktA, String wktB) {
    try {
      return WktGenerator.within(wktGeometry1: wktA, wktGeometry2: wktB);
    } catch (e) {
      debugPrint('GeometryRules.within hatası: $e');
      return false;
    }
  }

  static bool contains(String wktA, String wktB) {
    try {
      return WktGenerator.contains(wktGeometry1: wktA, wktGeometry2: wktB);
    } catch (e) {
      debugPrint('GeometryRules.contains hatası: $e');
      return false;
    }
  }

  static bool isSelfIntersecting(List<LatLng> pts) {
    final n = pts.length;
    if (n < 4) return false;
    final ring = [...pts, pts.first];
    final edgeCount = ring.length - 1;
    for (int i = 0; i < edgeCount; i++) {
      for (int j = i + 1; j < edgeCount; j++) {
        if (j == i + 1) continue;
        if (i == 0 && j == edgeCount - 1) continue;
        if (_segmentsCross(ring[i], ring[i + 1], ring[j], ring[j + 1])) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _segmentsCross(LatLng p1, LatLng p2, LatLng p3, LatLng p4) {
    final d1 = _cross(p3, p4, p1);
    final d2 = _cross(p3, p4, p2);
    final d3 = _cross(p1, p2, p3);
    final d4 = _cross(p1, p2, p4);
    return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0));
  }

  static double _cross(LatLng a, LatLng b, LatLng c) {
    return (b.longitude - a.longitude) * (c.latitude - a.latitude) -
        (b.latitude - a.latitude) * (c.longitude - a.longitude);
  }
}
