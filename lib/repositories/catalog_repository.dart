import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database_helper.dart';
import '../core/sync_service.dart';
import '../models/envanter_turu.dart';
import '../models/alan_tanimi.dart';
import '../models/kural.dart';

class CatalogRepository {
  final DatabaseHelper _db;
  CatalogRepository(this._db);

  Future<void> pull() => SyncService.pullCatalog();

  Future<List<EnvanterTuru>> getTurler({String? geometryType}) =>
      _db.getTurler(geometryType: geometryType);

  Future<List<AlanTanimi>> getAlanTanimlari(int turId) =>
      _db.getAlanTanimlari(turId);

  Future<List<Kural>> getKurallar() => _db.getKurallar();
}

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(DatabaseHelper.instance),
);
