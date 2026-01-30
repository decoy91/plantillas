import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:io'; // Necesario para File
import 'package:path_provider/path_provider.dart'; // Necesario para carpetas temporales
import 'package:share_plus/share_plus.dart'; // Necesario para XFile
import '../models/registro_model.dart';

class PdfService {
  
  // --- NUEVO MÉTODO PARA COMPARTIR ---
  static Future<XFile> prepararArchivoPDF(RegistroPlantilla registro) async {
    final pdf = await _crearDocumento(registro);

    // Obtener directorio temporal
    final directory = await getTemporaryDirectory();
    // Nombrar el archivo con el RFC para que sea profesional al compartir
    final nombreArchivo = "Reporte_${registro.rfc}.pdf";
    final file = File("${directory.path}/$nombreArchivo");
    
    // Escribir los bytes del PDF
    await file.writeAsBytes(await pdf.save());

    return XFile(file.path);
  }

  // --- MÉTODO ACTUAL DE IMPRESIÓN (MANTENIDO) ---
  static Future<void> generarPDF(RegistroPlantilla registro) async {
    final pdf = await _crearDocumento(registro);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // --- LÓGICA DE DISEÑO UNIFICADA (Para no repetir código) ---
  static Future<pw.Document> _crearDocumento(RegistroPlantilla registro) async {
    final pdf = pw.Document();
    final formatter = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final fechaHora = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // --- CAPA DE MARCA DE AGUA ---
              pw.Opacity(
                opacity: 0.1,
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Transform.rotate(
                    angle: -math.pi / 4,
                    child: pw.Text(
                      "DOCTO. INFORMATIVO",
                      style: pw.TextStyle(
                        fontSize: 60,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // --- CAPA DE CONTENIDO PRINCIPAL ---
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("SISTEMA DE PLANTILLA - DOSN", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text("Generado el: $fechaHora", style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Divider(),
                  pw.SizedBox(height: 10),

                  pw.Center(
                    child: pw.Text("REPORTE INDIVIDUAL DE PERSONAL", 
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text("${registro.nombre} (${registro.ur})", 
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  // pw.Text("RFC: ${registro.rfc}", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  
                  pw.SizedBox(height: 20),

                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                      border: pw.Border.all(color: PdfColors.grey300)
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _pdfMoneyCol("PERCEPCIONES", formatter.format(registro.per)),
                        _pdfMoneyCol("DEDUCCIONES", formatter.format(registro.ded)),
                        _pdfMoneyCol("LIQUIDO", formatter.format(registro.neto), isBold: true),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 25),

                  _pdfSectionTitle("DATOS PERSONALES"),
                  _pdfDataRow("RFC", registro.rfc),
                  _pdfDataRow("CURP", registro.curp),
                  _pdfDataRow("FIGF", registro.figf),
                  _pdfDataRow("FISSA", registro.fissa),
                  _pdfDataRow("FREING", registro.freing),

                  pw.SizedBox(height: 15),

                  _pdfSectionTitle("INFORMACIÓN LABORAL"),
                  _pdfDataRow("QUINCENA / AÑO", "${registro.qna} / ${registro.anio}"),
                  _pdfDataRow("CÓDIGO", "${registro.codigo} / ${registro.puesto}"),
                  _pdfDataRow("PROG./FF", "${registro.programa} / ${registro.ff}"),
                  _pdfDataRow("CLUES", "${registro.clues} - ${registro.desClues}"),
                  _pdfDataRow("CLAVE PRESUPUESTAL", registro.clavePresupuestal),
                  _pdfDataRow("ZONA ECONOMICA", registro.ze),
                  
                  
                  pw.SizedBox(height: 15),

                  _pdfSectionTitle("DATOS BANCARIOS"),
                  _pdfDataRow("BANCO", "${_obtenerNombreBanco(registro.banco)} (${registro.banco})"),
                  _pdfDataRow("CUENTA / CLABE", "${registro.numCta} / ${registro.clabe}"),
                ],
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static String _obtenerNombreBanco(String? codigo) {
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

  // --- Widgets de apoyo ---
  static pw.Widget _pdfMoneyCol(String label, String value, {bool isBold = false}) {
    return pw.Column(children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    ]);
  }

  static pw.Widget _pdfSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(4),
      decoration: const pw.BoxDecoration(color: PdfColors.indigo),
      child: pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
    );
  }

  static pw.Widget _pdfDataRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 120, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
          pw.Expanded(child: pw.Text(value ?? "N/A", style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }
}