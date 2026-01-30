import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        content: TextField(
          controller: newPassCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Nueva Contraseña", border: OutlineInputBorder()),
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

  void _onSearchChanged(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.length < 3) {
      setState(() => _resultados = []);
      return;
    }
    if (_cacheBusquedas.containsKey(query)) {
      setState(() {
        _resultados = _cacheBusquedas[query]!;
        _isSearching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 900), () async {
      setState(() => _isSearching = true);
      try {
        final res = await _apiService.buscarRegistros(query);
        _cacheBusquedas[query] = res;
        if (mounted) setState(() => _resultados = res);
      } catch (e) {
        debugPrint("Error en búsqueda: $e");
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final agrupados = _agruparYOrdenar(_resultados);
    final listaAnios = agrupados.keys.toList()..sort((a, b) => b.compareTo(a));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmarSalidaApp() && mounted) {
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else {exit(0);}
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text("Buscador"),
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
        // --- SE AGREGÓ EL SAFEAREA AQUÍ ---
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: "BUSCAR POR NOMBRE O RFC...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _onSearchChanged(""); })
                        : null,
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                  ),
                ),
              ),
              if (_isSearching) const LinearProgressIndicator(),
              Expanded(
                child: _resultados.isEmpty
                    ? Center(child: Text(_isSearching ? "Stalkeando 😱..." : "¿A quién vamos a buscar? 😈", style: const TextStyle(fontSize: 20)))
                    : _isGrouped ? _buildGroupedList(agrupados, listaAnios) : _buildFlatList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedList(Map<String, List<RegistroPlantilla>> agrupados, List<String> listaAnios) {
    return ListView.builder(
      // Se agregó padding inferior extra por si acaso
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
      itemCount: listaAnios.length,
      itemBuilder: (context, index) {
        final anio = listaAnios[index];
        final registros = agrupados[anio]!;
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            leading: const Icon(Icons.calendar_today, color: Colors.indigo),
            title: Text("AÑO $anio", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            children: registros.map((item) => _buildResultTile(item)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFlatList() {
    return ListView.builder(
      // Se agregó padding inferior extra por si acaso
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
      itemCount: _resultados.length,
      itemBuilder: (context, index) => Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: _buildResultTile(_resultados[index]),
      ),
    );
  }

  Widget _buildResultTile(RegistroPlantilla item) {
    final infoGenero = _obtenerInfoGenero(item.curp);
    return ListTile(
      leading: CircleAvatar(
        radius: 15,
        backgroundColor: infoGenero['color'],
        child: Icon(infoGenero['icono'], color: Colors.white, size: 16),
      ),
      title: Text(
        item.nombre ?? "",
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        "QNA: ${item.qna} | AÑO: ${item.anio} | RFC: ${item.rfc}",
        style: const TextStyle(fontSize: 11),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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