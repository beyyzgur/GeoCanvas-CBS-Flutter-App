import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/database_helper.dart';
import '../models/envanter.dart';
import '../core/constants.dart';

class EnvanterRepository {
  final SupabaseClient _sb;
  final DatabaseHelper _db;
  EnvanterRepository(this._sb, this._db);

  static const _table = 'envanterler';

  Envanter _fromRemote(Map<String, dynamic> m, String ownerId) => Envanter(
        id: m['id'] as int,
        recordUserId: ownerId,
        geometryType: m['geometry_type'] as String,
        inventoryType: m['inventory_type'] as String?,
        name: m['name'] as String,
        description: m['description'] as String?,
        status: (m['status'] as String?) ?? EnvanterStatus.aktif,
        geometryWkt: m['geometry_wkt'] as String,
        attributes:
            (m['attributes'] as Map?)?.cast<String, dynamic>() ?? const {},
        createdAt: m['created_at']?.toString(),
      );

  Map<String, dynamic> _toRemote(Envanter e) => {
        'geometry_type': e.geometryType,
        'inventory_type': e.inventoryType,
        'name': e.name,
        'description': e.description,
        'status': e.status,
        'geometry_wkt': e.geometryWkt,
        'attributes': e.attributes,

        if (e.createdAt != null) 'created_at': e.createdAt,
      };

  int _tempId() => -DateTime.now().microsecondsSinceEpoch;

  Future<List<Envanter>> syncAndGet(String userId) async {
    await _trySync(userId);

    if (await _db.outboxCount(userId) == 0) {
      try {
        final rows = await _sb.from(_table).select();
        final list = (rows as List).map((m) {
          final row = m as Map<String, dynamic>;
          return _fromRemote(row, row['user_id'] as String);
        }).toList();
        await _db.replaceRecordsForUser(userId, list);
      } catch (e) {
        debugPrint('syncAndGet pull hatası (çevrimdışı olabilir): $e');
      }
    }
    return _db.getAllEnvanterler(userId);
  }

  Future<List<Envanter>> getLocal(String userId) =>
      _db.getAllEnvanterler(userId);

  Future<void> add(Envanter e, String userId) async {
    final local = e.copyWith(
      id: _tempId(),
      recordUserId: userId,

      createdAt: e.createdAt ?? DateTime.now().toIso8601String(),
    );
    await _db.insertEnvanter(local);
    await _db.enqueueOutbox(
      'insert',
      local.id!,
      userId,
      jsonEncode(_toRemote(local)),
    );
    await _trySync(userId);
  }

  Future<void> edit(Envanter e) async {
    await _db.updateEnvanter(e);
    await _db.enqueueOutbox(
      'update',
      e.id!,
      e.recordUserId,
      jsonEncode(_toRemote(e)),
    );
    await _trySync(e.recordUserId);
  }

  Future<void> remove(int id, String userId) async {
    await _db.deleteEnvanter(id, userId);
    await _db.enqueueOutbox('delete', id, userId, null);
    await _trySync(userId);
  }

  Future<void> clearAll(String userId) async {
    await _db.deleteAllEnvanterler(userId);
    await _db.clearOutbox(userId);
    await _db.enqueueOutbox('clear', 0, userId, null);
    await _trySync(userId);
  }

  Future<void> _trySync(String userId) async {
    try {
      await _drain(userId);
    } catch (e) {

      debugPrint('Outbox gönderilemedi (kuyrukta bekliyor): $e');
    }
  }

  Future<void> _drain(String userId) async {
    while (true) {
      final op = await _db.nextOutbox(userId);
      if (op == null) break;
      final type = op['op_type'] as String;
      final localId = op['local_id'] as int;
      final payload = op['payload'] as String?;

      switch (type) {
        case 'insert':
          final data = jsonDecode(payload!) as Map<String, dynamic>;
          final inserted =
              await _sb.from(_table).insert(data).select().single();
          final realId = inserted['id'] as int;

          await _db.remapId(localId, realId, userId);
          break;
        case 'update':
          final data = jsonDecode(payload!) as Map<String, dynamic>;
          await _sb.from(_table).update(data).eq('id', localId);
          break;
        case 'delete':
          await _sb.from(_table).delete().eq('id', localId);
          break;
        case 'clear':
          await _sb.from(_table).delete().eq('user_id', userId);
          break;
      }
      await _db.deleteOutbox(op['op_id'] as int);
    }
  }
}

final envanterRepositoryProvider = Provider<EnvanterRepository>(
  (ref) =>
      EnvanterRepository(Supabase.instance.client, DatabaseHelper.instance),
);
