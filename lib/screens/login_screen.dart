import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importante para el guardado
import '../services/api_service.dart';
import 'busqueda_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;
  
  // --- NUEVAS VARIABLES PARA RECORDAR PASS ---
  bool _recordarPass = false;

  @override
  void initState() {
    super.initState();
    _cargarCredencialesGuardadas(); // Cargar al iniciar la pantalla
  }

  // Carga los datos desde el almacenamiento local
  Future<void> _cargarCredencialesGuardadas() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recordarPass = prefs.getBool('recordar_pass') ?? false;
      if (_recordarPass) {
        _userController.text = prefs.getString('user_pref') ?? "";
        _passController.text = prefs.getString('pass_pref') ?? "";
      }
    });
  }

  // Guarda o borra según el estado del checkbox
  Future<void> _gestionarPersistencia() async {
    final prefs = await SharedPreferences.getInstance();
    if (_recordarPass) {
      await prefs.setBool('recordar_pass', true);
      await prefs.setString('user_pref', _userController.text);
      await prefs.setString('pass_pref', _passController.text);
    } else {
      // Si el usuario desmarca la opción, limpiamos los datos guardados
      await prefs.remove('recordar_pass');
      await prefs.remove('user_pref');
      await prefs.remove('pass_pref');
    }
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final response = await api.login(_userController.text, _passController.text);
      
      debugPrint("Respuesta del servidor: $response");

      if (response['success'] == true) {
        // --- GUARDAR O LIMPIAR CREDENCIALES ANTES DE NAVEGAR ---
        await _gestionarPersistencia();

        if (!mounted) return;

        int nivelUsuario = int.tryParse(response['nivel']?.toString() ?? "2") ?? 2;
        var rawPermisos = response['tablas_autorizadas'];
        int permisosBitmask = int.tryParse(rawPermisos?.toString() ?? "0") ?? 0;

        debugPrint("Permisos calculados para enviar: $permisosBitmask");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BusquedaScreen(
              nivel: nivelUsuario, 
              usuario: _userController.text,
              permisosBit: permisosBitmask, 
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      String errorMsg = e.toString().replaceAll("Exception: ", "");
      bool esHorario = errorMsg.toLowerCase().contains("horario");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                esHorario ? Icons.access_time_filled : Icons.error_outline, 
                color: Colors.white
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMsg)),
            ],
          ), 
          backgroundColor: esHorario ? Colors.orange.shade800 : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade800,
              Colors.indigo.shade500,
              Colors.blue.shade300,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView( 
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Lottie.asset(
                    'assets/search.json', 
                    width: 150,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.security, size: 100, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "BIENVENIDO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  "Plantilla Digital",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),
                
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _userController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: "Usuario",
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passController,
                          obscureText: _obscureText,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            labelText: "Contraseña",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscureText = !_obscureText),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        
                        // --- CHECKBOX DE RECORDAR CREDENCIALES ---
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Recordar credenciales", style: TextStyle(fontSize: 14)),
                          value: _recordarPass,
                          activeColor: Colors.indigo,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (val) => setState(() => _recordarPass = val ?? false),
                        ),

                        const SizedBox(height: 10),
                        _isLoading 
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo.shade700, 
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  "INGRESAR",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "v2.0",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}