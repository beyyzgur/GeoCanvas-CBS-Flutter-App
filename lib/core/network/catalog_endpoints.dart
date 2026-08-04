import 'package:bs_network_kit/bs_network_kit.dart';

abstract class SupabaseCatalogEndpoint extends Endpoint {
  const SupabaseCatalogEndpoint({
    required this.supabaseUrl,
    required this.publishableKey,
  });

  final String supabaseUrl;
  final String publishableKey;

  @override
  String get baseUrl => supabaseUrl;

  @override
  HttpMethod get method => HttpMethod.get;

  @override
  Map<String, String> get queryParameters => const {'select': '*'};

  @override
  Map<String, String> get headers => {
    'apikey': publishableKey,
    'Accept': 'application/json',
  };

  @override
  Duration get timeout => const Duration(seconds: 15);
}

final class GetEnvanterTurleriEndpoint extends SupabaseCatalogEndpoint {
  const GetEnvanterTurleriEndpoint({
    required super.supabaseUrl,
    required super.publishableKey,
  });

  @override
  String get path => '/rest/v1/envanter_turleri';

  @override
  Map<String, String> get queryParameters => const {
    'select': '*',
    'order': 'sort_order.asc',
  };
}

final class GetAlanTanimlariEndpoint extends SupabaseCatalogEndpoint {
  const GetAlanTanimlariEndpoint({
    required super.supabaseUrl,
    required super.publishableKey,
  });

  @override
  String get path => '/rest/v1/alan_tanimlari';

  @override
  Map<String, String> get queryParameters => const {
    'select': '*',
    'order': 'sort_order.asc',
  };
}

final class GetGeometriKurallariEndpoint extends SupabaseCatalogEndpoint {
  const GetGeometriKurallariEndpoint({
    required super.supabaseUrl,
    required super.publishableKey,
  });

  @override
  String get path => '/rest/v1/geometri_kurallari';
}
