import 'package:bs_network_kit/bs_network_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final networkServiceProvider = Provider<NetworkService>((ref) {
  final client = HttpNetworkClient();

  final service = DefaultNetworkService(
    client: client,
    interceptors: [
      const RetryInterceptor(maxAttempts: 2),
      AuthInterceptor(
        tokenProvider: () =>
            Supabase.instance.client.auth.currentSession?.accessToken,
      ),
      if (kDebugMode) const LoggingInterceptor(),
    ],
  );

  ref.onDispose(service.close);

  return service;
});
