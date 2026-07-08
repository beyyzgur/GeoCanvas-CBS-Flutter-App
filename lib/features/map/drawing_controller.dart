import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants.dart';
import '../../models/envanter.dart';
import '../../models/envanter_turu.dart';
import '../../services/wkt_helper.dart';
import '../../services/geometry_validator.dart';
import 'drawing_mode.dart';
import 'envanter_notifier.dart';

class DrawingState {
  final DrawingMode mode;
  final List<LatLng> points;
  final List<int> vertexIds;
  final EnvanterTuru? selectedTuru;
  final Envanter? editing;
  final bool canRedo;

  const DrawingState({
    this.mode = DrawingMode.none,
    this.points = const [],
    this.vertexIds = const [],
    this.selectedTuru,
    this.editing,
    this.canRedo = false,
  });

  bool get isEditing => editing != null;
  bool get canUndo => points.isNotEmpty;
  bool get isActive => points.isNotEmpty || canRedo;
  String get geometryType => mode.geometryType;

  DrawingState copyWith({
    DrawingMode? mode,
    List<LatLng>? points,
    List<int>? vertexIds,
    EnvanterTuru? selectedTuru,
    Envanter? editing,
    bool? canRedo,
  }) => DrawingState(
    mode: mode ?? this.mode,
    points: points ?? this.points,
    vertexIds: vertexIds ?? this.vertexIds,
    selectedTuru: selectedTuru ?? this.selectedTuru,
    editing: editing ?? this.editing,
    canRedo: canRedo ?? this.canRedo,
  );
}

class DrawingController extends Notifier<DrawingState> {
  final List<LatLng> _redoStack = [];
  int _seq = 0;

  @override
  DrawingState build() => const DrawingState();

  static LatLng midpoint(LatLng a, LatLng b) =>
      LatLng((a.latitude + b.latitude) / 2, (a.longitude + b.longitude) / 2);

  static LatLng _extend(LatLng inner, LatLng end) => LatLng(
    2 * end.latitude - inner.latitude,
    2 * end.longitude - inner.longitude,
  );

  void selectTool(DrawingMode mode, EnvanterTuru tur) {
    _redoStack.clear();
    state = DrawingState(mode: mode, selectedTuru: tur);
  }

  void startEdit(Envanter e) {
    final pts = WktHelper.parseWkt(e.geometryWkt);
    final mode = e.geometryType == GeometryTypes.point
        ? DrawingMode.point
        : e.geometryType == GeometryTypes.line
        ? DrawingMode.line
        : DrawingMode.polygon;
    _redoStack.clear();
    state = DrawingState(
      mode: mode,
      editing: e,
      points: List.unmodifiable(pts),
      vertexIds: List.unmodifiable(List.generate(pts.length, (_) => _seq++)),
    );
  }

  void reset() {
    _redoStack.clear();
    state = const DrawingState();
  }

  void addTapPoint(LatLng p) {
    if (state.mode == DrawingMode.none) return;
    _redoStack.clear();
    if (state.mode == DrawingMode.point) {
      state = state.copyWith(points: [p], vertexIds: [_seq++], canRedo: false);
    } else {
      state = state.copyWith(
        points: [...state.points, p],
        vertexIds: [...state.vertexIds, _seq++],
        canRedo: false,
      );
    }
  }

  void insertPoint(int index, LatLng p) {
    _redoStack.clear();
    state = state.copyWith(
      points: [...state.points]..insert(index, p),
      vertexIds: [...state.vertexIds]..insert(index, _seq++),
      canRedo: false,
    );
  }

  void moveVertex(int i, LatLng p) {
    final pts = [...state.points]..[i] = p;
    state = state.copyWith(points: pts);
  }

  void extendLine(int endIndex) {
    final pts = state.points;
    if (pts.length < 2) return;
    if (endIndex == 0) {
      insertPoint(0, _extend(pts[1], pts[0]));
    } else {
      _redoStack.clear();
      final ep = _extend(pts[pts.length - 2], pts[pts.length - 1]);
      state = state.copyWith(
        points: [...pts, ep],
        vertexIds: [...state.vertexIds, _seq++],
        canRedo: false,
      );
    }
  }

  LatLng? undo() {
    if (!state.canUndo) return null;
    final removed = state.points.last;
    _redoStack.add(removed);
    state = state.copyWith(
      points: [...state.points]..removeLast(),
      vertexIds: [...state.vertexIds]..removeLast(),
      canRedo: true,
    );
    return removed;
  }

  LatLng? redo() {
    if (_redoStack.isEmpty) return null;
    final p = _redoStack.removeLast();
    state = state.copyWith(
      points: [...state.points, p],
      vertexIds: [...state.vertexIds, _seq++],
      canRedo: _redoStack.isNotEmpty,
    );
    return p;
  }

  String? countError() {
    final pts = WktHelper.clean(state.points);
    if (state.mode == DrawingMode.line && pts.length < 2) {
      return 'Çizgi için en az 2 farklı nokta gerekli';
    }
    if (state.mode == DrawingMode.polygon && pts.length < 3) {
      return 'Alan için en az 3 farklı nokta gerekli';
    }
    return null;
  }

  String currentWkt() =>
      WktHelper.fromPoints(state.geometryType, WktHelper.clean(state.points));

  Future<String?> validateRules() async {
    final pts = WktHelper.clean(state.points);
    if (pts.isEmpty) return null;
    final geomType = state.geometryType;
    if (geomType == GeometryTypes.line && pts.length < 2) return null;
    if (geomType == GeometryTypes.polygon && pts.length < 3) return null;
    final wkt = WktHelper.fromPoints(geomType, pts);
    final turName = state.editing?.inventoryType ?? state.selectedTuru?.name;

    final list = await ref.read(envanterlerProvider.future);
    final kurallar = await ref.read(kurallarProvider.future);
    final req = GeoValidationRequest(
      rules: [
        for (final k in kurallar)
          {
            'sourceType': k.sourceType,
            'targetType': k.targetType,
            'predicate': k.predicate,
            'ruleType': k.ruleType,
            'message': k.message,
          },
      ],
      existing: [
        for (final e in list)
          {'id': e.id, 'inventoryType': e.inventoryType, 'wkt': e.geometryWkt},
      ],
      geometryType: geomType,
      wkt: wkt,
      flatPoints: [
        for (final p in pts) ...[p.latitude, p.longitude],
      ],
      excludeId: state.editing?.id,
      turName: turName,
    );
    return compute(runGeometryValidation, req);
  }

  Future<String?> commitGeometryEdit() async {
    final e = state.editing;
    if (e == null) return null;
    final cErr = countError();
    if (cErr != null) return cErr;
    final rErr = await validateRules();
    if (rErr != null) return rErr;
    await ref
        .read(envanterlerProvider.notifier)
        .edit(e.copyWith(geometryWkt: currentWkt()));
    reset();
    return null;
  }
}

final drawingControllerProvider =
    NotifierProvider<DrawingController, DrawingState>(DrawingController.new);
