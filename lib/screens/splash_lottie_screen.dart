import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Importa la librería
import 'login_screen.dart';

class SplashLottieScreen extends StatefulWidget {
  const SplashLottieScreen({super.key});

  @override
  State<SplashLottieScreen> createState() => _SplashLottieScreenState();
}

class _SplashLottieScreenState extends State<SplashLottieScreen> {
  @override
  void initState() {
    super.initState();
    // Le damos 4 segundos para que se aprecie la animación
    Timer(const Duration(seconds: 3), () {
  if (!mounted) return;
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 800), // Desvanecimiento suave
    ),
  );
});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí cargamos tu archivo JSON
            Lottie.asset(
              'assets/search.json',
              width: 250,
              repeat: true, // Que se repita mientras carga
            ),
            const SizedBox(height: 20),
            const Text(
              "SISTEMA DE PLANTILLA",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}