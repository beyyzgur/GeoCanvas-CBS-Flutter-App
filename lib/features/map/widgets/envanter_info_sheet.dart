import 'package:flutter/material.dart';
import '../../../models/envanter.dart';
import '../../../core/constants.dart';
import '../../../core/date_format.dart';

class EnvanterInfoSheet extends StatelessWidget {
  final Envanter envanter;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onEditGeometry;

  const EnvanterInfoSheet({
    super.key,
    required this.envanter,
    required this.onDelete,
    required this.onEdit,
    required this.onEditGeometry,
  });

  IconData _iconForGeometry(String t) {
    switch (t) {
      case GeometryTypes.point:
        return Icons.place_outlined;
      case GeometryTypes.line:
        return Icons.timeline;
      case GeometryTypes.polygon:
        return Icons.hexagon_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _statusChip(String status) {
    final MaterialColor c =
        status == EnvanterStatus.aktif ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: c.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = envanter;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForGeometry(e.geometryType),
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (e.inventoryType != null)
                      Text(
                        e.inventoryType!,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              _statusChip(e.status),
            ],
          ),
          if (e.description != null && e.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              e.description!,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
          if (e.attributes.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...e.attributes.entries.map(
              (en) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      en.key,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    Text(
                      '${en.value}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (e.createdAt != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event_outlined,
                    size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Kayıt Tarihi: ${formatTrDateTime(e.createdAt)}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  label: Text('Sil', style: TextStyle(color: scheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: scheme.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Düzenle'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onEditGeometry();
            },
            icon: const Icon(Icons.edit_location_alt_outlined),
            label: const Text('Geometriyi Düzenle'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
