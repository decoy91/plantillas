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
      rfc: json['rfc'] ?? "",
      nombre: json['nombre'] ?? "",
      ur: json['ur'] ?? "",
      importe: (json['importe'] as num?)?.toDouble() ?? 0.0,
      qnaSubida: json['qna_subida'] ?? "",
      qnaReal: json['qnareal'] ?? "",
      anio: json['anio'] ?? "",
    );
  }
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
  // --- NUEVO CAMPO PARA PENSIONES ---
  final List<Pension> pensiones;

  RegistroPlantilla({
    this.numEmp, this.rfc, this.curp, this.nombre, this.ur,
    this.tipoPersonal, this.programa, this.ff, this.noFuente,
    this.codigo, this.puesto, this.rama, this.clavePresupuestal,
    this.ze, this.figf, this.fissa, this.freing,
    required this.per, required this.ded, required this.neto,
    this.banco, this.numCta, this.clabe, this.cr, this.clues,
    this.desClues, this.qna, this.anio, this.tipoTrab1,
    this.tipoTrab2, this.nivel, this.horas, this.numCheq,
    this.pensiones = const [], // Valor por defecto lista vacía
  });

  factory RegistroPlantilla.fromJson(Map<String, dynamic> json) {
    return RegistroPlantilla(
      numEmp: json['NUMEMP'],
      rfc: json['RFC'],
      curp: json['CURP'],
      nombre: json['NOMBRE'],
      ur: json['UR'],
      tipoPersonal: json['TIPO_PERSONAL'],
      programa: json['PROGRAMA'],
      ff: json['FF'],
      noFuente: json['NoFUENTE'],
      codigo: json['CODIGO'],
      puesto: json['PUESTO'],
      rama: json['RAMA'],
      clavePresupuestal: json['CLAVE_PRESUPUESTAL'],
      ze: json['ZE'],
      figf: json['FIGF'],
      fissa: json['FISSA'],
      freing: json['FREING'],
      per: (json['PER'] as num?)?.toDouble() ?? 0.0,
      ded: (json['DED'] as num?)?.toDouble() ?? 0.0,
      neto: (json['NETO'] as num?)?.toDouble() ?? 0.0,
      banco: json['BANCO'],
      numCta: json['NUMCTA'],
      clabe: json['CLABE'],
      cr: json['CR'],
      clues: json['CLUES'],
      desClues: json['DES_CLUES'],
      qna: json['QNA'],
      anio: json['ANIO'],
      tipoTrab1: json['TIPOTRAB1'],
      tipoTrab2: json['TIPOTRAB2'],
      nivel: json['NIVEL'],
      horas: json['HORAS'],
      numCheq: json['NUMCHEQ'],
      // --- MAPEO DE LA LISTA DE PENSIONES ---
      pensiones: (json['pensiones'] as List?)
              ?.map((p) => Pension.fromJson(p))
              .toList() ?? [],
    );
  }
}