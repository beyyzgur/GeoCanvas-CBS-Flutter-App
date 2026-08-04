import 'package:latlong2/latlong.dart';
import '../core/constants.dart';

class WktHelper {

  static List<LatLng> clean(List<LatLng> pts) {
    const eps = 1e-8;
    bool same(LatLng a, LatLng b) =>
        (a.latitude - b.latitude).abs() < eps &&
        (a.longitude - b.longitude).abs() < eps;
    final out = <LatLng>[];
    for (final p in pts) {
      if (out.isEmpty || !same(out.last, p)) out.add(p);
    }

    if (out.length > 1 && same(out.first, out.last)) out.removeLast();
    return out;
  }

  static String fromPoints(String geometryType, List<LatLng> rawPts) {
    final pts = clean(rawPts);
    switch (geometryType) {
      case GeometryTypes.line:
        return lineToWkt(pts);
      case GeometryTypes.polygon:
        return polygonToWkt(pts);
      default:
        return pointToWkt(pts.first);
    }
  }

  static String pointToWkt(LatLng p) => 'POINT(${p.longitude} ${p.latitude})';

  static String lineToWkt(List<LatLng> pts) {
    final coords = pts.map((p) => '${p.longitude} ${p.latitude}').join(', ');
    return 'LINESTRING($coords)';
  }

  static String polygonToWkt(List<LatLng> pts) {
    final ring = [...pts, pts.first];
    final coords = ring.map((p) => '${p.longitude} ${p.latitude}').join(', ');
    return 'POLYGON(($coords))';
  }

  static List<LatLng> parseWkt(String wkt) {
    final start = wkt.indexOf('(');
    final end = wkt.lastIndexOf(')');
    if (start == -1 || end == -1) return [];

    final body = wkt
        .substring(start + 1, end)
        .replaceAll('(', '')
        .replaceAll(')', '');

    final result = <LatLng>[];
    for (final pair in body.split(',')) {
      final parts = pair.trim().split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final lon = double.parse(parts[0]);
      final lat = double.parse(parts[1]);
      result.add(LatLng(lat, lon));
    }
    return result;
  }
}
