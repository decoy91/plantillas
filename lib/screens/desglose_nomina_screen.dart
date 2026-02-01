//lib/screens/desglose_nomina_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/registro_model.dart';

class DesgloseNominaScreen extends StatelessWidget {
  final RegistroPlantilla registro;

  const DesgloseNominaScreen({super.key, required this.registro});

  // --- FUNCIÓN PARA COPIAR AL PORTAPAPELES ---
  void _copiarAlPortapapeles(BuildContext context, List<MapEntry<String, double>> per, List<MapEntry<String, double>> ded) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    String texto = "📄 *DESGLOSE DE NÓMINA*\n";
    texto += "👤 ${registro.nombre}\n";
    texto += "📅 QNA: ${registro.qna} | AÑO: ${registro.anio}\n\n";

    texto += "✅ *PERCEPCIONES (${fmt.format(registro.per)}):*\n";
    for (var e in per) {
      texto += "• ${e.key}: ${fmt.format(e.value)}\n";
    }

    texto += "\n❌ *DEDUCCIONES (${fmt.format(registro.ded)}):*\n";
    for (var e in ded) {
      texto += "• ${e.key}: ${fmt.format(e.value)}\n";
    }

    texto += "\n💰 *LÍQUIDO: ${fmt.format(registro.per - registro.ded)}*";

    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copiado al portapapeles")),
    );
  }

  // --- FUNCIÓN PARA GENERAR PDF CON MARCA DE AGUA ---
  // --- FUNCIÓN PARA GENERAR PDF CORREGIDA (SOPORTA VARIAS PÁGINAS) ---
  Future<void> _exportarPDF(List<MapEntry<String, double>> per, List<MapEntry<String, double>> ded) async {
    final pdf = pw.Document();
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    // Calculamos el total de filas para decidir el tamaño de la fuente
    // Si hay más de 25 conceptos en total, reducimos la letra para que quepa en una hoja
    final totalFilas = per.length + ded.length;
    final double fontSizeCuerpo = totalFilas > 25 ? 7.0 : 9.0;
    final double fontSizeHeaders = totalFilas > 25 ? 8.0 : 10.0;
    final double spacing = totalFilas > 25 ? 2.0 : 10.0;

    pdf.addPage(
      pw.Page( // Cambiamos MultiPage por Page para forzar una sola hoja
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(25),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // MARCA DE AGUA AL FONDO
              pw.Center(
                child: pw.Opacity(
                  opacity: 0.07,
                  child: pw.Transform.rotate(
                    angle: 0.5,
                    child: pw.Text(
                      "DOCUMENTO INFORMATIVO",
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: 50, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
              ),
              // CONTENIDO
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(color: PdfColors.indigo),
                    child: pw.Center(
                      child: pw.Text("RECIBO DE DESGLOSE DE CONCEPTOS", 
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ),
                  ),
                  pw.SizedBox(height: spacing),
                  
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("NOMBRE: ${registro.nombre}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.Text("RFC: ${registro.rfc}", style: const pw.TextStyle(fontSize: 9)),
                        ]
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("QNA: ${registro.qna} | AÑO: ${registro.anio}", style: const pw.TextStyle(fontSize: 9)),
                          pw.Text("LIQUIDO: ${fmt.format(registro.per - registro.ded)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.indigo)),
                        ]
                      ),
                    ]
                  ),
                  pw.SizedBox(height: spacing),

                  // TABLA PERCEPCIONES
                  pw.Text("PERCEPCIONES", style: pw.TextStyle(color: PdfColors.green, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.TableHelper.fromTextArray(
                    cellStyle: pw.TextStyle(fontSize: fontSizeCuerpo),
                    headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: fontSizeHeaders),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
                    cellHeight: 12,
                    headers: ['CONCEPTO', 'IMPORTE'],
                    data: per.map((e) => [e.key, fmt.format(e.value)]).toList(),
                  ),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text("TOTAL PER: ${fmt.format(registro.per)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSizeCuerpo)),
                  ),

                  pw.SizedBox(height: spacing),

                  // TABLA DEDUCCIONES
                  pw.Text("DEDUCCIONES", style: pw.TextStyle(color: PdfColors.red, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.TableHelper.fromTextArray(
                    cellStyle: pw.TextStyle(fontSize: fontSizeCuerpo),
                    headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: fontSizeHeaders),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.red),
                    cellHeight: 12,
                    headers: ['CONCEPTO', 'IMPORTE'],
                    data: ded.map((e) => [e.key, fmt.format(e.value)]).toList(),
                  ),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text("TOTAL DED: ${fmt.format(registro.ded)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSizeCuerpo)),
                  ),

                  pw.Spacer(), // Empuja el total al final de la hoja
                  pw.Divider(color: PdfColors.indigo, thickness: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("ESTE DOCUMENTO ES DE CARÁCTER INFORMATIVO", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey)),
                      pw.Text("NETO A PAGAR: ${fmt.format(registro.per - registro.ded)}", 
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
                    ]
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Desglose_${registro.rfc}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final percepciones = registro.desglose.entries
        .where((e) => e.key.startsWith('P') && e.key != 'PER' && e.key != 'PERIODICIDAD' && e.key != 'PER_GRAVADA')
        .toList();

    final deducciones = registro.desglose.entries
        .where((e) => e.key.startsWith('D') && e.key != 'DED' && e.key != 'DEL')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Desglose de Conceptos"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            onPressed: () => _copiarAlPortapapeles(context, percepciones, deducciones),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () => _exportarPDF(percepciones, deducciones),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBannerInfo(fmt),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCardGrupo("PERCEPCIONES", percepciones, Colors.green, registro.per),
                const SizedBox(height: 16),
                _buildCardGrupo("DEDUCCIONES", deducciones, Colors.red, registro.ded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerInfo(NumberFormat fmt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.indigo.shade50,
      child: Column(
        children: [
          Text(registro.nombre ?? "", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text("QNA: ${registro.qna} | AÑO: ${registro.anio}", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("LÍQUIDO: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(fmt.format(registro.per - registro.ded), style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrupo(String titulo, List<MapEntry<String, double>> items, Color color, double montoTotal) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            width: double.infinity,
            decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text(fmt.format(montoTotal), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Text("No hay conceptos con valor registrados"))
          else
            ...items.map((e) => Column(
              children: [
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  trailing: Text(fmt.format(e.value), style: TextStyle(color: color.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1, indent: 15, endIndent: 15),
              ],
            )),
        ],
      ),
    );
  }
}