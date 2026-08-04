import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/envanter.dart';
import '../../core/connectivity_provider.dart';
import '../../repositories/envanter_repository.dart';
import '../../repositories/catalog_repository.dart';
import '../auth/auth_providers.dart';
import '../../models/envanter_turu.dart';
import '../../models/kural.dart';

class EnvanterNotifier extends AsyncNotifier<List<Envanter>> {
  EnvanterRepository get _repo => ref.read(envanterRepositoryProvider);

  @override
  Future<List<Envanter>> build() async {
    final userId = ref.watch(currentUserIdProvider);

    ref.listen(connectivityProvider, (prev, next) {
      final wasOffline = prev?.value ?? false;
      final isOffline = next.value ?? false;
      if (wasOffline && !isOffline) _resync();
    });

    if (userId == null) return [];
    return _repo.syncAndGet(userId);
  }

  Future<void> _refresh() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    state = await AsyncValue.guard(() => _repo.getLocal(userId));
  }

  Future<void> _resync() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    state = await AsyncValue.guard(() => _repo.syncAndGet(userId));
  }

  Future<void> add(Envanter e) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await _repo.add(e, userId);
    await _refresh();
  }

  Future<void> edit(Envanter e) async {
    await _repo.edit(e);
    await _refresh();
  }

  Future<void> remove(int id) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await _repo.remove(id, userId);
    await _refresh();
  }

  Future<void> clearAll() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await _repo.clearAll(userId);
    await _refresh();
  }
}

final envanterlerProvider =
    AsyncNotifierProvider<EnvanterNotifier, List<Envanter>>(
      EnvanterNotifier.new,
    );

final catalogSyncProvider = FutureProvider<void>((ref) async {
  ref.watch(currentUserIdProvider);
  try {
    await ref.read(catalogRepositoryProvider).pull();
  } catch (e) {
    debugPrint('Katalog senkronu başarısız (çevrimdışı olabilir): $e');
  }
});

final turlerProvider = FutureProvider<List<EnvanterTuru>>((ref) async {
  await ref.watch(catalogSyncProvider.future);
  return ref.read(catalogRepositoryProvider).getTurler();
});

final kurallarProvider = FutureProvider<List<Kural>>((ref) async {
  await ref.watch(catalogSyncProvider.future);
  return ref.read(catalogRepositoryProvider).getKurallar();
});
