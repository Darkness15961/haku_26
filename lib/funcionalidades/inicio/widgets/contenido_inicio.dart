import 'package:flutter/material.dart';

class ContenidoInicio extends StatelessWidget {
  const ContenidoInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            sliver: SliverList.list(
              children: const [
                _Encabezado(),
                SizedBox(height: 20),
                _Buscador(),
                SizedBox(height: 26),
                _Titulo(
                  texto: '¿Qué quieres explorar?',
                  detalle: 'Encuentra una experiencia para hoy',
                ),
                SizedBox(height: 12),
                _Actividades(),
                SizedBox(height: 28),
                _Titulo(
                  texto: 'Destinos emergentes',
                  detalle: 'Lugares que la comunidad está descubriendo',
                ),
                SizedBox(height: 12),
                _Destinos(),
                SizedBox(height: 28),
                _Titulo(
                  texto: 'Ruta recomendada',
                  detalle: 'Compartida por exploradores locales',
                ),
                SizedBox(height: 12),
                _RutaRecomendada(),
                SizedBox(height: 28),
                _Titulo(
                  texto: 'Próxima salida comunitaria',
                  detalle: 'Conoce personas y exploren juntos',
                ),
                SizedBox(height: 12),
                _SalidaComunitaria(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, explorador',
                style: TextStyle(color: Color(0xFF695D4C), fontSize: 14),
              ),
              SizedBox(height: 3),
              Text(
                'Descubre el Perú',
                style: TextStyle(
                  color: Color(0xFF26382D),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: const Color(0xFFF7F1E7),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {},
            icon: const Badge(
              smallSize: 7,
              child: Icon(Icons.notifications_none_rounded),
            ),
          ),
        ),
      ],
    );
  }
}

class _Buscador extends StatelessWidget {
  const _Buscador();

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'Busca destinos, rutas o actividades',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: const Icon(Icons.tune_rounded),
        filled: true,
        fillColor: const Color(0xFFFDFBF7).withValues(alpha: 0.94),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;
  final String detalle;

  const _Titulo({required this.texto, required this.detalle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texto,
          style: const TextStyle(
            color: Color(0xFF26382D),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          detalle,
          style: const TextStyle(color: Color(0xFF756A5D), fontSize: 13),
        ),
      ],
    );
  }
}

class _Actividades extends StatelessWidget {
  const _Actividades();

  static const _datos = [
    (nombre: 'Trekking', icono: Icons.hiking_rounded),
    (nombre: 'Ciclismo', icono: Icons.directions_bike_rounded),
    (nombre: 'Gastronomía', icono: Icons.restaurant_rounded),
    (nombre: 'Naturaleza', icono: Icons.forest_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _datos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, indice) {
          final actividad = _datos[indice];
          return Container(
            width: 90,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFBF7).withValues(alpha: 0.93),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7D8C3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(actividad.icono, color: const Color(0xFF2F684C)),
                const SizedBox(height: 8),
                Text(
                  actividad.nombre,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF443C32),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Destinos extends StatelessWidget {
  const _Destinos();

  static const _datos = [
    (
      nombre: 'Cañón de los Perdidos',
      ubicacion: 'Ica',
      senal: 'Interés en crecimiento',
      icono: Icons.landscape_rounded,
      color: Color(0xFFB96F45),
    ),
    (
      nombre: 'Nor Yauyos-Cochas',
      ubicacion: 'Lima · Junín',
      senal: 'Muy guardado esta semana',
      icono: Icons.water_rounded,
      color: Color(0xFF397A76),
    ),
    (
      nombre: 'Bosque de Piedras',
      ubicacion: 'Pasco',
      senal: 'Nuevo en la comunidad',
      icono: Icons.terrain_rounded,
      color: Color(0xFF6D7450),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 205,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _datos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, indice) {
          final destino = _datos[indice];
          return Container(
            width: 240,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [destino.color, destino.color.withValues(alpha: 0.72)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 14,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(destino.icono, color: Colors.white, size: 32),
                    const Icon(Icons.favorite_border, color: Colors.white),
                  ],
                ),
                const Spacer(),
                Text(
                  destino.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  destino.ubicacion,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                _Etiqueta(texto: destino.senal),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;

  const _Etiqueta({required this.texto});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RutaRecomendada extends StatelessWidget {
  const _RutaRecomendada();

  @override
  Widget build(BuildContext context) {
    return _TarjetaClara(
      hijo: Row(
        children: [
          Container(
            width: 64,
            height: 86,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE8DE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: Color(0xFF2F684C),
              size: 34,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laguna Humantay por Soraypampa',
                  style: TextStyle(
                    color: Color(0xFF26382D),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Cusco · 7,2 km · Dificultad media',
                  style: TextStyle(color: Color(0xFF756A5D), fontSize: 12),
                ),
                SizedBox(height: 9),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE29A3B),
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text('4,8'),
                    SizedBox(width: 14),
                    Icon(Icons.people_outline, size: 18),
                    SizedBox(width: 4),
                    Text('126'),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _TarjetaClara extends StatelessWidget {
  final Widget hijo;

  const _TarjetaClara({required this.hijo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7D8C3)),
      ),
      child: hijo,
    );
  }
}

class _SalidaComunitaria extends StatelessWidget {
  const _SalidaComunitaria();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF294F3B).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _Fecha(),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caminata a Huchuy Qosqo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Comunidad Caminantes del Cusco',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '06:30  ·  8 de 12 cupos disponibles',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE9B75F),
                foregroundColor: const Color(0xFF26382D),
              ),
              child: const Text('Ver salida'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fecha extends StatelessWidget {
  const _Fecha();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Text(
            '24',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'AGO',
            style: TextStyle(
              color: Color(0xFFE9B75F),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
