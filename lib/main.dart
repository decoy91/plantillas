import 'package:flutter/material.dart';
import 'screens/splash_lottie_screen.dart'; // Asegúrate de crear este archivo con el código anterior

void main() {
  runApp(const MiPlantillaApp());
}

class MiPlantillaApp extends StatelessWidget {
  const MiPlantillaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión de Plantilla',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo,
          // Un fondo ligeramente gris para que las Cards y campos blancos resalten
          surface: Colors.grey.shade50, 
        ),
        // Estilo global para los campos de texto mejorado
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.indigo, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.indigo, width: 2),
          ),
        ),
      ),
      // CAMBIO AQUÍ: La app ahora inicia con la animación
      home: const SplashLottieScreen(), 
    );
  }
}