import 'package:flutter/material.dart';
import '../drawing_mode.dart';
import '../../../models/envanter_turu.dart';

class AppDrawer extends StatelessWidget {
  final String? userEmail;
  final List<EnvanterTuru> turler;
  final DrawingMode currentMode;
  final EnvanterTuru? selectedTuru;
  final void Function(DrawingMode mode, EnvanterTuru turu) onSelectTool;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.userEmail,
    required this.turler,
    required this.currentMode,
    required this.selectedTuru,
    required this.onSelectTool,
    required this.onSettings,
    required this.onLogout,
  });

  Widget _toolExpansion(
    BuildContext context,
    DrawingMode mode,
    IconData icon,
    String label,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final tipler =
        turler.where((t) => t.geometryType == mode.geometryType).toList();
    final active = currentMode == mode;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(
          icon,
          color: active ? scheme.primary : scheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 4),
        children: tipler.map((t) {
          final selected = currentMode == mode && selectedTuru?.id == t.id;
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 52, right: 16),
            leading: Icon(
              Icons.circle,
              size: 8,
              color: selected ? scheme.primary : scheme.outline,
            ),
            title: Text(t.name),
            selected: selected,
            selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.35),
            onTap: () {
              Navigator.pop(context);
              onSelectTool(mode, t);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.person_outline,
                        color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CBS Harita',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          userEmail ?? '',
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'ÇİZİM ARAÇLARI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _toolExpansion(context, DrawingMode.point,
                      Icons.place_outlined, 'Nokta'),
                  _toolExpansion(
                      context, DrawingMode.line, Icons.timeline, 'Çizgi'),
                  _toolExpansion(context, DrawingMode.polygon,
                      Icons.hexagon_outlined, 'Alan'),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Ayarlar'),
              onTap: () {
                Navigator.pop(context);
                onSettings();
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text('Çıkış Yap', style: TextStyle(color: scheme.error)),
              onTap: onLogout,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
