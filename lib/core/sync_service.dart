import 'package:bs_network_kit/bs_network_kit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alan_tanimi.dart';
import '../models/envanter_turu.dart';
import '../models/kural.dart';
import 'database_helper.dart';
import 'network/catalog_endpoints.dart';
import 'network/network_providers.dart';

class SyncService {
  const SyncService({
    required this.networkService,
    required this.database,
    required this.supabaseUrl,
    required this.publishableKey,
  });

  final NetworkService networkService;
  final DatabaseHelper database;
  final String supabaseUrl;
  final String publishableKey;

  Future<void> pullCatalog() async {
    final turler = await networkService.request(
      GetEnvanterTurleriEndpoint(
        supabaseUrl: supabaseUrl,
        publishableKey: publishableKey,
      ),
      decoder: JsonDecoders.list(_decodeMap),
    );

    final alanlar = await networkService.request(
      GetAlanTanimlariEndpoint(
        supabaseUrl: supabaseUrl,
        publishableKey: publishableKey,
      ),
      decoder: JsonDecoders.list(_decodeMap),
    );

    final kurallar = await networkService.request(
      GetGeometriKurallariEndpoint(
        supabaseUrl: supabaseUrl,
        publishableKey: publishableKey,
      ),
      decoder: JsonDecoders.list(_decodeMap),
    );

    await database.replaceTurler(turler.map(EnvanterTuru.fromMap).toList());

    await database.replaceAlanTanimlari(
      alanlar.map(AlanTanimi.fromMap).toList(),
    );

    await database.replaceKurallar(kurallar.map(Kural.fromMap).toList());
  }

  static Map<String, dynamic> _decodeMap(Object? json) {
    return json! as Map<String, dynamic>;
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    networkService: ref.watch(networkServiceProvider),
    database: DatabaseHelper.instance,
    supabaseUrl: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );
});
