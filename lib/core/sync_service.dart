import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_helper.dart';
import '../models/envanter_turu.dart';
import '../models/alan_tanimi.dart';
import '../models/kural.dart';

class SyncService {
  static final SupabaseClient _sb = Supabase.instance.client;

  static Future<void> pullCatalog() async {
    final turler = await _sb.from('envanter_turleri').select();
    final alanlar = await _sb.from('alan_tanimlari').select();
    final kurallar = await _sb.from('geometri_kurallari').select();

    await DatabaseHelper.instance.replaceTurler(
      (turler as List).map((m) => EnvanterTuru.fromMap(m)).toList(),
    );
    await DatabaseHelper.instance.replaceAlanTanimlari(
      (alanlar as List).map((m) => AlanTanimi.fromMap(m)).toList(),
    );
    await DatabaseHelper.instance.replaceKurallar(
      (kurallar as List).map((m) => Kural.fromMap(m)).toList(),
    );
  }

}
