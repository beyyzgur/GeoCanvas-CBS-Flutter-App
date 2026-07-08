import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/envanter.dart';
import '../../models/envanter_turu.dart';
import '../../models/alan_tanimi.dart';
import '../../core/constants.dart';
import '../../core/date_format.dart';
import '../../repositories/catalog_repository.dart';
import 'envanter_notifier.dart';

class InventoryFormSheet extends ConsumerStatefulWidget {
  final String geometryType;
  final String geometryWkt;
  final Envanter? existing;
  final EnvanterTuru? preselectedTuru;

  const InventoryFormSheet({
    super.key,
    required this.geometryType,
    required this.geometryWkt,
    this.existing,
    this.preselectedTuru,
  });

  @override
  ConsumerState<InventoryFormSheet> createState() => _InventoryFormSheetState();
}

class _InventoryFormSheetState extends ConsumerState<InventoryFormSheet> {
  String _status = EnvanterStatus.aktif;
  bool _isSaving = false;
  bool _loading = true;

  List<EnvanterTuru> _turler = [];
  EnvanterTuru? _selectedTuru;
  List<AlanTanimi> _alanlar = [];
  Map<String, dynamic> _attrValues = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  EnvanterTuru? _find(bool Function(EnvanterTuru) test) {
    for (final t in _turler) {
      if (test(t)) return t;
    }
    return null;
  }

  Future<void> _init() async {
    final e = widget.existing;
    if (e != null) {
      _status = e.status;
      _attrValues = {
        ...e.attributes,
        FieldKeys.name: e.name,
        FieldKeys.description: e.description ?? '',
      };
    }

    final catalog = ref.read(catalogRepositoryProvider);
    _turler = await catalog.getTurler(geometryType: widget.geometryType);

    EnvanterTuru? initial;
    if (e?.inventoryType != null) {
      initial = _find((t) => t.name == e!.inventoryType);
    }
    initial ??= widget.preselectedTuru != null
        ? _find((t) => t.id == widget.preselectedTuru!.id)
        : null;
    initial ??= _turler.isNotEmpty ? _turler.first : null;

    _selectedTuru = initial;
    if (initial != null) {
      _alanlar = await catalog.getAlanTanimlari(initial.id);
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _onTuruChanged(EnvanterTuru? t) async {
    if (t == null) return;
    final alanlar =
        await ref.read(catalogRepositoryProvider).getAlanTanimlari(t.id);
    if (!mounted) return;
    setState(() {
      _selectedTuru = t;
      _alanlar = alanlar;

    });
  }

  bool get _isValid {
    for (final alan in _alanlar) {
      if (alan.isRequired) {
        final v = _attrValues[alan.fieldKey];
        if (v == null || v.toString().trim().isEmpty) return false;
      }
    }
    return true;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final name = (_attrValues[FieldKeys.name] ?? '').toString().trim();
      final descRaw =
          (_attrValues[FieldKeys.description] ?? '').toString().trim();
      final description = descRaw.isEmpty ? null : descRaw;

      final attrs = <String, dynamic>{};
      for (final alan in _alanlar) {
        if (alan.fieldKey == FieldKeys.name ||
            alan.fieldKey == FieldKeys.description) {
          continue;
        }
        final v = _attrValues[alan.fieldKey];
        if (v != null && v.toString().trim().isNotEmpty) {
          attrs[alan.fieldKey] = v;
        }
      }

      if (widget.existing != null) {

        final updated = Envanter(
          id: widget.existing!.id,
          recordUserId: widget.existing!.recordUserId,
          geometryType: widget.geometryType,
          inventoryType: _selectedTuru?.name,
          name: name,
          description: description,
          status: _status,
          geometryWkt: widget.geometryWkt,
          attributes: attrs,
          createdAt: widget.existing!.createdAt,
        );
        await ref.read(envanterlerProvider.notifier).edit(updated);
      } else {
        final yeni = Envanter(
          recordUserId: userId,
          geometryType: widget.geometryType,
          inventoryType: _selectedTuru?.name,
          name: name,
          description: description,
          status: _status,
          geometryWkt: widget.geometryWkt,
          attributes: attrs,
        );
        await ref.read(envanterlerProvider.notifier).add(yeni);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydedilemedi: $e')),
        );
      }
    }
  }

  Future<String?> _showPicker(
      String title, List<String> options, String? current) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child:
                    Text(title, style: Theme.of(ctx).textTheme.titleMedium),
              ),
            ),
            ...options.map(
              (o) => ListTile(
                title: Text(o),
                trailing: o == current
                    ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, o),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _pickerField({
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? 'Seçiniz',
                style: TextStyle(
                  fontSize: 16,
                  color: value == null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicField(AlanTanimi alan) {
    final key = ValueKey('${_selectedTuru!.id}_${alan.fieldKey}');
    final label = alan.isRequired ? '${alan.label} *' : alan.label;

    switch (alan.fieldType) {
      case FieldType.dropdown:
        final val = _attrValues[alan.fieldKey] as String?;
        return Padding(
          key: key,
          padding: const EdgeInsets.only(bottom: 12),
          child: _pickerField(
            label: label,
            value: (val != null && alan.optionList.contains(val)) ? val : null,
            onTap: () async {
              final sel = await _showPicker(alan.label, alan.optionList, val);
              if (sel != null) {
                setState(() => _attrValues[alan.fieldKey] = sel);
              }
            },
          ),
        );
      case FieldType.number:
        return Padding(
          key: key,
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            initialValue: _attrValues[alan.fieldKey]?.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _attrValues[alan.fieldKey] = v),
          ),
        );
      default:
        return Padding(
          key: key,
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            initialValue: _attrValues[alan.fieldKey]?.toString(),
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _attrValues[alan.fieldKey] = v),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 4,
      ),
      child: _loading
          ? const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.existing == null
                        ? 'ENVANTER BİLGİ FORMU'
                        : 'ENVANTERİ DÜZENLE',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _pickerField(
                    label: 'Türü',
                    value: _selectedTuru?.name,
                    onTap: () async {
                      final sel = await _showPicker(
                        'Tür Seç',
                        _turler.map((t) => t.name).toList(),
                        _selectedTuru?.name,
                      );
                      if (sel != null) {
                        final t = _find((x) => x.name == sel);
                        if (t != null) _onTuruChanged(t);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  ..._alanlar.map(_buildDynamicField),
                  _pickerField(
                    label: 'Durum',
                    value: _status,
                    onTap: () async {
                      final sel = await _showPicker(
                          'Durum Seç',
                          const [EnvanterStatus.aktif, EnvanterStatus.pasif],
                          _status);
                      if (sel != null) setState(() => _status = sel);
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kayıt Tarihi: '
                        '${widget.existing?.createdAt != null ? formatTrDateTime(widget.existing!.createdAt) : 'Kaydedince oluşturulacak'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_isValid)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Lütfen zorunlu (*) alanları doldurun',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: const Text('İPTAL'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (_isSaving || !_isValid) ? null : _save,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('KAYDET'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
