import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/envanter.dart';
import '../models/envanter_turu.dart';
import '../models/alan_tanimi.dart';
import '../models/kural.dart';

class DatabaseHelper {

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> initializeDatabase() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cbs.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static const _createOutbox = '''
      CREATE TABLE IF NOT EXISTS outbox (
        op_id INTEGER PRIMARY KEY AUTOINCREMENT,
        op_type TEXT NOT NULL,
        local_id INTEGER NOT NULL,
        record_user_id TEXT NOT NULL,
        payload TEXT
      )
    ''';

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {

    if (oldVersion < 2) {
      await db.execute(_createOutbox);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE envanterler (
        id INTEGER NOT NULL,
        record_user_id TEXT NOT NULL,
        geometry_type TEXT NOT NULL,
        inventory_type TEXT,
        name TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'Aktif',
        geometry_wkt TEXT NOT NULL,
        attributes TEXT,
        created_at TEXT,
        PRIMARY KEY (id, record_user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE envanter_turleri (
        id INTEGER PRIMARY KEY,
        geometry_type TEXT NOT NULL,
        name TEXT NOT NULL,
        icon TEXT,
        sort_order INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE alan_tanimlari (
        id INTEGER PRIMARY KEY,
        tur_id INTEGER,
        field_key TEXT NOT NULL,
        label TEXT NOT NULL,
        field_type TEXT NOT NULL,
        options TEXT,
        sort_order INTEGER DEFAULT 0,
        is_required INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE geometri_kurallari (
        id INTEGER PRIMARY KEY,
        source_type TEXT NOT NULL,
        target_type TEXT NOT NULL,
        predicate TEXT NOT NULL,
        rule_type TEXT NOT NULL,
        message TEXT NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute(_createOutbox);
  }

  Future<int> insertEnvanter(Envanter e) async {
    final db = await database;

    return db.insert(
      'envanterler',
      e.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Envanter>> getAllEnvanterler(String userId) async {
    final db = await database;
    final rows = await db.query(
      'envanterler',
      where: 'record_user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map((m) => Envanter.fromMap(m)).toList();
  }

  Future<int> updateEnvanter(Envanter e) async {
    final db = await database;
    return db.update(
      'envanterler',
      e.toMap(),
      where: 'id = ? AND record_user_id = ?',
      whereArgs: [e.id, e.recordUserId],
    );
  }

  Future<int> deleteEnvanter(int id, String userId) async {
    final db = await database;
    return db.delete(
      'envanterler',
      where: 'id = ? AND record_user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> deleteAllEnvanterler(String userId) async {
    final db = await database;
    await db.delete(
      'envanterler',
      where: 'record_user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<EnvanterTuru>> getTurler({String? geometryType}) async {
    final db = await database;
    final rows = geometryType == null
        ? await db.query('envanter_turleri', orderBy: 'sort_order, name')
        : await db.query(
            'envanter_turleri',
            where: 'geometry_type = ?',
            whereArgs: [geometryType],
            orderBy: 'sort_order, name',
          );
    return rows.map((m) => EnvanterTuru.fromMap(m)).toList();
  }

  Future<List<AlanTanimi>> getAlanTanimlari(int turId) async {
    final db = await database;
    final rows = await db.query(
      'alan_tanimlari',
      where: 'tur_id = ? OR tur_id IS NULL',
      whereArgs: [turId],
      orderBy: 'sort_order',
    );
    return rows.map((m) => AlanTanimi.fromMap(m)).toList();
  }

  Future<EnvanterTuru?> getTuruByName(String geometryType, String name) async {
    final db = await database;
    final rows = await db.query(
      'envanter_turleri',
      where: 'geometry_type = ? AND name = ?',
      whereArgs: [geometryType, name],
      limit: 1,
    );
    return rows.isEmpty ? null : EnvanterTuru.fromMap(rows.first);
  }

  Future<void> replaceTurler(List<EnvanterTuru> list) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('envanter_turleri');
    for (final t in list) {
      batch.insert('envanter_turleri', {
        'id': t.id,
        'geometry_type': t.geometryType,
        'name': t.name,
        'icon': t.icon,
        'sort_order': t.sortOrder,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> replaceAlanTanimlari(List<AlanTanimi> list) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('alan_tanimlari');
    for (final a in list) {
      batch.insert('alan_tanimlari', {
        'id': a.id,
        'tur_id': a.turId,
        'field_key': a.fieldKey,
        'label': a.label,
        'field_type': a.fieldType,
        'options': a.options,
        'sort_order': a.sortOrder,
        'is_required': a.isRequired ? 1 : 0,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> replaceRecordsForUser(String userId, List<Envanter> list) async {
    final db = await database;
    final batch = db.batch();
    batch.delete(
      'envanterler',
      where: 'record_user_id = ?',
      whereArgs: [userId],
    );
    for (final e in list) {
      batch.insert(
        'envanterler',
        e.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Kural>> getKurallar() async {
    final db = await database;
    final rows = await db.query('geometri_kurallari', where: 'is_active = 1');
    return rows.map((m) => Kural.fromMap(m)).toList();
  }

  Future<void> replaceKurallar(List<Kural> list) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('geometri_kurallari');
    for (final k in list) {
      batch.insert('geometri_kurallari', {
        'id': k.id,
        'source_type': k.sourceType,
        'target_type': k.targetType,
        'predicate': k.predicate,
        'rule_type': k.ruleType,
        'message': k.message,
        'is_active': k.isActive ? 1 : 0,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> enqueueOutbox(
    String opType,
    int localId,
    String userId,
    String? payload,
  ) async {
    final db = await database;
    await db.insert('outbox', {
      'op_type': opType,
      'local_id': localId,
      'record_user_id': userId,
      'payload': payload,
    });
  }

  Future<Map<String, dynamic>?> nextOutbox(String userId) async {
    final db = await database;
    final rows = await db.query(
      'outbox',
      where: 'record_user_id = ?',
      whereArgs: [userId],
      orderBy: 'op_id',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> deleteOutbox(int opId) async {
    final db = await database;
    await db.delete('outbox', where: 'op_id = ?', whereArgs: [opId]);
  }

  Future<void> clearOutbox(String userId) async {
    final db = await database;
    await db.delete('outbox', where: 'record_user_id = ?', whereArgs: [userId]);
  }

  Future<int> outboxCount(String userId) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM outbox WHERE record_user_id = ?',
      [userId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> remapId(int oldId, int newId, String userId) async {
    final db = await database;
    await db.update(
      'envanterler',
      {'id': newId},
      where: 'id = ? AND record_user_id = ?',
      whereArgs: [oldId, userId],
    );
    await db.update(
      'outbox',
      {'local_id': newId},
      where: 'local_id = ? AND record_user_id = ?',
      whereArgs: [oldId, userId],
    );
  }
}
