import 'dart:math';

// Provider do assistente de viagem: é a única camada que sabe de onde vêm
// as dicas. Hoje elas são uma lista fixa sorteada aqui mesmo, mas se um dia
// vierem de uma API, é só trocar a implementação deste método — o Bloc não
// muda nada, porque ele nunca acessa a fonte de dados (nem a internet)
// diretamente, sempre pede para o Provider.
class ChatBotProvider {
  static const _dicas = [
    'Pegou o carregador de celular?',
    'Lembre-se da capa de chuva!',
    'Passaporte em mãos?',
    'Aviso de Viagem no app do banco está ok?',
    'Imprima um roteiro em papel para entregar na imigração ;)',
    'Confira o bilhete do seguro viagem do cartão de crédito.',
    'Vai dirigir? Confira se sua PID está válida!',
    'Lembre-se de levar baterias extras CR2032 para AirTag.',
    'Liberou espaço no celular para tirar novas fotos?',
    'Download de mapa off-line do Google Maps está ok?',
  ];

  final _sorteio = Random();

  // Recebe a pergunta só para manter a mesma assinatura que teria se um dia
  // consultasse uma API de verdade; a resposta de hoje é sempre aleatória.
  String buscarDica(String pergunta) {
    return _dicas[_sorteio.nextInt(_dicas.length)];
  }
}
