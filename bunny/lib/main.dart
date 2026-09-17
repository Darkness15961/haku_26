import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'pantalla_prueba_s3.dart';
import 'video_service.dart';
import 'reproductor_haku.dart';

// Instancia global para llamarla fácilmente
final supabase = Supabase.instance.client;




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. INICIALIZAR CONEXIÓN CON TU VPS
  await Supabase.initialize(
    url: 'https://supabase.haku.best',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhha3UiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTc4MzU1MTM0MiwiZXhwIjo0MTAyNDQ0ODAwfQ.vADeXIoed1f_EmbUeh8PO8whhz7jtxI3hsHbXth0TU8', 
  );

  runApp(const HakuPruebaApp());
}

class HakuPruebaApp extends StatelessWidget {
  const HakuPruebaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haku Prueba',
      theme: ThemeData.dark(), // Un tema oscuro para que se vea bien rápido
      home: const AuthGate(),
    );
  }
}

// 2. EL "PORTERO" (Decide qué pantalla mostrar de forma reactiva)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Verificación reactiva en tiempo real
        final session = supabase.auth.currentSession;
        return session == null ? const LoginScreen() : const HomeScreen();
      },
    );
  }
}

// 3. PANTALLA DE LOGIN
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _loginConGoogle() async {
    try {
      // AQUÍ ESTÁ LA MAGIA (REGLA 1)
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'hakuapp://login-callback', // El Deep link que configuramos
      );
    } catch (e) {
      debugPrint('Error de inicio de sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login HAKU')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _loginConGoogle,
          icon: const Icon(Icons.login),
          label: const Text('Ingresar con Google'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }
}

// 4. PANTALLA PRINCIPAL (HOME)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _actualizarNombre(BuildContext context) async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // PRUEBA DE LA REGLA 2 Y RLS
        await supabase
            .from('usuarios')
            .update({'nombre': 'Jhon Tech Lead'})
            .eq('id', user.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nombre actualizado en base de datos')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    try {
      await supabase.auth.signOut();
      // Reactivo a través del StreamBuilder en AuthGate, no requiere Navigator.push
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenido')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ID: ${user?.id}', textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('Correo: ${user?.email}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _actualizarNombre(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(250, 45),
              ),
              child: const Text('Probar Update (Cambiar Nombre)'),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PantallaPruebaS3()),
                );
              },
              icon: const Icon(Icons.science),
              label: const Text('Laboratorio AWS S3 (CRUD)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(250, 45),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () async {
                // 1. Abrir la galería para elegir el video físico
                final ImagePicker picker = ImagePicker();
                final XFile? videoSeleccionado = await picker.pickVideo(
                  source: ImageSource.gallery,
                );

                if (videoSeleccionado == null) {
                  print('⚠️ Selección cancelada: El usuario no eligió ningún video.');
                  return;
                }

                final videoService = VideoService();

                // 2. Fase 7.1: Pedir permiso al VPS (Usando el ID 1 de prueba)
                final ticketData = await videoService.solicitarTicketVideo(1);

                // 3. Fase 7.2 + 7.3: Si hay ticket, encender el motor TUS y subir
                if (ticketData != null) {
                  final subidaExitosa = await videoService.subirVideoConTus(
                    videoSeleccionado,
                    ticketData,
                  );

                  if (subidaExitosa) {
                    // 4. Fase 7.4: Handoff - Sincronizar estado en la BD
                    final handoffExitoso = await videoService.confirmarVideoListo(ticketData['guid'].toString());

                    if (handoffExitoso) {
                      print('🎬 ¡Proceso E2E completado! El video está listo en el Feed.');
                    }
                  }
                } else {
                  print('❌ Abortando subida: No se pudo obtener el pase de abordar.');
                }
              },
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Seleccionar y Subir Video (TUS)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(250, 45),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Aquí está el GUID del último video que subiste:
                    builder: (context) => const PantallaPruebaHls(videoGuid: '10093eda-07ab-4a81-a225-12e952647410'), 
                  ),
                );
              },
              icon: const Icon(Icons.play_circle_filled),
              label: const Text('Probar Reproductor HLS (Fase 8)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(250, 45),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => _cerrarSesion(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(250, 45),
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}