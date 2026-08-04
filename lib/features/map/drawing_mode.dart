import '../../core/constants.dart';

enum DrawingMode { none, point, line, polygon }

extension DrawingModeX on DrawingMode {

  String get geometryType {
    switch (this) {
      case DrawingMode.point:
        return GeometryTypes.point;
      case DrawingMode.line:
        return GeometryTypes.line;
      case DrawingMode.polygon:
        return GeometryTypes.polygon;
      case DrawingMode.none:
        return '';
    }
  }
}
