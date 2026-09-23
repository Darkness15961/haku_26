import 'package:flutter_test/flutter_test.dart';
import 'package:haku/funcionalidades/rutas/dominio/modelos/solicitud_crear_ruta.dart';

void main() {
  test('valida minimo de paradas y duplicados', () {
    final unaParada = SolicitudCrearRuta(
      nombre: 'Ruta corta',
      resumen: 'Resumen corto',
      descripcion: 'Descripcion suficiente.',
      zona: 'Cusco',
      paradas: const [ParadaRutaEscritura(lugarId: '10', nombre: 'Inicio')],
    );

    expect(unaParada.validar(), 'Elige al menos dos Lugares');

    final repetida = SolicitudCrearRuta(
      nombre: 'Ruta repetida',
      resumen: 'Resumen corto',
      descripcion: 'Descripcion suficiente.',
      zona: 'Cusco',
      paradas: const [
        ParadaRutaEscritura(lugarId: '10', nombre: 'Inicio'),
        ParadaRutaEscritura(lugarId: '10', nombre: 'Destino'),
      ],
    );

    expect(repetida.validar(), 'No repitas el mismo Lugar en la Ruta');
  });

  test('exige resumen y zona para una Ruta publicable', () {
    const paradas = [
      ParadaRutaEscritura(lugarId: '10', nombre: 'Inicio'),
      ParadaRutaEscritura(lugarId: '11', nombre: 'Destino'),
    ];

    final sinResumen = SolicitudCrearRuta(
      nombre: 'Ruta sin resumen',
      resumen: '',
      descripcion: 'Descripcion suficiente.',
      zona: 'Cusco',
      paradas: paradas,
    );

    expect(sinResumen.validar(), 'Escribe un resumen corto de la Ruta');

    final sinZona = SolicitudCrearRuta(
      nombre: 'Ruta sin zona',
      resumen: 'Resumen corto',
      descripcion: 'Descripcion suficiente.',
      paradas: paradas,
    );

    expect(sinZona.validar(), 'Confirma la zona de la Ruta');
  });

  test('genera payload RPC limpio', () {
    final solicitud = SolicitudCrearRuta(
      nombre: '  Camino del Sol  ',
      resumen: '  Recorrido cultural  ',
      descripcion: '  Dos paradas conectadas por lugares activos.  ',
      fotoPortadaUrl: ' https://img.test/ruta.jpg ',
      tipo: TipoRutaEscritura.cultural,
      dificultad: DificultadRutaEscritura.facil,
      hilo: HiloRutaEscritura.camino,
      zona: ' Cusco ',
      acceso: ' Libre ',
      requisitos: const [' Agua ', '', 'Sombrero'],
      advertencias: const ['Aclimatarse', 'Aclimatarse'],
      etiquetas: listaTextoCsv('cultura, caminata, cultura'),
      paradas: const [
        ParadaRutaEscritura(lugarId: '101', nombre: 'Inicio'),
        ParadaRutaEscritura(
          lugarId: '102',
          nombre: 'Destino',
          instrucciones: 'Mirador final',
        ),
      ],
    );

    expect(solicitud.validar(), isNull);

    final params = solicitud.toRpcParams();
    expect(params['p_nombre'], 'Camino del Sol');
    expect(params['p_tipo'], 'cultural');
    expect(params['p_dificultad'], 'facil');
    expect(params['p_zona'], 'Cusco');
    expect(params['p_acceso'], 'Libre');
    expect(params['p_requisitos'], ['Agua', 'Sombrero']);
    expect(params['p_advertencias'], ['Aclimatarse']);
    expect(params['p_etiquetas'], ['cultura', 'caminata']);
    expect(params['p_paradas'], [
      {'lugar_id': '101'},
      {'lugar_id': '102', 'instrucciones': 'Mirador final'},
    ]);
  });

  test('exige acceso, requisitos y advertencias en la ficha', () {
    const paradas = [
      ParadaRutaEscritura(lugarId: '10', nombre: 'Inicio'),
      ParadaRutaEscritura(lugarId: '11', nombre: 'Destino'),
    ];

    final sinAcceso = SolicitudCrearRuta(
      nombre: 'Ruta ficha',
      resumen: 'Resumen corto',
      descripcion: 'Descripcion suficiente.',
      zona: 'Cusco',
      paradas: paradas,
      requisitos: const ['Agua'],
      advertencias: const ['Altitud'],
    );

    expect(sinAcceso.validar(), 'Elige el acceso de la Ruta');

    final sinRequisitos = SolicitudCrearRuta(
      nombre: 'Ruta ficha',
      resumen: 'Resumen corto',
      descripcion: 'Descripcion suficiente.',
      zona: 'Cusco',
      acceso: 'Libre',
      paradas: paradas,
      advertencias: const ['Altitud'],
    );

    expect(sinRequisitos.validar(), 'Agrega al menos un requisito');

    final sinAdvertencias = SolicitudCrearRuta(
      nombre: 'Ruta ficha',
      resumen: 'Resumen corto',
      descripcion: 'Descripcion suficiente.',
      zona: 'Cusco',
      acceso: 'Libre',
      paradas: paradas,
      requisitos: const ['Agua'],
    );

    expect(sinAdvertencias.validar(), 'Agrega al menos una advertencia');
  });
}
