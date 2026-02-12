import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:intl/intl.dart';
import 'package:plantilla/screens/desglose_nomina_screen.dart';
import 'package:plantilla/services/pdf_service.dart';
import 'package:share_plus/share_plus.dart'; 
import '../models/registro_model.dart';

class DetalleRegistroScreen extends StatelessWidget {
  final RegistroPlantilla registro;
  final dynamic permisos; 

  const DetalleRegistroScreen({super.key, required this.registro, required this.permisos});

  // --- MAPA DE BITS ---
  static const int bitNumEmp = 1;
  static const int bitRfc = 2;
  static const int bitCurp = 4;
  static const int bitNombre = 8;
  static const int bitUr = 16;
  static const int bitTipoPers = 32;
  static const int bitProg = 64;
  static const int bitFf = 128;
  static const int bitNoFuente = 256;
  static const int bitCodigo = 512;
  static const int bitPuesto = 1024;
  static const int bitRama = 2048;
  static const int bitClavePres = 4096;
  static const int bitZe = 8192;
  static const int bitFigf = 16384;
  static const int bitFissa = 32768;
  static const int bitFreing = 65536;
  static const int bitPer = 131072;
  static const int bitDed = 262144;
  static const int bitNeto = 524288;
  static const int bitBanco = 1048576;
  static const int bitNumCta = 2097152;
  static const int bitClabe = 4194304;
  static const int bitCr = 8388608;
  static const int bitClues = 16777216;
  static const int bitDesClues = 33554432;
  static const int bitQna = 67108864;
  static const int bitAnio = 134217728;
  static const int bitTipoT1 = 268435456;
  static const int bitTipoT2 = 536870912;
  static const int bitNivel = 1073741824;
  static const int bitHoras = 2147483648;
  static const int bitNumCheq = 4294967296;

  // --- FUNCIÓN DE PERMISOS COMPATIBLE CON WEB (BigInt) ---
  bool _tienePermiso(int bitRequerido) {
    final BigInt mascaraActual = BigInt.tryParse(permisos.toString()) ?? BigInt.zero;
    final BigInt bitReq = BigInt.from(bitRequerido);
    return (mascaraActual & bitReq) != BigInt.zero;
  }

  String _dato(int bitRequerido, String? valorReal) {
    return _tienePermiso(bitRequerido) ? (valorReal ?? "N/A") : "**********";
  }

  // --- FUNCIÓN PARA COPIAR AL PORTAPAPELES ---
  void _copiarTexto(BuildContext context, String titulo, String contenido) {
    Clipboard.setData(ClipboardData(text: contenido)).then((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Copiado: $titulo"),
          backgroundColor: Colors.indigo,
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  void _copiarSeccion(BuildContext context, String titulo, List<Widget> children) {
    String textoACopiar = "*$titulo*\n";
    for (var widget in children) {
      if (widget is Padding) {
        try {
          final row = widget.child as Row;
          final label = (row.children[0] as Expanded).child as Text;
          final value = (row.children[1] as Expanded).child as Text;
          textoACopiar += "${label.data}: ${value.data}\n";
        } catch (_) {}
      }
    }
    _copiarTexto(context, titulo, textoACopiar);
  }

  Map<String, dynamic> _obtenerInfoGenero() {
    if (registro.curp != null && registro.curp!.length >= 11) {
      String generoChar = registro.curp![10].toUpperCase(); 
      if (generoChar == 'H') return {'icono': Icons.male, 'color': Colors.blue.shade700};
      if (generoChar == 'M') return {'icono': Icons.female, 'color': Colors.pink.shade400};
    }
    return {'icono': Icons.person, 'color': Colors.indigo};
  }

  void _compartirPDF(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final XFile archivoPdf = await PdfService.prepararArchivoPDF(registro);
      await SharePlus.instance.share(
        ShareParams(
          text: 'Envío de PDF de Plantilla: ${registro.rfc}',
          subject: 'Expediente Digital - ${registro.rfc}',
          files: [archivoPdf],
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error al compartir PDF: $e")));
    }
  }

  void _compartirDatos() {
    final formatter = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final String message = '''
📋 *DATOS DE PLANTILLA*
👤 *Nombre:* ${_dato(bitNombre, registro.nombre)} (${_dato(bitUr, registro.ur)})
🆔 *RFC:* ${_dato(bitRfc, registro.rfc)}
💳 *CURP:* ${_dato(bitCurp, registro.curp)}
🏢 *Puesto:* ${_dato(bitCodigo, registro.codigo)} / ${_dato(bitPuesto, registro.puesto)}
📍 *CLUES:* ${_dato(bitClues, registro.clues)} - ${_dato(bitDesClues, registro.desClues)}
⭐ *FF:* ${_dato(bitFf, registro.ff)}
📅 *QNA/AÑO:* ${_dato(bitQna, registro.qna)}/${_dato(bitAnio, registro.anio)}

💰 *DETALLE ECONÓMICO*
🏦 Banco: ${_dato(bitBanco, _obtenerNombreBanco(registro.banco))}
#️⃣ Cuenta: ${_dato(bitNumCta, registro.numCta)}
#️⃣ CLABE: ${_dato(bitClabe, registro.clabe)}
💲 Percepciones: ${_dato(bitPer, formatter.format(registro.per))}
💸 Deducciones: ${_dato(bitDed, formatter.format(registro.ded))}
💳 Neto: ${_dato(bitNeto, formatter.format(registro.neto))}
''';
    SharePlus.instance.share(ShareParams(text: message));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detalle (${registro.qna}/${registro.anio})"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Compartir PDF",
            onPressed: () => _compartirPDF(context),
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: _compartirDatos),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 15),
                  // Se aplica BigInt también aquí para la visibilidad de la tarjeta financiera
                  if (_tienePermiso(bitPer) || _tienePermiso(bitDed) || _tienePermiso(bitNeto)) 
                    _buildFinancialCard(context),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    if (registro.pensiones.isNotEmpty)
                      _buildPensionSection(context),

                    _buildSection(
                      context,
                      "Datos Personales",
                      Icons.badge_outlined,
                      [
                        _buildRow("RFC", _dato(bitRfc, registro.rfc)),
                        _buildRow("CURP", _dato(bitCurp, registro.curp)),
                        _buildRow("# Empleado", _dato(bitNumEmp, registro.numEmp)),
                      ],
                    ),
                    _buildSection(
                      context,
                      "Datos Laborales",
                      Icons.work_outline,
                      [
                        _buildInfoTile("QNA / Año", "${registro.qna} / ${registro.anio}"),
                        _buildInfoTile("Tipo Personal", _dato(bitTipoPers, registro.tipoPersonal)),
                        _buildInfoTile("Programa", _dato(bitProg, registro.programa)),
                        _buildInfoTile("FF", _dato(bitFf, registro.ff)),
                        _buildInfoTile("Puesto", _dato(bitPuesto, registro.puesto)),
                        _buildInfoTile("Código", _dato(bitCodigo, registro.codigo)),
                        _buildInfoTile("UR", _dato(bitUr, registro.ur)),
                        _buildInfoTile("Tipo Trab.", "${registro.tipoTrab2} (${registro.tipoTrab1})"),
                        _buildInfoTile("RAMA", _dato(bitRama, registro.rama)),
                        _buildInfoTile("CR", _dato(bitCr, registro.cr)),
                        _buildInfoTile("Clues", "${registro.clues} - ${registro.desClues}"),
                        _buildInfoTile("Clave Presup.", _dato(bitClavePres, registro.clavePresupuestal)),
                        _buildInfoTile("Z. Economica.", _dato(bitZe, registro.ze)),
                        _buildInfoTile("FIGF", _dato(bitFigf, registro.figf)),
                        _buildInfoTile("FISSA", _dato(bitFissa, registro.fissa)),
                        _buildInfoTile("FREING", _dato(bitFreing, registro.freing)),
                        _buildInfoTile("# CHEQ", _dato(bitNumCheq, registro.numCheq)),
                      ],
                    ),
                    _buildSection(
                      context,
                      "Datos Bancarios",
                      Icons.account_balance_outlined,
                      [
                        _buildInfoTile("BANCO", _dato(bitBanco, _obtenerNombreBanco(registro.banco))),
                        _buildInfoTile("# Cuenta", _dato(bitNumCta, registro.numCta)),
                        _buildInfoTile("CLAVE", _dato(bitClabe, registro.clabe)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPensionSection(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.family_restroom, color: Colors.orange, size: 20),
                  SizedBox(width: 10),
                  Text("Pensiones Alimenticias", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.orange),
                onPressed: () {
                  String texto = "*PENSIONES ALIMENTICIAS*\n";
                  for (var p in registro.pensiones) {
                    texto += "Beneficiario: ${p.nombre}\nImporte: ${fmt.format(p.importe)}\nUR: ${p.ur}/${p.qnaReal} \n---\n";
                  }
                  _copiarTexto(context, "Pensiones", texto);
                },
              ),
            ],
          ),
          const Divider(height: 25, color: Colors.orange),
          ...registro.pensiones.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Importe: ${fmt.format(p.importe)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    Text("UR: ${p.ur}/${p.qnaReal}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final infoGenero = _obtenerInfoGenero();
    return Center(
      child: Column(
        children: [
          Material(
            elevation: 5,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: CircleAvatar(
              radius: 35,
              backgroundColor: infoGenero['color'],
              child: Icon(infoGenero['icono'], size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _dato(bitNombre, registro.nombre),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DesgloseNominaScreen(registro: registro),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.indigo.shade700, Colors.indigo.shade500]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _moneyCol("PERCEPCIÓN", _tienePermiso(bitPer), registro.per, Colors.white),
                  _moneyCol("DEDUCCIÓN", _tienePermiso(bitDed), registro.ded, Colors.white),
                  _moneyCol("NETO", _tienePermiso(bitNeto), registro.neto, Colors.greenAccent, isBold: true),
                ],
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white70),
                onPressed: () {
                  String texto = "*DETALLE ECONÓMICO*\n";
                  texto += "Percepciones: ${_tienePermiso(bitPer) ? fmt.format(registro.per) : "****"}\n";
                  texto += "Deducciones: ${_tienePermiso(bitDed) ? fmt.format(registro.ded) : "****"}\n";
                  texto += "Neto: ${_tienePermiso(bitNeto) ? fmt.format(registro.neto) : "****"}";
                  _copiarTexto(context, "Montos Económicos", texto);
                },
              ),
            ),
            Positioned(
              bottom: 8,
              right: 15,
              child: Icon(Icons.touch_app, size: 14, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyCol(String label, bool tienePermiso, double val, Color color, {bool isBold = false}) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(
          tienePermiso ? fmt.format(val) : "****",
          style: TextStyle(color: color, fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.indigo, size: 20),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.indigo),
                onPressed: () => _copiarSeccion(context, title, children),
              ),
            ],
          ),
          const Divider(height: 25),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }

  String _obtenerNombreBanco(String? codigo) {
    final bancos = {
      '02': 'BANCOMER',
      '04': 'BANCOMER',
      '40012': 'BANCOMER',
      '05': 'CHEQUE',
      '18': 'BANORTE',
      '40072': 'BANORTE',
      '17': 'BANORTE',
    };
    return bancos[codigo] ?? 'DESCONOCIDO';
  }
}