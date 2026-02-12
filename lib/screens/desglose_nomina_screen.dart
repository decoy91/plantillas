import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Importante para kIsWeb
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart'; 
import 'package:pdf/widgets.dart' as pw; 
import 'package:printing/printing.dart'; 
import '../models/registro_model.dart';

class DesgloseNominaScreen extends StatelessWidget {
  final RegistroPlantilla registro;

  const DesgloseNominaScreen({super.key, required this.registro});

  // --- FUNCIÓN PARA GENERAR Y COMPARTIR PDF ---
  Future<void> _exportarPDF() async {
    final pdf = pw.Document();
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    final perOrd = _filtrarConceptos(registro.desgloseOrdinario, 'P');
    final dedOrd = _filtrarConceptos(registro.desgloseOrdinario, 'D');

    int totalItems = perOrd.length + dedOrd.length;
    for (var extra in registro.desglosesExtras) {
      totalItems += _filtrarConceptos(extra['conceptos'], 'P').length;
      totalItems += _filtrarConceptos(extra['conceptos'], 'D').length;
    }
    double fontSize = totalItems > 25 ? 7.0 : 9.0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Stack(
            alignment: pw.Alignment.center, 
            children: [
              pw.Center(
                child: pw.Opacity(
                  opacity: 0.07, 
                  child: pw.Transform.rotate(
                    angle: 0.5,
                    child: pw.Text(
                      "DOCUMENTO INFORMATIVO",
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 50, 
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(color: PdfColors.indigo),
                    child: pw.Center(
                        child: pw.Text("DESGLOSE DE CONCEPTOS DE NÓMINA",
                            style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text("NOMBRE: ${registro.nombre}  |  RFC: ${registro.rfc}", 
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text("QNA: ${registro.qna} | AÑO: ${registro.anio}", style: const pw.TextStyle(fontSize: 8)),
                  ]),
                  pw.Divider(color: PdfColors.grey),
                  
                  pw.SizedBox(height: 5),
                  pw.Text("PAGOS ORDINARIOS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.indigo, fontSize: 9)),
                  
                  _buildTablaPDF("PERCEPCIONES", perOrd, PdfColors.green, fontSize, fmt, registro.per),
                  _buildTablaPDF("DEDUCCIONES", dedOrd, PdfColors.red, fontSize, fmt, registro.ded),

                  if (registro.desglosesExtras.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text("PAGOS EXTRAORDINARIOS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange, fontSize: 9)),
                    ...registro.desglosesExtras.map((extra) {
                      final pEx = _filtrarConceptos(extra['conceptos'], 'P');
                      final dEx = _filtrarConceptos(extra['conceptos'], 'D');
                      return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
                            child: pw.Text("Quincena Extra: ${extra['qna_label']}", style: const pw.TextStyle(fontSize: 7, color: PdfColors.orange))),
                        _buildTablaPDF("PERCEPCIONES EXTRA", pEx, PdfColors.orange, fontSize, fmt, (extra['per'] as num).toDouble()),
                        _buildTablaPDF("DEDUCCIONES EXTRA", dEx, PdfColors.blueGrey, fontSize, fmt, (extra['ded'] as num).toDouble()),
                      ]);
                    }),
                  ],
                  pw.Spacer(),
                  pw.Divider(thickness: 1.5, color: PdfColors.indigo),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Desglose_${registro.rfc}.pdf');
  }

  pw.Widget _buildTablaPDF(String titulo, List<MapEntry<String, double>> items, PdfColor color, double fontSize, NumberFormat fmt, double montoTotal) {
    if (items.isEmpty) return pw.SizedBox();
    return pw.Column(children: [
      pw.Container(
        width: double.infinity,
        color: color,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(titulo, style: pw.TextStyle(color: PdfColors.white, fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold)),
            pw.Text(fmt.format(montoTotal), style: pw.TextStyle(color: PdfColors.white, fontSize: fontSize - 1, fontWeight: pw.FontWeight.bold)),
          ]
        ),
      ),
      pw.TableHelper.fromTextArray(
        cellStyle: pw.TextStyle(fontSize: fontSize),
        headerStyle: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
        cellHeight: 12,
        headers: ['CONCEPTO', 'IMPORTE'],
        data: items.map((e) => [e.key, fmt.format(e.value)]).toList(),
      ),
      pw.SizedBox(height: 5),
    ]);
  }

  double _getNetoTotal() {
    double total = registro.neto;
    for (var extra in registro.desglosesExtras) {
      total += (extra['neto'] as num).toDouble();
    }
    return total;
  }

  List<MapEntry<String, double>> _filtrarConceptos(Map<String, dynamic>? mapa, String prefijo) {
    final List<MapEntry<String, double>> listaCorregida = [];
    if (mapa == null) return listaCorregida;

    mapa.forEach((key, value) {
      final String llave = key.toString();
      if (llave.startsWith(prefijo) &&
          !['PER', 'PER_GRAVADA', 'PROGRAMA', 'PER_NOGRAVA', 'PERIODICIDAD', 'PUESTO', 'DED', 'DEL', 'NETO', 'LIQUIDO'].contains(llave)) {
        double monto = 0.0;
        try {
          if (value is num) {
            monto = value.toDouble();
          } else if (value is String) {
            monto = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          }
        } catch (e) { monto = 0.0; }
        if (monto > 0) listaCorregida.add(MapEntry(llave, monto));
      }
    });
    return listaCorregida;
  }

  void _copiarAlPortapapeles(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    String texto = "📄 *DESGLOSE DE NÓMINA*\n";
    texto += "👤 *${registro.nombre}*\n";
    texto += "🆔 RFC: ${registro.rfc}\n";
    texto += "📅 QNA: ${registro.qna} | AÑO: ${registro.anio}\n";
    texto += "----------------------------------\n\n";

    texto += "🔹 *PAGOS ORDINARIOS*\n";
    final perOrd = _filtrarConceptos(registro.desgloseOrdinario, 'P');
    final dedOrd = _filtrarConceptos(registro.desgloseOrdinario, 'D');

    if (perOrd.isNotEmpty) {
      texto += "_Percepciones:_\n";
      for (var e in perOrd) {
        texto += "• ${e.key}: ${fmt.format(e.value)}\n";
      }
      texto += "*Total Per:* ${fmt.format(registro.per)}\n";
    }

    if (dedOrd.isNotEmpty) {
      texto += "\n_Deducciones:_\n";
      for (var e in dedOrd) {
        texto += "• ${e.key}: ${fmt.format(e.value)}\n";
      }
      texto += "*Total Ded:* ${fmt.format(registro.ded)}\n";
    }
    texto += "*Neto Ordinario:* ${fmt.format(registro.per - registro.ded)}\n\n";

    if (registro.desglosesExtras.isNotEmpty) {
      texto += "----------------------------------\n";
      texto += "🔸 *PAGOS EXTRAORDINARIOS*\n";
      for (var extra in registro.desglosesExtras) {
        texto += "\n📌 *Concepto: ${extra['qna_label']}*\n";
        final perEx = _filtrarConceptos(extra['conceptos'], 'P');
        final dedEx = _filtrarConceptos(extra['conceptos'], 'D');
        if (perEx.isNotEmpty) {
          for (var e in perEx) { texto += "  • ${e.key}: ${fmt.format(e.value)}\n"; }
        }
        if (dedEx.isNotEmpty) {
          for (var e in dedEx) { texto += "  • ${e.key}: ${fmt.format(e.value)}\n"; }
        }
        texto += "  *Subtotal Extra:* ${fmt.format((extra['per'] ?? 0) - (extra['ded'] ?? 0))}\n";
      }
    }
    texto += "\n========================\n";
    texto += "💰 *LÍQUIDO TOTAL: ${fmt.format(_getNetoTotal())}*";

    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Desglose completo copiado al portapapeles"),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final perOrdinarias = _filtrarConceptos(registro.desgloseOrdinario, 'P');
    final dedOrdinarias = _filtrarConceptos(registro.desgloseOrdinario, 'D');
    final double maxContentWidth = kIsWeb ? 850 : double.infinity;

    return 
    SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Desglose de Nómina"),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: "Exportar PDF",
              onPressed: () => _exportarPDF(),
            ),
            IconButton(
              icon: const Icon(Icons.copy_all_rounded),
              onPressed: () => _copiarAlPortapapeles(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBannerInfo(fmt),
                  const SizedBox(height: 20),
                  const _HeaderSeccion(titulo: "PAGOS ORDINARIOS", icono: Icons.account_balance_wallet),
                  _buildCardGrupo("PERCEPCIONES", perOrdinarias, Colors.green, registro.per),
                  _buildCardGrupo("DEDUCCIONES", dedOrdinarias, Colors.red, registro.ded),
                  if (registro.desglosesExtras.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: _HeaderSeccion(titulo: "PAGOS EXTRAORDINARIOS", icono: Icons.stars, color: Colors.orange),
                    ),
                    ...registro.desglosesExtras.map((extra) {
                      final perExtras = _filtrarConceptos(extra['conceptos'], 'P');
                      final dedExtras = _filtrarConceptos(extra['conceptos'], 'D');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 8),
                            child: Text("Concepto: ${extra['qna_label']}",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          ),
                          _buildCardGrupo("PERCEPCIONES EXTRA", perExtras, Colors.orange, (extra['per'] as num).toDouble()),
                          _buildCardGrupo("DEDUCCIONES EXTRA", dedExtras, Colors.blueGrey, (extra['ded'] as num).toDouble()),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerInfo(NumberFormat fmt) {
    //double totalNetoTodo = _getNetoTotal();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.indigo.shade100)),
      child: Column(
        children: [
          Text(registro.nombre ?? "", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: kIsWeb ? 25 : 16)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("QNA: ${registro.qna}", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: kIsWeb ? 23 : null)),
              Text("AÑO: ${registro.anio}", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: kIsWeb ? 23 : null)),
            ],
          ),
          const Divider(),
          Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _moneyCol("PERCEPCIÓN", registro.per, Colors.indigo, isBold: kIsWeb ? true : false),
                  _moneyCol("DEDUCCIÓN", registro.ded, Colors.indigo, isBold: kIsWeb ? true : false),
                  _moneyCol("LIQUIDO", registro.neto, Colors.indigo, isBold: true),
                ],
              ),
        ],
      ),
    );
  }
Widget _moneyCol(String label, double val, Color color, {bool isBold = false}) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: kIsWeb ? 20 : 10, fontWeight: FontWeight.bold)),
        Text(
          fmt.format(val),
          style: TextStyle(color: color, fontSize: isBold ? 20 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }
  Widget _buildCardGrupo(String titulo, List<MapEntry<String, double>> items, Color color, double montoTotal) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            width: double.infinity,
            decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(fmt.format(montoTotal), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ...items.map((e) => ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                title: Text(e.key, style: const TextStyle(fontSize: kIsWeb ? 18 : 13)),
                trailing: Text(fmt.format(e.value), style: TextStyle(fontSize: kIsWeb ? 18 : 13, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.bold)),
              )),
        ],
      ),
    );
  }
}

class _HeaderSeccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  const _HeaderSeccion({required this.titulo, required this.icono, this.color = Colors.indigo});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icono, color: color, size: 20),
      const SizedBox(width: 8),
      Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
      const Expanded(child: Divider(indent: 10)),
    ]);
  }
}