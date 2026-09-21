/// Datos de un perfil ajeno (vista pública).
class PerfilPublico {
  final String id;
  final String nombre;
  final String usuario;
  final String avatarUrl;
  final String bioCorta;
  final int nivel;
  final int xpActual;
  final int xpMeta;
  final String lugaresVisitados;
  final String rutasCompletadas;
  final String experiencias;
  final String insignias;
  final List<String> publicacionesUrls;
  final String destinoSugeridoTitulo;
  final String destinoSugeridoUrl;

  const PerfilPublico({
    required this.id,
    required this.nombre,
    required this.usuario,
    required this.avatarUrl,
    this.bioCorta = '',
    this.nivel = 12,
    this.xpActual = 3500,
    this.xpMeta = 5000,
    this.lugaresVisitados = '24',
    this.rutasCompletadas = '8',
    this.experiencias = '12',
    this.insignias = '3',
    this.publicacionesUrls = const [
      'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=400&q=80',
      'https://images.unsplash.com/photo-1587595431973-160d0d94add1?w=400&q=80',
      'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400&q=80',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&q=80',
      'https://images.unsplash.com/photo-1548013146-72479768bada?w=400&q=80',
      'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=400&q=80',
    ],
    this.destinoSugeridoTitulo = 'Parque Nacional Ausangate',
    this.destinoSugeridoUrl =
        'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400&q=80',
  });
}
