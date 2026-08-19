-- Catálogo Fase 1: lugares semilla (coinciden con LugaresDataSourceLocal).
insert into lugares (
  id, nombre, descripcion, imagen_url, galeria, categoria_id, provincia, distrito,
  latitud, longitud, distancia_km, calificacion, exploradores, fotos,
  nivel_exploracion, dificultad, tiempo_estimado, altitud, acceso, creado_por_usuario
) values
  (
    'laguna_humantay',
    'Laguna Humantay',
    'Laguna turquesa al pie del nevado Humantay. Información enriquecida por la comunidad HAKU.',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
    '["https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80","https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&q=80"]'::jsonb,
    'naturaleza', 'Anta', 'Mollepata',
    -13.3840, -72.6200, 24, 4.8, 6, 42,
    'enCrecimiento', 'Moderada', '5–6 h', '4200 msnm', 'Caminata desde Soraypampa', false
  ),
  (
    'canon_qeswachaka',
    'Cañón Q''eswachaka',
    'Puente inca vivo y cañón profundo. Descubierto recientemente en HAKU.',
    'https://images.unsplash.com/photo-1548013146-72479768bada?w=800&q=80',
    '[]'::jsonb,
    'misterioso', 'Canas', 'Quehue',
    -14.2150, -71.4180, 78, 4.6, 4, 12,
    'nuevoEnHaku', 'Fácil', '3 h', '3700 msnm', 'Transporte + corto tramo a pie', false
  ),
  (
    'moray',
    'Moray',
    'Anfiteatro agrícola inca con microclimas únicos.',
    'assets/destinos/moray.jpg',
    '[]'::jsonb,
    'cultura', 'Urubamba', 'Maras',
    -13.3280, -72.1960, 38, 4.7, 32, 88,
    'muyConocido', 'Fácil', '2 h', '3500 msnm', 'Auto o tour', false
  ),
  (
    'ausangate_vista',
    'Mirador Ausangate',
    'Vistas al nevado sagrado. Zona en crecimiento en HAKU.',
    'assets/destinos/ausangate.jpg',
    '[]'::jsonb,
    'caminata', 'Quispicanchi', 'Ocongate',
    -13.7900, -71.2300, 95, 4.9, 11, 27,
    'pocoExplorado', 'Difícil', '1 día', '4800 msnm', 'Trekking', false
  ),
  (
    'machu_picchu',
    'Machu Picchu',
    'Ciudadela inca. Muy documentada; aún se puede enriquecer.',
    'assets/destinos/machu_picchu.jpg',
    '[]'::jsonb,
    'cultura', 'Urubamba', 'Machupicchu',
    -13.1631, -72.5450, 110, 4.9, 120, 400,
    'muyConocido', 'Moderada', '1 día', '2430 msnm', 'Tren + bus', false
  ),
  (
    'laguna_oculta',
    'Laguna Escondida de Calca',
    'Poco explorada. Ideal para documentar.',
    'https://images.unsplash.com/photo-1439066615861-d1af74d74000?w=800&q=80',
    '[]'::jsonb,
    'magico', 'Calca', 'Lares',
    -13.2100, -72.0200, 52, 4.5, 2, 5,
    'pocoExplorado', 'Moderada', '4 h', '3900 msnm', 'Caminata', false
  )
on conflict (id) do update set
  nombre = excluded.nombre,
  descripcion = excluded.descripcion,
  categoria_id = excluded.categoria_id,
  provincia = excluded.provincia,
  distrito = excluded.distrito;
