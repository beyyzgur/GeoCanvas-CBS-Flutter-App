import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onLocation;

  const MapControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'zoomIn',
          tooltip: 'Yakınlaştır',
          onPressed: onZoomIn,
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'zoomOut',
          tooltip: 'Uzaklaştır',
          onPressed: onZoomOut,
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'location',
          tooltip: 'Konumum',
          onPressed: onLocation,
          child: const Icon(Icons.my_location),
        ),
      ],
    );
  }
}

class DrawingActionBar extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  final VoidCallback? onUndo;

  final VoidCallback? onRedo;

  const DrawingActionBar({
    super.key,
    required this.isEditing,
    required this.onCancel,
    required this.onComplete,
    this.onUndo,
    this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              label: const Text('İptal'),
            ),
          ),

          if (onUndo != null) ...[
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: onUndo,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 48),
              ),
              child: const Icon(Icons.undo),
            ),
          ],

          if (onRedo != null) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onRedo,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 48),
              ),
              child: const Icon(Icons.redo),
            ),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.check),
              label: Text(isEditing ? 'Geometriyi Kaydet' : 'Tamamla'),
            ),
          ),
        ],
      ),
    );
  }
}
