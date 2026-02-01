//lib/models/registro_model.dart

class Pension {
  final int id;
  final String rfc;
  final String nombre;
  final String ur;
  final double importe;
  final String qnaSubida;
  final String qnaReal;
  final String anio;

  Pension({
    required this.id,
    required this.rfc,
    required this.nombre,
    required this.ur,
    required this.importe,
    required this.qnaSubida,
    required this.qnaReal,
    required this.anio,
  });

  factory Pension.fromJson(Map<String, dynamic> json) {
    return Pension(
      id: json['id'] as int,
      rfc: json['rfc']?.toString() ?? "",
      nombre: json['nombre']?.toString() ?? "",
      ur: json['ur']?.toString() ?? "",
      importe: _toDouble(json['importe']), // Cambio seguro
      qnaSubida: json['qna_subida']?.toString() ?? "",
      qnaReal: json['qnareal']?.toString() ?? "",
      anio: json['anio']?.toString() ?? "",
    );
  }
}

/// Función auxiliar para convertir cualquier tipo de dato a double de forma segura.
/// Evita el error "String is not a subtype of num".
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
  }
  return 0.0;
}

class RegistroPlantilla {
  final String? numEmp;
  final String? rfc;
  final String? curp;
  final String? nombre;
  final String? ur;
  final String? tipoPersonal;
  final String? programa;
  final String? ff;
  final String? noFuente;
  final String? codigo;
  final String? puesto;
  final String? rama;
  final String? clavePresupuestal;
  final String? ze;
  final String? figf;
  final String? fissa;
  final String? freing;
  final double per;
  final double ded;
  final double neto;
  final String? banco;
  final String? numCta;
  final String? clabe;
  final String? cr;
  final String? clues;
  final String? desClues;
  final String? qna;
  final String? anio;
  final String? tipoTrab1;
  final String? tipoTrab2;
  final String? nivel;
  final String? horas;
  final String? numCheq;
  final List<Pension> pensiones;
  final Map<String, double> desglose;

  RegistroPlantilla({
    this.numEmp, this.rfc, this.curp, this.nombre, this.ur,
    this.tipoPersonal, this.programa, this.ff, this.noFuente,
    this.codigo, this.puesto, this.rama, this.clavePresupuestal,
    this.ze, this.figf, this.fissa, this.freing,
    required this.per, required this.ded, required this.neto,
    this.banco, this.numCta, this.clabe, this.cr, this.clues,
    this.desClues, this.qna, this.anio, this.tipoTrab1,
    this.tipoTrab2, this.nivel, this.horas, this.numCheq,
    this.pensiones = const [],
    this.desglose = const {},
  });

  factory RegistroPlantilla.fromJson(Map<String, dynamic> json) {
    // Lógica para detectar dinámicamente conceptos P y D con valor > 0 de forma segura
    final Map<String, double> mapaConceptos = {};
    json.forEach((key, value) {
      if ((key.startsWith('P') || key.startsWith('D')) && value != null) {
        final double monto = _toDouble(value); // Uso de conversión segura
        if (monto > 0) {
          mapaConceptos[key] = monto;
        }
      }
    });

    return RegistroPlantilla(
      numEmp: json['NUMEMP']?.toString(),
      rfc: json['RFC']?.toString(),
      curp: json['CURP']?.toString(),
      nombre: json['NOMBRE']?.toString(),
      ur: json['UR']?.toString(),
      tipoPersonal: json['TIPO_PERSONAL']?.toString(),
      programa: json['PROGRAMA']?.toString(),
      ff: json['FF']?.toString(),
      noFuente: json['NoFUENTE']?.toString(),
      codigo: json['CODIGO']?.toString(),
      puesto: json['PUESTO']?.toString(),
      rama: json['RAMA']?.toString(),
      clavePresupuestal: json['CLAVE_PRESUPUESTAL']?.toString(),
      ze: json['ZE']?.toString(),
      figf: json['FIGF']?.toString(),
      fissa: json['FISSA']?.toString(),
      freing: json['FREING']?.toString(),
      per: _toDouble(json['PER']),
      ded: _toDouble(json['DED']),
      neto: _toDouble(json['NETO']),
      banco: json['BANCO']?.toString(),
      numCta: json['NUMCTA']?.toString(),
      clabe: json['CLABE']?.toString(),
      cr: json['CR']?.toString(),
      clues: json['CLUES']?.toString(),
      desClues: json['DES_CLUES']?.toString(),
      qna: json['QNA']?.toString(),
      anio: json['ANIO']?.toString(),
      tipoTrab1: json['TIPOTRAB1']?.toString(),
      tipoTrab2: json['TIPOTRAB2']?.toString(),
      nivel: json['NIVEL']?.toString(),
      horas: json['HORAS']?.toString(),
      numCheq: json['NUMCHEQ']?.toString(),
      pensiones: (json['pensiones'] as List?)
              ?.map((p) => Pension.fromJson(p))
              .toList() ?? [],
      desglose: mapaConceptos,
    );
  }
}