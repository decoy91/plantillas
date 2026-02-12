import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Importante para kIsWeb
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plantilla/screens/admin_screen.dart';
import '../services/api_service.dart';
import '../models/registro_model.dart';
import 'detalle_screen.dart';
import 'login_screen.dart';

class BusquedaScreen extends StatefulWidget {
  final int nivel;
  final String usuario;
  final int permisosBit;

  const BusquedaScreen({
    super.key, 
    required this.nivel, 
    required this.usuario,
    required this.permisosBit,
  });

  @override
  State<BusquedaScreen> createState() => _BusquedaScreenState();
}

class _BusquedaScreenState extends State<BusquedaScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<RegistroPlantilla> _resultados = [];
  bool _isSearching = false;
  bool _isGrouped = true;
  Timer? _debounce;

  final Map<String, List<RegistroPlantilla>> _cacheBusquedas = {};

  @override
  void initState() {
    super.initState();
    _cargarPreferenciaVista();
    _searchController.addListener(() {
      final String text = _searchController.text;
      if (text != text.toUpperCase()) {
        _searchController.value = _searchController.value.copyWith(
          text: text.toUpperCase(),
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
      setState(() {});
    });
  }

  Future<void> _cargarPreferenciaVista() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGrouped = prefs.getBool('isGrouped') ?? true;
    });
  }

  Future<void> _guardarPreferenciaVista(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGrouped', valor);
  }

  Map<String, List<RegistroPlantilla>> _agruparYOrdenar(List<RegistroPlantilla> registros) {
    Map<String, List<RegistroPlantilla>> agrupados = {};
    for (var reg in registros) {
      String anio = reg.anio ?? "S/A";
      if (!agrupados.containsKey(anio)) agrupados[anio] = [];
      agrupados[anio]!.add(reg);
    }
    agrupados.forEach((anio, lista) {
      lista.sort((a, b) {
        int qnaA = int.tryParse(a.qna ?? "0") ?? 0;
        int qnaB = int.tryParse(b.qna ?? "0") ?? 0;
        return qnaB.compareTo(qnaA);
      });
    });
    return agrupados;
  }

  Map<String, dynamic> _obtenerInfoGenero(String? curp) {
    if (curp != null && curp.length >= 11) {
      String generoChar = curp[10].toUpperCase();
      if (generoChar == 'H') return {'icono': Icons.male, 'color': Colors.blue.shade700};
      if (generoChar == 'M') return {'icono': Icons.female, 'color': Colors.pink.shade400};
    }
    return {'icono': Icons.person, 'color': Colors.indigo};
  }

  void _mostrarDialogoCambiarPass() {
    final TextEditingController newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [Icon(Icons.vpn_key, color: Colors.indigo), SizedBox(width: 10), Text("Cambiar Contraseña")],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: TextField(
            controller: newPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Nueva Contraseña", border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          FilledButton(
            onPressed: () async {
              if (newPassCtrl.text.trim().isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final success = await _apiService.cambiarMiPassword(widget.usuario, newPassCtrl.text.trim());
              if (!mounted) return;
              navigator.pop();
              if (success) {
                messenger.showSnackBar(const SnackBar(content: Text("Contraseña actualizada"), backgroundColor: Colors.green));
              } else {
                messenger.showSnackBar(const SnackBar(content: Text("Error"), backgroundColor: Colors.red));
              }
            },
            child: const Text("ACTUALIZAR"),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmarSalidaApp() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Salir"),
            content: const Text("¿Cerrar aplicación?"),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("CANCELAR")),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("SALIR")),
            ],
          ),
        ) ?? false;
  }

  Future<bool> _confirmarCerrarSesion() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Cerrar Sesión"),
            content: const Text("¿Estás seguro?"),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("CANCELAR")),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("CERRAR"),
              ),
            ],
          ),
        ) ?? false;
  }

  void _ejecutarBusqueda(String query) async {
    query = query.trim().toUpperCase();
    if (query.length < 3) {
      setState(() => _resultados = []);
      return;
    }
    
    setState(() => _isSearching = true);

    if (_cacheBusquedas.containsKey(query)) {
      if (mounted) {
        setState(() {
          _resultados = _cacheBusquedas[query]!;
          _isSearching = false;
        });
      }
      return;
    }

    try {
      final res = await _apiService.buscarRegistros(query);
      _cacheBusquedas[query] = res;
      if (mounted) setState(() => _resultados = res);
    } catch (e) {
      debugPrint("Error en búsqueda: $e");
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final agrupados = _agruparYOrdenar(_resultados);
    final listaAnios = agrupados.keys.toList()..sort((a, b) => b.compareTo(a));
    // Definimos el ancho máximo para la web
    final double maxContentWidth = kIsWeb ? 850 : double.infinity;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmarSalidaApp() && mounted) {
          if (kIsWeb) {
             // En web no cerramos la pestaña por comando, se sugiere logout
          } else if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else {exit(0);}
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text("Buscador Plantilla", style: TextStyle(fontSize: kIsWeb ? 35 : null ),),
          centerTitle: kIsWeb,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(_isGrouped ? Icons.view_day : Icons.account_tree_outlined),
              tooltip: _isGrouped ? "Vista Plana" : "Vista Agrupada",
              onPressed: () {
                setState(() => _isGrouped = !_isGrouped);
                _guardarPreferenciaVista(_isGrouped);
              },
            ),
            IconButton(icon: const Icon(Icons.key), onPressed: _mostrarDialogoCambiarPass),
            if (widget.nivel == 1)
              IconButton(
                icon: const Icon(Icons.admin_panel_settings),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminScreen())),
              ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (await _confirmarCerrarSesion() && mounted) {
                  navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (value) => _ejecutarBusqueda(value),
                      textInputAction: TextInputAction.search,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: "BUSCAR POR NOMBRE O RFC...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear), 
                                onPressed: () { 
                                  _searchController.clear(); 
                                  setState(() => _resultados = []); 
                                }
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  if (_isSearching) const LinearProgressIndicator(),
                  Expanded(
                    child: _resultados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                //Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 10),
                                Text(
                                  _isSearching ? "Stalkeando 😱..." : "¿A quién vamos a buscar? 😈", 
                                  style: TextStyle(fontSize: kIsWeb ? 35 : 20, color: Colors.grey.shade500)
                                ),
                              ],
                            )
                          )
                        : _isGrouped ? _buildGroupedList(agrupados, listaAnios) : _buildFlatList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedList(Map<String, List<RegistroPlantilla>> agrupados, List<String> listaAnios) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
      itemCount: listaAnios.length,
      itemBuilder: (context, index) {
        final anio = listaAnios[index];
        final registros = agrupados[anio]!;
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ExpansionTile(
            // initiallyExpanded: index == 0, // Expandir el año más reciente por defecto
            shape: const Border(),
            collapsedShape: const Border(),
            leading: const Icon(Icons.calendar_today, color: Colors.indigo),
            title: Text("AÑO $anio", style: const TextStyle(fontSize: kIsWeb ? 20 : null, fontWeight: FontWeight.bold, color: Colors.indigo)),
            subtitle: Text("${registros.length} registros encontrados", style: const TextStyle(fontSize: kIsWeb ? 15 : 11)),
            children: registros.map((item) => _buildResultTile(item)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFlatList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
      itemCount: _resultados.length,
      itemBuilder: (context, index) => Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: _buildResultTile(_resultados[index]),
      ),
    );
  }

  Widget _buildResultTile(RegistroPlantilla item) {
    final infoGenero = _obtenerInfoGenero(item.curp);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: infoGenero['color'].withOpacity(0.1),
        child: Icon(infoGenero['icono'], color: infoGenero['color'], size: kIsWeb ? 33 : 20),
      ),
      title: Text(
        item.nombre ?? "",
        style: const TextStyle(fontSize: kIsWeb ? 15 : 13, fontWeight: FontWeight.bold),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            children: [
              const TextSpan(
                text: "QNA: ",
                style: TextStyle(fontSize: kIsWeb ? 15 : null),
                ),
              TextSpan(
                text: "QNA: ${item.qna}",
                style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: kIsWeb ? 15 : null),
              ),
              const TextSpan(
                text: " | AÑO: ",
                style: TextStyle(fontSize: kIsWeb ? 15 : null),
                ),
              TextSpan(
                text: "${item.anio}",
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: kIsWeb ? 15 : null),
              ),
              TextSpan(
                text: " | RFC: ${item.rfc}",
                style: TextStyle(fontSize: kIsWeb ? 15 : null),),
            ],
          ),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetalleRegistroScreen(
            registro: item,
            permisos: widget.permisosBit, 
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}