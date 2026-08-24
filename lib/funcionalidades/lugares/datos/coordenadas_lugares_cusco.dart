import '../dominio/modelos/modelo_lugar.dart';

/// Coordenadas reales aproximadas — región Cusco.
abstract final class CoordenadasLugaresCusco {
  static const _centro = (-13.5164, -71.9785);

  static const porId = <String, (double, double)>{
    'laguna_humantay': (-13.4097, -72.8758),
    'canon_qeswachaka': (-14.4422, -71.4836),
    'moray': (-13.3297, -72.1972),
    'ausangate_vista': (-13.7896, -71.2298),
    'machu_picchu': (-13.1631, -72.5450),
    'laguna_oculta': (-13.0450, -72.0200),
    'fogon_chinchero': (-13.3931, -72.0472),
    'mercado_san_pedro': (-13.5185, -71.9812),
    'picanteria_san_jeronimo': (-13.5040, -71.9200),
    'cafe_cacao_quellouno': (-12.6510, -72.7350),
    'taller_ceramica_blas': (-13.5135, -71.9758),
    'museo_inkariy': (-13.3320, -71.9565),
    'ofrenda_despacho_ausangate': (-13.7900, -71.2300),
    'temazcal_valle': (-13.3050, -72.1150),
    'ayahuasca_retiro_no': (-13.5220, -71.9680),
    'rafting_vilcanota': (-13.2580, -72.2650),
    'via_ferrata_sacred': (-13.2610, -72.2620),
    'casa_ollanta': (-13.2583, -72.2633),
    'mirador_foto_pisac': (-13.4215, -71.8472),
    'astro_foto_maras': (-13.3020, -72.1560),
    'catarata_quellouno': (-12.6480, -72.7400),
    'laguna_sibinacocha': (-13.8200, -71.0500),
    'plaza_paucartambo': (-13.7147, -71.5925),
    'puente_qeswa_canas': (-14.4410, -71.4845),
    'cementerio_almudena_noche': (-13.5280, -71.9620),
    'qoricancha_noche': (-13.5190, -71.9750),
    'calles_brujas_noche': (-13.5155, -71.9770),
    'wakas_sacsay_amanecer': (-13.5097, -71.9816),
    'salineras_luna_llena': (-13.3025, -72.1555),
    'cruz_cristal_noche': (-13.5050, -71.9900),
    'baile_diablada_noche': (-13.7140, -71.5930),
  };

  static ModeloLugar aplicar(ModeloLugar lugar) {
    final c = porId[lugar.id];
    if (c == null) {
      return lugar.copyWith(
        latitud: _centro.$1,
        longitud: _centro.$2,
      );
    }
    return lugar.copyWith(latitud: c.$1, longitud: c.$2);
  }
}
