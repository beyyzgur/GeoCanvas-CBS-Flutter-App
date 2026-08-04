import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final conn = Connectivity();
  bool offline(List<ConnectivityResult> r) =>
      !r.any((x) => x != ConnectivityResult.none);
  yield offline(await conn.checkConnectivity());
  yield* conn.onConnectivityChanged.map(offline);
});
