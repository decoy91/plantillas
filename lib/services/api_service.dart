import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/registro_model.dart';

class ApiService {
  // Cambia esto por la IP de tu VPS o tu dominio
  static const String baseUrl = "https://klificapp.cloud";

  // --- MÉTODO DE LOGIN ---
  Future<Map<String, dynamic>> login(String usuario, String contra) async {
    final url = Uri.parse("$baseUrl/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "usuario": usuario,
          "contra": contra,
          "mac_cliente": "MOVIL", 
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? "Error en el servidor");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }
  }

  // --- MÉTODO DE BÚSQUEDA ---
  Future<List<RegistroPlantilla>> buscarRegistros(String termino) async {
    if (termino.length < 3) return [];

    final url = Uri.parse("$baseUrl/buscar?termino=$termino");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => RegistroPlantilla.fromJson(item)).toList();
      } else {
        throw Exception("Error al obtener datos");
      }
    } catch (e) {
      throw Exception("Error de red: $e");
    }
  }

  // --- MÉTODO DE ADMINISTRACIÓN (REGISTRO) ---
  Future<Map<String, dynamic>> registrarUsuario(
    Map<String, dynamic> datos,
  ) async {
    final url = Uri.parse("$baseUrl/usuarios");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user": datos['user'],
          "pass_word": datos['pass'],
          "nivel": datos['nivel'],
          "activo": datos['activo'],
          "direccion_mac": datos['direccion_mac'],
          "tablas_autorizadas": datos['tablas_autorizadas'],
          "guardar_log": datos['guardar_log'],
          // --- NUEVOS CAMPOS ENVIADOS ---
          "hora_inicio": datos['hora_inicio'],
          "hora_fin": datos['hora_fin'],
          "validar_horario": datos['validar_horario'],
        }),
      );

      if (response.statusCode == 200) {
        return {"success": true};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorData['detail'] ?? "Error desconocido",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión"};
    }
  }

  Future<List<dynamic>> obtenerUsuarios() async {
    final url = Uri.parse("$baseUrl/usuarios");
    final response = await http.get(url);
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  Future<bool> actualizarEstadoUsuario(int id, int nuevoEstado) async {
    final url = Uri.parse("$baseUrl/usuarios/estado");
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id, "activo": nuevoEstado}),
    );
    return response.statusCode == 200;
  }

  Future<bool> eliminarUsuario(int id) async {
    final url = Uri.parse("$baseUrl/usuarios/$id");
    try {
      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> editarUsuario(Map<String, dynamic> datos) async {
    // 1. Extraemos el ID para ponerlo en la URL
    final int userId = datos['id']; 
    // 2. La URL debe llevar el ID al final: /usuarios/5
    final url = Uri.parse("$baseUrl/usuarios/$userId"); 

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user": datos['user'],
          "pass_word": datos['pass_word'], 
          "nivel": datos['nivel'],
          "activo": datos['activo'] ?? 1, // Asegúrate de enviar 'activo'
          "direccion_mac": datos['direccion_mac'],
          "tablas_autorizadas": datos['tablas_autorizadas'],
          "hora_inicio": datos['hora_inicio'],
          "hora_fin": datos['hora_fin'],
          "validar_horario": datos['validar_horario'],
        }),
      );
      
      // Imprime para debug si falla
      if (response.statusCode != 200) {
      }
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cambiarMiPassword(String usuario, String nuevaPass) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/usuarios/cambiar_pass"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user": usuario,
          "pass_word": nuevaPass,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}