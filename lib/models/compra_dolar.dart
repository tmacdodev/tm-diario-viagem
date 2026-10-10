import 'package:cloud_firestore/cloud_firestore.dart';

// Um registro de compra de dólares para a viagem: quanto foi comprado
// e a cotação (reais por dólar) paga naquela data. O valor em reais
// é sempre calculado a partir desses dois campos, nunca salvo separado.
class CompraDolar {
  final String? id;
  final DateTime data;
  final double valorDolares;
  final double cotacaoPaga;

  CompraDolar({
    this.id,
    required this.data,
    required this.valorDolares,
    required this.cotacaoPaga,
  });

  double get valorReais => valorDolares * cotacaoPaga;

  Map<String, dynamic> toMap() {
    return {
      'data': Timestamp.fromDate(data),
      'valorDolares': valorDolares,
      'cotacaoPaga': cotacaoPaga,
    };
  }

  factory CompraDolar.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final dados = doc.data()!;
    return CompraDolar(
      id: doc.id,
      data: (dados['data'] as Timestamp).toDate(),
      valorDolares: (dados['valorDolares'] as num).toDouble(),
      cotacaoPaga: (dados['cotacaoPaga'] as num).toDouble(),
    );
  }
}
