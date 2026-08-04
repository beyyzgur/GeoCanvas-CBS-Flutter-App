import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database_helper.dart';
import '../core/sync_service.dart';
import '../models/alan_tanimi.dart';
import '../models/envanter_turu.dart';
import '../models/kural.dart';

class CatalogRepository {
  const CatalogRepository({required this.database, required this.syncService});

  final DatabaseHelper database;
  final SyncService syncService;

  Future<void> pull() => syncService.pullCatalog();

  Future<List<EnvanterTuru>> getTurler({String? geometryType}) {
    return database.getTurler(geometryType: geometryType);
  }

  Future<List<AlanTanimi>> getAlanTanimlari(int turId) {
    return database.getAlanTanimlari(turId);
  }

  Future<List<Kural>> getKurallar() {
    return database.getKurallar();
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(
    database: DatabaseHelper.instance,
    syncService: ref.watch(syncServiceProvider),
  );
});
