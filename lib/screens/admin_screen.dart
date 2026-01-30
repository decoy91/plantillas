import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  Key _expansionTileKey = UniqueKey();

  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _macController = TextEditingController(text: "MOVIL");
  final _tablasController = TextEditingController(text: "0"); 
  final _searchUserController = TextEditingController();
  
  final _horaInicioController = TextEditingController(text: "08:00:00");
  final _horaFinController = TextEditingController(text: "16:00:00");

  int _nivel = 2;
  bool _validarHorario = false; 
  List<dynamic> _usuariosOriginales = [];
  List<dynamic> _usuariosFiltrados = [];
  bool _isLoadingList = true;

  final List<Map<String, dynamic>> _camposBitmask = [
    {'nombre': 'NUMEMP', 'bit': 1},
    {'nombre': 'RFC', 'bit': 2},
    {'nombre': 'CURP', 'bit': 4},
    {'nombre': 'NOMBRE', 'bit': 8},
    {'nombre': 'UR', 'bit': 16},
    {'nombre': 'TIPO_PERSONAL', 'bit': 32},
    {'nombre': 'PROGRAMA', 'bit': 64},
    {'nombre': 'FF', 'bit': 128},
    {'nombre': 'NoFUENTE', 'bit': 256},
    {'nombre': 'CODIGO', 'bit': 512},
    {'nombre': 'PUESTO', 'bit': 1024},
    {'nombre': 'RAMA', 'bit': 2048},
    {'nombre': 'CLAVE_PRESUPUESTAL', 'bit': 4096},
    {'nombre': 'ZE', 'bit': 8192},
    {'nombre': 'FIGF', 'bit': 16384},
    {'nombre': 'FISSA', 'bit': 32768},
    {'nombre': 'FREING', 'bit': 65536},
    {'nombre': 'PER', 'bit': 131072},
    {'nombre': 'DED', 'bit': 262144},
    {'nombre': 'NETO', 'bit': 524288},
    {'nombre': 'BANCO', 'bit': 1048576},
    {'nombre': 'NUMCTA', 'bit': 2097152},
    {'nombre': 'CLABE', 'bit': 4194304},
    {'nombre': 'CR', 'bit': 8388608},
    {'nombre': 'CLUES', 'bit': 16777216},
    {'nombre': 'DES_CLUES', 'bit': 33554432},
    {'nombre': 'QNA', 'bit': 67108864},
    {'nombre': 'ANIO', 'bit': 134217728},
    {'nombre': 'TIPOTRAB1', 'bit': 268435456},
    {'nombre': 'TIPOTRAB2', 'bit': 536870912},
    {'nombre': 'NIVEL', 'bit': 1073741824},
    {'nombre': 'HORAS', 'bit': 2147483648},
    {'nombre': 'NUMCHEQ', 'bit': 4294967296},
  ];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
    _searchUserController.addListener(_filtrarUsuarios);
  }

  void _cargarUsuarios() async {
    setState(() => _isLoadingList = true);
    final users = await ApiService().obtenerUsuarios();
    setState(() {
      _usuariosOriginales = users.where((u) => u['user'].toString().toLowerCase() != 'alex').toList();
      _usuariosFiltrados = _usuariosOriginales;
      _isLoadingList = false;
    });
  }

  void _filtrarUsuarios() {
    String query = _searchUserController.text.toLowerCase();
    setState(() {
      _usuariosFiltrados = _usuariosOriginales.where((u) {
        final userName = u['user'].toString().toLowerCase();
        return userName.contains(query);
      }).toList();
    });
  }

  Future<void> _seleccionarHora(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.indigo),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final String horaFormateada = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00";
      setState(() {
        controller.text = horaFormateada;
      });
    }
  }

  void _mostrarSelectorPermisos(TextEditingController controller) {
    int currentMask = int.tryParse(controller.text) ?? 0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Permisos de Vista"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            currentMask = 0;
                            for (var campo in _camposBitmask) {
                              currentMask |= campo['bit'];
                            }
                            controller.text = currentMask.toString();
                          });
                        },
                        icon: const Icon(Icons.select_all),
                        label: const Text("TODO"),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            currentMask = 0;
                            controller.text = "0";
                          });
                        },
                        icon: const Icon(Icons.deselect),
                        label: const Text("NADA"),
                      ),
                    ],
                  ),
                  const Divider(),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _camposBitmask.length,
                      itemBuilder: (context, index) {
                        final campo = _camposBitmask[index];
                        bool isSelected = (currentMask & campo['bit']) != 0;
                        return CheckboxListTile(
                          title: Text(campo['nombre']),
                          value: isSelected,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val!) {
                                currentMask |= campo['bit'];
                              } else {
                                currentMask &= ~campo['bit'];
                              }
                              controller.text = currentMask.toString();
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ACEPTAR"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _compartirCredenciales(dynamic usuario, {String? passRecienCreado}) {
    final String passwordAEnviar = passRecienCreado ?? (usuario['pass']?.toString() ?? "******** (Protegido)");
    final String mensaje = '''
🔐 *CREDENCIALES DE ACCESO A LA PLANTILLA*
👤 *Usuario:* ${usuario['user']}
🔑 *Password:* $passwordAEnviar

_Por seguridad, cambie su contraseña al ingresar._
''';
    SharePlus.instance.share(ShareParams(text: mensaje));
  }

  void _crearUsuario() async {
    if (_formKey.currentState!.validate()) {
      final String passwordTemporal = _passController.text;

      final resultado = await ApiService().registrarUsuario({
        "user": _userController.text,
        "pass": passwordTemporal,
        "nivel": _nivel,
        "activo": 1,
        "direccion_mac": _macController.text,
        "tablas_autorizadas": _tablasController.text,
        "guardar_log": 1,
        "hora_inicio": _horaInicioController.text,
        "hora_fin": _horaFinController.text,
        "validar_horario": _validarHorario ? 1 : 0, 
      });

      if (!mounted) return;
      if (resultado['success'] == true) {
        _compartirCredenciales({
          "user": _userController.text,
          "direccion_mac": _macController.text,
          "nivel": _nivel,
        }, passRecienCreado: passwordTemporal);

        _userController.clear();
        _passController.clear();
        _tablasController.text = "0";
        _horaInicioController.text = "08:00:00";
        _horaFinController.text = "16:00:00";
        _validarHorario = false;
        setState(() { _expansionTileKey = UniqueKey(); });
        FocusScope.of(context).unfocus();
        _cargarUsuarios();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario registrado"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resultado['message']), backgroundColor: Colors.red));
      }
    }
  }

  void _abrirEditorUsuario(dynamic usuario) {
    final editUserCtrl = TextEditingController(text: usuario['user']);
    final editPassCtrl = TextEditingController();
    final editMacCtrl = TextEditingController(text: usuario['direccion_mac']);
    final editTablasCtrl = TextEditingController(text: usuario['tablas_autorizadas']?.toString() ?? "0");
    final editHoraInicioCtrl = TextEditingController(text: usuario['hora_inicio']?.toString() ?? "08:00:00");
    final editHoraFinCtrl = TextEditingController(text: usuario['hora_fin']?.toString() ?? "16:00:00");
    int editNivel = int.tryParse(usuario['nivel'].toString()) ?? 2;
    bool editValidarHorario = (usuario['validar_horario'].toString() == "1");

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [Icon(Icons.edit, color: Colors.indigo), SizedBox(width: 10), Text("Editar Usuario")],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  TextField(controller: editUserCtrl, decoration: const InputDecoration(labelText: "Usuario", prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 15),
                  TextField(controller: editPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Password (Vacío para no cambiar)", prefixIcon: Icon(Icons.lock))),
                  const SizedBox(height: 15),
                  TextField(controller: editMacCtrl, decoration: const InputDecoration(labelText: "Dirección MAC", prefixIcon: Icon(Icons.settings_input_antenna))),
                  const SizedBox(height: 15),
                  TextField(
                    controller: editTablasCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Bitmask de Permisos",
                      prefixIcon: const Icon(Icons.security),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () => _mostrarSelectorPermisos(editTablasCtrl),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SwitchListTile(
                    title: const Text("Validar Horario", style: TextStyle(fontSize: 14)),
                    value: editValidarHorario,
                    onChanged: (val) {
                      setDialogState(() => editValidarHorario = val);
                    },
                  ),
                  Opacity(
                    opacity: editValidarHorario ? 1.0 : 0.5,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: editHoraInicioCtrl,
                            readOnly: true,
                            enabled: editValidarHorario,
                            decoration: const InputDecoration(labelText: "Inicio", prefixIcon: Icon(Icons.access_time)),
                            onTap: () async {
                              await _seleccionarHora(context, editHoraInicioCtrl);
                              setDialogState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: editHoraFinCtrl,
                            readOnly: true,
                            enabled: editValidarHorario,
                            decoration: const InputDecoration(labelText: "Fin", prefixIcon: Icon(Icons.access_time_filled)),
                            onTap: () async {
                              await _seleccionarHora(context, editHoraFinCtrl);
                              setDialogState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<int>(
                    initialValue: editNivel,
                    decoration: const InputDecoration(labelText: "Nivel", prefixIcon: Icon(Icons.security)),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text("Administrador")),
                      DropdownMenuItem(value: 2, child: Text("Consulta")),
                    ],
                    onChanged: (v) => setDialogState(() => editNivel = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("ACTUALIZAR"),
              style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                
                final data = {
                  "id": usuario['id'],
                  "user": editUserCtrl.text,
                  "pass_word": editPassCtrl.text,
                  "nivel": editNivel,
                  "direccion_mac": editMacCtrl.text,
                  "tablas_autorizadas": editTablasCtrl.text,
                  "hora_inicio": editHoraInicioCtrl.text,
                  "hora_fin": editHoraFinCtrl.text,
                  "validar_horario": editValidarHorario ? 1 : 0,
                };

                final success = await ApiService().editarUsuario(data);
                
                if (!mounted) return;
                if (success) {
                  navigator.pop();
                  _cargarUsuarios();
                  messenger.showSnackBar(const SnackBar(content: Text("Actualizado con éxito")));
                } else {
                  messenger.showSnackBar(const SnackBar(content: Text("Error al actualizar"), backgroundColor: Colors.red));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleUsuario(dynamic id, dynamic estadoActual) async {
    int valorActual = int.tryParse(estadoActual.toString()) ?? 0;
    int nuevoEstado = valorActual == 1 ? 0 : 1;
    final res = await ApiService().actualizarEstadoUsuario(int.parse(id.toString()), nuevoEstado);
    if (res) _cargarUsuarios();
  }

  void _confirmarEliminacion(dynamic id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar"),
        content: Text("¿Borrar a $nombre?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("NO")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (await ApiService().eliminarUsuario(int.parse(id.toString()))) _cargarUsuarios();
            },
            child: const Text("SÍ", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text("Gestión de Usuarios"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(8.0),
                    elevation: 3,
                    // --- CORRECCIÓN 1: Quitar líneas negras del ExpansionTile ---
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        key: _expansionTileKey,
                        leading: const Icon(Icons.person_add, color: Colors.indigo),
                        title: const Text("Registrar Nuevo Usuario", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            // --- CORRECCIÓN 2: Limitar altura y asegurar scroll si el teclado sube ---
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(controller: _userController, decoration: const InputDecoration(labelText: "Usuario", prefixIcon: Icon(Icons.account_circle))),
                                  const SizedBox(height: 10),
                                  TextFormField(controller: _passController, decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock)), obscureText: true),
                                  const SizedBox(height: 10),
                                  TextFormField(controller: _macController, decoration: const InputDecoration(labelText: "Dirección MAC", prefixIcon: Icon(Icons.settings_input_antenna))),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _tablasController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: "Configurar Permisos (Bitmask)",
                                      prefixIcon: const Icon(Icons.security),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.settings),
                                        onPressed: () => _mostrarSelectorPermisos(_tablasController),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text("¿Restringir por horario?", style: TextStyle(fontSize: 14)),
                                    activeThumbColor: Colors.indigo,
                                    value: _validarHorario,
                                    onChanged: (val) => setState(() => _validarHorario = val),
                                  ),
                                  if (_validarHorario)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _horaInicioController,
                                            readOnly: true,
                                            decoration: const InputDecoration(labelText: "Hora Inicio", prefixIcon: Icon(Icons.access_time), contentPadding: EdgeInsets.symmetric(vertical: 8)),
                                            onTap: () => _seleccionarHora(context, _horaInicioController),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _horaFinController,
                                            readOnly: true,
                                            decoration: const InputDecoration(labelText: "Hora Fin", prefixIcon: Icon(Icons.access_time_filled), contentPadding: EdgeInsets.symmetric(vertical: 8)),
                                            onTap: () => _seleccionarHora(context, _horaFinController),
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<int>(
                                    initialValue: _nivel,
                                    items: const [DropdownMenuItem(value: 1, child: Text("Admin")), DropdownMenuItem(value: 2, child: Text("Consulta"))],
                                    onChanged: (v) => setState(() => _nivel = v!),
                                    decoration: const InputDecoration(labelText: "Nivel", prefixIcon: Icon(Icons.security)),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _crearUsuario,
                                      icon: const Icon(Icons.save),
                                      label: const Text("GUARDAR USUARIO"),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: TextField(
                      controller: _searchUserController,
                      decoration: InputDecoration(
                        hintText: "Buscar usuario...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchUserController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchUserController.clear()) : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                  ),
                  _isLoadingList
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _usuariosFiltrados.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final u = _usuariosFiltrados[i];
                            bool isTimeRestricted = (u['validar_horario'].toString() == "1");
                            return ListTile(
                              onTap: () => _abrirEditorUsuario(u),
                              leading: CircleAvatar(
                                backgroundColor: u['nivel'].toString() == "1" ? Colors.amber.shade800 : Colors.indigo.shade300,
                                child: Icon(u['nivel'].toString() == "1" ? Icons.star : Icons.person, color: Colors.white, size: 20),
                              ),
                              title: Text(u['user'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(isTimeRestricted 
                                ? "Horario: ${u['hora_inicio']} - ${u['hora_fin']}"
                                : "Acceso libre 24/7"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.share, color: Colors.green), onPressed: () => _compartirCredenciales(u)),
                                  Switch(value: u['activo'].toString() == "1", onChanged: (val) => _toggleUsuario(u['id'], u['activo'])),
                                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmarEliminacion(u['id'], u['user'])),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchUserController.dispose();
    _userController.dispose();
    _passController.dispose();
    _macController.dispose();
    _tablasController.dispose();
    _horaInicioController.dispose();
    _horaFinController.dispose();
    super.dispose();
  }
}