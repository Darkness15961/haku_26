enum ModoEjecucionHaku { produccion, demo }

ModoEjecucionHaku interpretarModoEjecucion(String valor) {
  switch (valor.trim().toLowerCase()) {
    case 'production':
    case 'produccion':
    case 'prod':
      return ModoEjecucionHaku.produccion;
    case 'demo':
      return ModoEjecucionHaku.demo;
    default:
      throw ArgumentError.value(
        valor,
        'HAKU_APP_MODE',
        'Usa "production" o "demo".',
      );
  }
}

class ConfigEntornoHaku {
  ConfigEntornoHaku._();

  static const _modoConfigurado = String.fromEnvironment(
    'HAKU_APP_MODE',
    defaultValue: 'production',
  );

  static ModoEjecucionHaku get modo =>
      interpretarModoEjecucion(_modoConfigurado);

  static bool get esDemo => modo == ModoEjecucionHaku.demo;
}
