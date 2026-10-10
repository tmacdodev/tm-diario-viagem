import 'package:cloud_firestore/cloud_firestore.dart';

// Os três possíveis status de uma viagem, calculados a partir das datas
// de ida e volta comparadas com a data de hoje.
enum StatusViagem { proxima, emAndamento, concluida }

// Representa uma viagem cadastrada pelo usuário, com os dados preenchidos
// manualmente e os dados de localização vindos da geocodificação (Open-Meteo).
class Viagem {
  final String? id;
  final String destino;
  final String pais;
  final double latitude;
  final double longitude;
  final DateTime dataIda;
  final DateTime dataVolta;
  final double orcamentoDolares;
  final String anotacoes;
  final DateTime criadoEm;
  // Foto de capa da viagem, guardada como base64 direto no documento
  // (sem usar Firebase Storage, para manter a configuração do projeto simples).
  final String? fotoBase64;

  Viagem({
    this.id,
    required this.destino,
    required this.pais,
    required this.latitude,
    required this.longitude,
    required this.dataIda,
    required this.dataVolta,
    required this.orcamentoDolares,
    required this.anotacoes,
    required this.criadoEm,
    this.fotoBase64,
  });

  // Quantos dias faltam para a data de ida .
  int get diasParaIda {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    return dataIda.difference(hojeSemHora).inDays;
  }

  // Status calculado comparando as datas salvas com o dia de hoje.
  StatusViagem get status {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    if (hojeSemHora.isBefore(dataIda)) return StatusViagem.proxima;
    if (hojeSemHora.isAfter(dataVolta)) return StatusViagem.concluida;
    return StatusViagem.emAndamento;
  }

  Map<String, dynamic> toMap() {
    return {
      'destino': destino,
      'pais': pais,
      'latitude': latitude,
      'longitude': longitude,
      'dataIda': Timestamp.fromDate(dataIda),
      'dataVolta': Timestamp.fromDate(dataVolta),
      'orcamentoDolares': orcamentoDolares,
      'anotacoes': anotacoes,
      'criadoEm': Timestamp.fromDate(criadoEm),
      'fotoBase64': fotoBase64,
    };
  }

  factory Viagem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final dados = doc.data()!;
    return Viagem(
      id: doc.id,
      destino: dados['destino'] as String,
      pais: dados['pais'] as String,
      latitude: (dados['latitude'] as num).toDouble(),
      longitude: (dados['longitude'] as num).toDouble(),
      dataIda: (dados['dataIda'] as Timestamp).toDate(),
      dataVolta: (dados['dataVolta'] as Timestamp).toDate(),
      orcamentoDolares: (dados['orcamentoDolares'] as num).toDouble(),
      anotacoes: dados['anotacoes'] as String? ?? '',
      criadoEm: (dados['criadoEm'] as Timestamp).toDate(),
      fotoBase64: dados['fotoBase64'] as String?,
    );
  }

  Viagem copyWith({
    String? destino,
    String? pais,
    double? latitude,
    double? longitude,
    DateTime? dataIda,
    DateTime? dataVolta,
    double? orcamentoDolares,
    String? anotacoes,
    String? fotoBase64,
    bool limparFoto = false,
  }) {
    return Viagem(
      id: id,
      destino: destino ?? this.destino,
      pais: pais ?? this.pais,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dataIda: dataIda ?? this.dataIda,
      dataVolta: dataVolta ?? this.dataVolta,
      orcamentoDolares: orcamentoDolares ?? this.orcamentoDolares,
      anotacoes: anotacoes ?? this.anotacoes,
      criadoEm: criadoEm,
      fotoBase64: limparFoto ? null : (fotoBase64 ?? this.fotoBase64),
    );
  }
}
