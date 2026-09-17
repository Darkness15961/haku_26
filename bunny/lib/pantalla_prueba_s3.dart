import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'multimedia_service.dart';

class PantallaPruebaS3 extends StatefulWidget {
  const PantallaPruebaS3({super.key});

  @override
  State<PantallaPruebaS3> createState() => _PantallaPruebaS3State();
}

class _PantallaPruebaS3State extends State<PantallaPruebaS3> {
  final _servicio = MultimediaService();
  final _idPublicacionController = TextEditingController(text: "1");
  
  bool _estaCargando = false;
  String _mensaje = "Establece el ID de Publicación y sube una foto.";
  String? _urlImagenSubida;

  @override
  void dispose() {
    _idPublicacionController.dispose();
    super.dispose();
  }

  int get _idPublicacion {
    return int.tryParse(_idPublicacionController.text) ?? 1;
  }

  void _ejecutarSubida() async {

    // --- 🕵️ INICIO DEL DETECTOR DE MENTIRAS ---
    final usuarioActual = Supabase.instance.client.auth.currentUser;
    if (usuarioActual == null) {
      setState(() {
        _mensaje = "🚨 BLOQUEADO: No hay ningún usuario logueado en la app.";
      });
      print("🚨 ERROR FATAL: auth.currentUser es NULL.");
      return; // Aborta la subida antes de gastar internet
    }
    print("✅ EL CELULAR ESTÁ USANDO ESTE UUID: ${usuarioActual.id}");
    // --- 🕵️ FIN DEL DETECTOR ---


    setState(() {
      _estaCargando = true;
      _mensaje = "Iniciando subida hacia S3...";
    });

    final String? resultadoUrl = await _servicio.subirFotoDePrueba(_idPublicacion); 

    setState(() {
      _estaCargando = false;
      if (resultadoUrl != null) {
        _urlImagenSubida = resultadoUrl;
        _mensaje = "¡ÉXITO ROTUNDO! Imagen subida y registrada.";
      } else {
        _mensaje = "FALLÓ LA SUBIDA. Revisa la consola para el error exacto (verifica si existe el ID de Publicación).";
      }
    });
  }

  void _ejecutarActualizacion() async {
    if (_urlImagenSubida == null) return;
    
    setState(() {
      _estaCargando = true;
      _mensaje = "Actualizando archivo en S3...";
    });

    final String? nuevaUrl = await _servicio.actualizarFoto(_urlImagenSubida!, _idPublicacion);

    setState(() {
      _estaCargando = false;
      if (nuevaUrl != null) {
        _urlImagenSubida = nuevaUrl;
        _mensaje = "¡IMAGEN ACTUALIZADA CON ÉXITO! Registro anterior borrado.";
      } else {
        _mensaje = "FALLÓ LA ACTUALIZACIÓN. Revisa la consola.";
      }
    });
  }

  void _ejecutarEliminacion() async {
    if (_urlImagenSubida == null) return;

    setState(() {
      _estaCargando = true;
      _mensaje = "Eliminando archivo de S3...";
    });

    final bool exito = await _servicio.eliminarFoto(_urlImagenSubida!);

    setState(() {
      _estaCargando = false;
      if (exito) {
        _urlImagenSubida = null;
        _mensaje = "¡IMAGEN ELIMINADA CON ÉXITO de S3 y Base de Datos!";
      } else {
        _mensaje = "FALLÓ LA ELIMINACIÓN. Revisa la consola.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laboratorio AWS S3 & Postgres')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Configuración de Prueba",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _idPublicacionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "ID de la Publicación (Debe existir en la base de datos)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Estado / Mensaje
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    if (_estaCargando) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      _mensaje, 
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), 
                      textAlign: TextAlign.center
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Visualizador de Imagen
              if (_urlImagenSubida != null) ...[
                const Text(
                  "Imagen en S3:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 220,
                    color: Colors.black26,
                    child: Image.network(
                      _urlImagenSubida!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image, size: 50, color: Colors.red),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  "No se pudo cargar la imagen:\n$_urlImagenSubida",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  "URL: $_urlImagenSubida",
                  style: const TextStyle(fontSize: 11, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Botones de acción cuando ya hay una imagen
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _estaCargando ? null : _ejecutarActualizacion,
                        icon: const Icon(Icons.sync),
                        label: const Text("Actualizar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _estaCargando ? null : _ejecutarEliminacion,
                        icon: const Icon(Icons.delete),
                        label: const Text("Eliminar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(
                  height: 180,
                  child: Card(
                    color: Colors.black12,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_search, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "No hay imagen subida aún",
                          style: TextStyle(color: Colors.grey),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _estaCargando ? null : _ejecutarSubida,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("Subir Foto de Prueba"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blueAccent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}