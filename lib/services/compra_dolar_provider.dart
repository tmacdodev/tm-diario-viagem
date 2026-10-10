import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/compra_dolar.dart';

// Provider da subcoleção "compras" dentro de cada viagem
// (viagens/{viagemId}/compras). Só essa camada fala com o Firestore.
class CompraDolarProvider {
  CollectionReference<Map<String, dynamic>> _colecao(String viagemId) {
    return FirebaseFirestore.instance
        .collection('viagens')
        .doc(viagemId)
        .collection('compras');
  }

  Stream<List<CompraDolar>> streamCompras(String viagemId) {
    return _colecao(viagemId)
        .orderBy('data')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(CompraDolar.fromFirestore).toList(),
        );
  }

  adicionar(String viagemId, CompraDolar compra) {
    return _colecao(viagemId).add(compra.toMap());
  }

  remover(String viagemId, String compraId) {
    return _colecao(viagemId).doc(compraId).delete();
  }
}
