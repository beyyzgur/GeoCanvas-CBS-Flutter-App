import 'package:flutter/material.dart';
import '../map_layer.dart';

class LayerSwitcher extends StatefulWidget {
  final MapLayer current;
  final bool offline;
  final ValueChanged<MapLayer> onSelect;

  const LayerSwitcher({
    super.key,
    required this.current,
    required this.offline,
    required this.onSelect,
  });

  @override
  State<LayerSwitcher> createState() => _LayerSwitcherState();
}

class _LayerSwitcherState extends State<LayerSwitcher>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  late final Animation<double> _anim = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  Widget _fab(MapLayer l, VoidCallback onTap, {bool isCurrent = false}) {
    final scheme = Theme.of(context).colorScheme;

    final disabled = widget.offline && !l.cacheable && !isCurrent;
    return FloatingActionButton.small(
      heroTag: 'layer_${l.type.name}',
      tooltip: disabled ? '${l.label} (çevrimdışı kullanılamaz)' : l.label,
      backgroundColor: disabled
          ? scheme.surfaceContainerHighest
          : (isCurrent ? scheme.primary : null),
      foregroundColor: disabled
          ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
          : (isCurrent ? scheme.onPrimary : null),
      onPressed: disabled
          ? () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${l.label} için internet bağlantısı gerekli'),
                ),
              )
          : onTap,
      child: Icon(l.icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final others =
        kMapLayers.where((l) => l.type != widget.current.type).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        ...others.map(
          (l) => SizeTransition(
            sizeFactor: _anim,
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _anim,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _fab(l, () {
                  widget.onSelect(l);
                  _toggle();
                }),
              ),
            ),
          ),
        ),
        _fab(widget.current, _toggle, isCurrent: true),
      ],
    );
  }
}
