import 'package:cbs_app/features/map/inventory_form_sheet.dart';
import 'package:cbs_app/features/auth/login_view.dart';
import 'package:cbs_app/features/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/wkt_helper.dart';
import '../../models/envanter.dart';
import '../../models/envanter_turu.dart';
import 'envanter_notifier.dart';
import 'drawing_controller.dart';
import '../auth/auth_viewmodel.dart';
import '../../services/location_service.dart';
import '../../core/connectivity_provider.dart';
import 'map_layer.dart';
import 'widgets/layer_switcher.dart';
import 'widgets/envanter_info_sheet.dart';
import 'widgets/map_controls.dart';
import 'widgets/app_drawer.dart';
import 'drawing_mode.dart';
import '../../core/constants.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LayerHitNotifier<int> _polygonHit = ValueNotifier(null);
  final LayerHitNotifier<int> _lineHit = ValueNotifier(null);
  double _zoom = 6.0;
  LatLng? _dragOrigin;
  LatLng? _myLocation;
  MapLayer _selectedLayer = kMapLayers.first;

  DrawingController get _ctrl => ref.read(drawingControllerProvider.notifier);
  LatLng? _pulsePoint;
  Animation<double>? _pulseAnim;
  Color _pulseColor = Colors.redAccent;
  bool _pulseOutward = true;

  void _playPulse(LatLng p, {required Color color, required bool outward}) {
    final c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    final a = CurvedAnimation(parent: c, curve: Curves.easeOut);
    setState(() {
      _pulsePoint = p;
      _pulseAnim = a;
      _pulseColor = color;
      _pulseOutward = outward;
    });
    c.addListener(() {
      if (mounted) setState(() {});
    });
    c.forward().whenComplete(() {
      c.dispose();
      if (mounted) {
        setState(() {
          _pulsePoint = null;
          _pulseAnim = null;
        });
      }
    });
  }

  void _undo() {
    final removed = _ctrl.undo();
    if (removed != null) {
      _playPulse(removed, color: Colors.redAccent, outward: true);
    }
  }

  void _redo() {
    final p = _ctrl.redo();
    if (p != null) _playPulse(p, color: Colors.green, outward: false);
  }

  List<Envanter>? _memoRecords;
  List<EnvanterTuru>? _memoTurler;
  List<Polygon<int>> _savedPolygons = [];
  List<Polyline<int>> _savedLines = [];
  List<Marker> _savedMarkers = [];

  void _rebuildSavedLayers(List<Envanter> kayitlar, List<EnvanterTuru> turler) {
    final polygons = <Polygon<int>>[];
    final lines = <Polyline<int>>[];
    final markers = <Marker>[];
    final iconByType = {
      for (final t in turler) '${t.geometryType}|${t.name}': t.icon,
    };
    for (final Envanter e in kayitlar) {
      final pts = WktHelper.parseWkt(e.geometryWkt);
      if (pts.isEmpty) continue;
      final Color c = e.status == EnvanterStatus.pasif
          ? Colors.grey
          : Colors.blue;
      final iconFile = iconByType['${e.geometryType}|${e.inventoryType}'];
      if (e.geometryType == GeometryTypes.polygon) {
        polygons.add(
          Polygon<int>(
            points: pts,
            color: c.withValues(alpha: 0.3),
            borderColor: c,
            borderStrokeWidth: 2,
            hitValue: e.id,
          ),
        );
      } else if (e.geometryType == GeometryTypes.line) {
        lines.add(
          Polyline<int>(points: pts, color: c, strokeWidth: 4, hitValue: e.id),
        );
      }
      markers.add(_iconMarker(e, _repPoint(pts, e.geometryType), iconFile));
    }
    _savedPolygons = polygons;
    _savedLines = lines;
    _savedMarkers = markers;
  }

  String _geomLabel(DrawingMode m) {
    switch (m) {
      case DrawingMode.point:
        return 'Nokta';
      case DrawingMode.line:
        return 'Çizgi';
      case DrawingMode.polygon:
        return 'Alan';
      case DrawingMode.none:
        return '';
    }
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) =>
      _ctrl.addTapPoint(point);

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _goToMyLocation() async {
    try {
      final konum = await LocationService().getCurrentLocation();
      if (!mounted) return;
      setState(() => _myLocation = konum);
      _animatedMove(konum, 16.0);
    } on LocationException catch (e) {
      if (mounted) _showMsg(e.message);
    } catch (e) {
      if (mounted) _showMsg('Konum alınamadı: $e');
    }
  }

  Future<void> _saveDrawing() async {
    final countErr = _ctrl.countError();
    if (countErr != null) {
      _showMsg(countErr);
      return;
    }
    final ruleErr = await _ctrl.validateRules();
    if (!mounted) return;
    if (ruleErr != null) {
      _showMsg(ruleErr);
      return;
    }
    final st = ref.read(drawingControllerProvider);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InventoryFormSheet(
        geometryType: st.geometryType,
        geometryWkt: _ctrl.currentWkt(),
        preselectedTuru: st.selectedTuru,
      ),
    );
    if (saved == true) {
      _ctrl.reset();
      if (mounted) _showMsg('Envanter kaydedildi ✓');
    }
  }

  Future<void> _saveGeometryEdit() async {
    final err = await _ctrl.commitGeometryEdit();
    if (!mounted) return;
    _showMsg(err ?? 'Geometri güncellendi ✓');
  }

  void _handleIdentify(LayerHitNotifier<int> notifier) {
    final result = notifier.value;
    if (result == null || result.hitValues.isEmpty) return;
    final id = result.hitValues.first;
    final list = ref.read(envanterlerProvider).value ?? [];
    Envanter? bulunan;
    for (final e in list) {
      if (e.id == id) {
        bulunan = e;
        break;
      }
    }
    if (bulunan != null) _showEnvanterPopup(bulunan);
  }

  void _showEnvanterPopup(Envanter e) {
    showModalBottomSheet(
      context: context,
      builder: (_) => EnvanterInfoSheet(
        envanter: e,
        onDelete: () => _deleteEnvanter(e),
        onEdit: () => _editEnvanter(e),
        onEditGeometry: () => _startGeometryEdit(e),
      ),
    );
  }

  Future<void> _deleteEnvanter(Envanter e) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: Text('"${e.name}" envanteri silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sil',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (onay != true) return;

    await ref.read(envanterlerProvider.notifier).remove(e.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Envanter silindi'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => ref.read(envanterlerProvider.notifier).add(e),
          ),
        ),
      );
  }

  Future<void> _editEnvanter(Envanter e) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InventoryFormSheet(
        geometryType: e.geometryType,
        geometryWkt: e.geometryWkt,
        existing: e,
      ),
    );
    if (!mounted) return;
    if (saved == true) _showMsg('Envanter güncellendi ✓');
  }

  void _startGeometryEdit(Envanter e) {
    _ctrl.startEdit(e);
    _showMsg('Köşeleri sürükleyerek düzenle, sonra Kaydet');
  }

  Future<void> _logout() async {
    await ref.read(authViewModelProvider).logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  LatLng _repPoint(List<LatLng> pts, String geo) {
    if (geo == GeometryTypes.point) return pts.first;
    if (geo == GeometryTypes.line) return pts[pts.length ~/ 2];
    double lat = 0, lng = 0;
    for (final p in pts) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / pts.length, lng / pts.length);
  }

  Marker _iconMarker(Envanter e, LatLng at, String? iconFile) {
    return Marker(
      point: at,
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () {
          if (ref.read(drawingControllerProvider).mode == DrawingMode.none) {
            _showEnvanterPopup(e);
          }
        },
        child: (iconFile != null && iconFile.isNotEmpty)
            ? Opacity(
                opacity: e.status == EnvanterStatus.pasif ? 0.45 : 1.0,
                child: Image.asset(
                  'assets/icons/$iconFile',
                  width: 34,
                  height: 34,
                ),
              )
            : Icon(
                Icons.location_on,
                size: 36,
                color: e.status == EnvanterStatus.pasif
                    ? Colors.grey
                    : Colors.blue,
              ),
      ),
    );
  }

  Marker _plusMarker(LatLng at, VoidCallback onTap, double size) {
    return Marker(
      point: at,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(Icons.add, color: Colors.white, size: size * 0.6),
        ),
      ),
    );
  }

  List<Marker> _polygonPlusMarkers(List<LatLng> pts, double size) {
    final markers = <Marker>[];
    final n = pts.length;
    for (int i = 0; i < n; i++) {
      final idx = i;
      final mid = DrawingController.midpoint(pts[idx], pts[(idx + 1) % n]);
      markers.add(
        _plusMarker(mid, () => _ctrl.insertPoint(idx + 1, mid), size),
      );
    }
    return markers;
  }

  void _animatedMove(LatLng dest, double destZoom, {int ms = 600}) {
    final cam = _mapController.camera;
    final latT = Tween<double>(begin: cam.center.latitude, end: dest.latitude);
    final lngT = Tween<double>(
      begin: cam.center.longitude,
      end: dest.longitude,
    );
    final zoomT = Tween<double>(begin: cam.zoom, end: destZoom);
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );
    final anim = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    controller.addListener(() {
      _mapController.move(
        LatLng(latT.evaluate(anim), lngT.evaluate(anim)),
        zoomT.evaluate(anim),
      );
    });
    controller.forward().whenComplete(controller.dispose);
  }

  void _animatedZoom(double delta) {
    final cam = _mapController.camera;
    _animatedMove(cam.center, (cam.zoom + delta).clamp(3.0, 19.0), ms: 350);
  }

  @override
  Widget build(BuildContext context) {
    final draw = ref.watch(drawingControllerProvider);
    final points = draw.points;
    final kayitlar = ref.watch(envanterlerProvider).value ?? [];
    final allTurler = ref.watch(turlerProvider).value ?? [];
    final handleSize = (_zoom * 2.0).clamp(10.0, 30.0);
    final plusSize = (_zoom * 2.0).clamp(12.0, 24.0);
    final offline = ref.watch(connectivityProvider).value ?? false;

    ref.listen(envanterlerProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        _showMsg('Veriler yüklenirken sorun oluştu');
      }
    });

    if (!identical(kayitlar, _memoRecords) ||
        !identical(allTurler, _memoTurler)) {
      _rebuildSavedLayers(kayitlar, allTurler);
      _memoRecords = kayitlar;
      _memoTurler = allTurler;
    }
    final savedPolygons = _savedPolygons;
    final savedLines = _savedLines;
    final savedMarkers = _savedMarkers;
    final drawing = draw.mode != DrawingMode.none;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CBS Harita',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      drawer: AppDrawer(
        userEmail: Supabase.instance.client.auth.currentUser?.email,
        turler: allTurler,
        currentMode: draw.mode,
        selectedTuru: draw.selectedTuru,
        onSelectTool: (mode, t) {
          _ctrl.selectTool(mode, t);
          _showMsg('${_geomLabel(mode)} - ${t.name} çizimi başladı');
        },
        onSettings: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsView()),
        ),
        onLogout: _logout,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(39.0, 35.0),
              initialZoom: 6.0,
              onTap: _handleMapTap,
              onPositionChanged: (camera, hasGesture) {
                if ((camera.zoom - _zoom).abs() > 0.2) {
                  setState(() => _zoom = camera.zoom);
                }
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _selectedLayer.url,
                userAgentPackageName: 'com.example.cbs_app',
                tileProvider: NetworkTileProvider(
                  cachingProvider:
                      BuiltInMapCachingProvider.getOrCreateInstance(
                        overrideFreshAge: const Duration(days: 30),
                      ),
                ),
              ),
              if (!drawing) ...[
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  hitTestBehavior: HitTestBehavior.deferToChild,
                  child: GestureDetector(
                    onTap: () => _handleIdentify(_polygonHit),
                    child: PolygonLayer<int>(
                      hitNotifier: _polygonHit,
                      polygons: savedPolygons,
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  hitTestBehavior: HitTestBehavior.deferToChild,
                  child: GestureDetector(
                    onTap: () => _handleIdentify(_lineHit),
                    child: PolylineLayer<int>(
                      hitNotifier: _lineHit,
                      polylines: savedLines,
                    ),
                  ),
                ),
              ] else ...[
                PolygonLayer<int>(polygons: savedPolygons),
                PolylineLayer<int>(polylines: savedLines),
              ],
              MarkerLayer(markers: savedMarkers),
              if (draw.mode == DrawingMode.polygon && points.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: points,
                      color: Colors.deepPurple.withValues(alpha: 0.3),
                      borderColor: Colors.deepPurple,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
              if ((draw.mode == DrawingMode.line ||
                      draw.mode == DrawingMode.polygon) &&
                  points.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      color: Colors.deepPurple,
                      strokeWidth: 4,
                    ),
                  ],
                ),

              if (_myLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _myLocation!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              if (_pulsePoint != null && _pulseAnim != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pulsePoint!,
                      width: 46,
                      height: 46,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity:
                              (_pulseOutward
                                      ? 1 - _pulseAnim!.value
                                      : _pulseAnim!.value)
                                  .clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _pulseOutward
                                ? 1 + _pulseAnim!.value * 1.6
                                : 1 + (1 - _pulseAnim!.value) * 0.8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _pulseColor.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _pulseColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              if (draw.mode == DrawingMode.polygon && points.length >= 2)
                MarkerLayer(markers: _polygonPlusMarkers(points, plusSize)),

              if (points.isNotEmpty)
                DragMarkers(
                  markers: [
                    for (int i = 0; i < points.length; i++)
                      DragMarker(
                        key: ValueKey(draw.vertexIds[i]),
                        point: points[i],
                        size: Size(handleSize, handleSize),
                        builder: (context, latLng, isDragging) {
                          final isLineEnd =
                              draw.mode == DrawingMode.line &&
                              (i == 0 || i == points.length - 1);
                          final circle = Container(
                            decoration: BoxDecoration(
                              color: isDragging ? Colors.orange : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.deepPurple,
                                width: 3,
                              ),
                            ),
                            child: isLineEnd
                                ? Icon(
                                    Icons.add,
                                    color: Colors.deepPurple,
                                    size: handleSize * 0.55,
                                  )
                                : null,
                          );
                          if (!isLineEnd) return circle;
                          return GestureDetector(
                            onTap: () => _ctrl.extendLine(i),
                            child: circle,
                          );
                        },
                        onDragStart: (details, latLng) =>
                            _dragOrigin = points[i],
                        onDragUpdate: (details, latLng) =>
                            _ctrl.moveVertex(i, latLng),
                        onDragEnd: (details, latLng) async {
                          final err = await _ctrl.validateRules();
                          if (!mounted) return;
                          if (err != null) {
                            _ctrl.moveVertex(i, _dragOrigin ?? latLng);
                            _showMsg(err);
                          }
                        },
                      ),
                  ],
                ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: points.isEmpty
                        ? 24 + MediaQuery.of(context).padding.bottom
                        : 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      LayerSwitcher(
                        current: _selectedLayer,
                        offline: offline,
                        onSelect: (l) => setState(() => _selectedLayer = l),
                      ),
                      MapControls(
                        onZoomIn: () => _animatedZoom(1),
                        onZoomOut: () => _animatedZoom(-1),
                        onLocation: _goToMyLocation,
                      ),
                    ],
                  ),
                ),
                if (draw.isActive)
                  DrawingActionBar(
                    isEditing: draw.isEditing,
                    onCancel: _ctrl.reset,
                    onComplete: draw.isEditing
                        ? _saveGeometryEdit
                        : _saveDrawing,
                    onUndo: draw.canUndo ? _undo : null,
                    onRedo: draw.canRedo ? _redo : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
