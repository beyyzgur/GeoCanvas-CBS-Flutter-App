import 'package:bs_network_kit/bs_network_kit.dart';
import 'package:bs_network_kit/testing.dart';
import 'package:cbs_app/core/network/catalog_endpoints.dart';
import 'package:cbs_app/models/envanter_turu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supabaseUrl = 'https://example.supabase.co';
  const publishableKey = 'publishable-key';

  group('Catalog endpoints', () {
    test('builds the expected Supabase REST URLs', () {
      const turlerEndpoint = GetEnvanterTurleriEndpoint(
        supabaseUrl: supabaseUrl,
        publishableKey: publishableKey,
      );

      const alanlarEndpoint = GetAlanTanimlariEndpoint(
        supabaseUrl: supabaseUrl,
        publishableKey: publishableKey,
      );

      const kurallarEndpoint = GetGeometriKurallariEndpoint(
        supabaseUrl: supabaseUrl,
        publishableKey: publishableKey,
      );

      expect(turlerEndpoint.uri.path, '/rest/v1/envanter_turleri');
      expect(alanlarEndpoint.uri.path, '/rest/v1/alan_tanimlari');
      expect(kurallarEndpoint.uri.path, '/rest/v1/geometri_kurallari');

      expect(turlerEndpoint.method, HttpMethod.get);
      expect(turlerEndpoint.queryParameters['select'], '*');
      expect(turlerEndpoint.queryParameters['order'], 'sort_order.asc');
      expect(turlerEndpoint.headers['apikey'], publishableKey);
    });

    test('sends auth headers and decodes catalog records', () async {
      final client = MockNetworkClient.json([
        {
          'id': 1,
          'geometry_type': 'point',
          'name': 'Ağaç',
          'icon': 'tree',
          'sort_order': 10,
        },
      ]);

      final service = DefaultNetworkService(
        client: client,
        interceptors: [AuthInterceptor(tokenProvider: () => 'access-token')],
      );

      addTearDown(service.close);

      const endpoint = GetEnvanterTurleriEndpoint(
        supabaseUrl: supabaseUrl,
        publishableKey: publishableKey,
      );

      final turler = await service.request(
        endpoint,
        decoder: JsonDecoders.list(
          (json) => EnvanterTuru.fromMap(json! as Map<String, dynamic>),
        ),
      );

      expect(turler, hasLength(1));
      expect(turler.single.id, 1);
      expect(turler.single.geometryType, 'point');
      expect(turler.single.name, 'Ağaç');
      expect(turler.single.sortOrder, 10);

      expect(client.requests, hasLength(1));
      expect(
        client.lastRequest?.headers['Authorization'],
        'Bearer access-token',
      );
      expect(client.lastRequest?.headers['apikey'], publishableKey);
    });

    test('retries a GET request after a connection error', () async {
      final client = MockNetworkClient.error(const ConnectionError());

      final service = DefaultNetworkService(
        client: client,
        interceptors: const [
          RetryInterceptor(
            maxAttempts: 2,
            delay: Duration.zero,
            jitterFactor: 0,
          ),
        ],
      );

      addTearDown(service.close);

      const endpoint = GetEnvanterTurleriEndpoint(
        supabaseUrl: supabaseUrl,
        publishableKey: publishableKey,
      );

      await expectLater(
        service.requestVoid(endpoint),
        throwsA(isA<ConnectionError>()),
      );

      expect(client.requests, hasLength(2));
    });
  });
}
