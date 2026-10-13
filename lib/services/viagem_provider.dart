import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import '../models/viagem.dart';

// Provider da coleção "viagens" no Firestore: é a única camada que conversa
// com o Firestore. Os Blocs nunca acessam o Firestore diretamente, sempre
// passam por aqui.
class ViagemProvider {
  final _colecao = FirebaseFirestore.instance.collection('viagens');

  // Cada viagem guarda o uid de quem a criou; a lista só traz as viagens do
  // usuário logado. A ordenação por data é feita aqui no app para não
  // exigir um índice composto (uid + dataIda) no Firestore.
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<Viagem>> streamViagens() {
    return _colecao.where('uid', isEqualTo: _uid).snapshots().map((snapshot) {
      final viagens = snapshot.docs.map(Viagem.fromFirestore).toList();
      viagens.sort((a, b) => a.dataIda.compareTo(b.dataIda));
      return viagens;
    });
  }

  Stream<Viagem> streamViagemPorId(String id) {
    return _colecao.doc(id).snapshots().map(Viagem.fromFirestore);
  }

  adicionar(Viagem viagem) {
    return _colecao.add({...viagem.toMap(), 'uid': _uid});
  }

  atualizar(Viagem viagem) {
    return _colecao.doc(viagem.id).update(viagem.toMap());
  }

  atualizarAnotacoes(String id, String anotacoes) {
    return _colecao.doc(id).update({'anotacoes': anotacoes});
  }

  remover(String id) {
    return _colecao.doc(id).delete();
  }

  // Cria algumas viagens de exemplo para demonstração rápida em sala.
  /*
  semearExemplos() {
    final agora = DateTime.now();
    final exemplos = [
      Viagem(
        destino: 'Lisboa',
        pais: 'Portugal',
        latitude: 38.7167,
        longitude: -9.1333,
        dataIda: agora.add(const Duration(days: 20)),
        dataVolta: agora.add(const Duration(days: 30)),
        orcamentoDolares: 1800,
        anotacoes:
            'Viagem de intercâmbio acadêmico. Levar adaptador de tomada.',
        criadoEm: agora,
      ),
      Viagem(
        destino: 'Tóquio',
        pais: 'Japão',
        latitude: 35.6895,
        longitude: 139.6917,
        dataIda: agora.subtract(const Duration(days: 40)),
        dataVolta: agora.subtract(const Duration(days: 25)),
        orcamentoDolares: 3500,
        anotacoes:
            'Viagem concluída. Guardar recibos para o relatório de despesas.',
        criadoEm: agora,
      ),
    ];
    
    return _colecao
        .add(exemplos[0].toMap())
        .then((_) => _colecao.add(exemplos[1].toMap()))
        .then((_) => _colecao.add(exemplos[2].toMap()));
  }
  */
}
