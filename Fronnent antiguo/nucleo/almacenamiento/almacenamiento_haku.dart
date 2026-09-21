import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Almacén local tipo localStorage. Documento JSON único = BD provisional.
///
/// Colecciones (mismas claves que `supabase/001_fase1.sql`):
/// perfiles, clips, publicaciones, comentarios, categorias_actividad,
/// comunidades, miembros_comunidad, interacciones, lugares_creados.
class AlmacenamientoHaku {
  static const claveDocumento = 'haku_bd_local_v1';
  static const versionEsquema = 3;

  final SharedPreferences _prefs;

  AlmacenamientoHaku(this._prefs);

  static Future<AlmacenamientoHaku> abrir() async {
    final prefs = await SharedPreferences.getInstance();
    return AlmacenamientoHaku(prefs);
  }

  Map<String, dynamic>? leer() {
    final raw = _prefs.getString(claveDocumento);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  }

  Future<void> guardar(Map<String, dynamic> documento) async {
    documento['version'] = versionEsquema;
    documento['actualizado_en'] = DateTime.now().toIso8601String();
    await _prefs.setString(claveDocumento, jsonEncode(documento));
  }

  Future<void> borrar() async {
    await _prefs.remove(claveDocumento);
  }
}
