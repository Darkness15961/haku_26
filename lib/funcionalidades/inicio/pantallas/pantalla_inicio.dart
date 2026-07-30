import 'package:flutter/material.dart';

import '../../destinos/indice.dart';
import '../../favoritos/indice.dart';
import '../../perfil_usuario/indice.dart';
import '../../rutas/indice.dart';
import '../widgets/contenido_inicio.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _EstadoPantallaInicio();
}

class _EstadoPantallaInicio extends State<PantallaInicio> {
  int _indiceSeleccionado = 0;

  static const List<Widget> _pantallas = [
    ContenidoInicio(),
    PantallaDestinos(),
    PantallaRutas(),
    PantallaFavoritos(),
    PantallaPerfilUsuario(),
  ];

  void _seleccionarSeccion(int indice) {
    setState(() => _indiceSeleccionado = indice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indiceSeleccionado, children: _pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceSeleccionado,
        onDestinationSelected: _seleccionarSeccion,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Destinos',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Rutas',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
