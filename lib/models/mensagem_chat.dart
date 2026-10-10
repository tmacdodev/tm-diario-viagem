// Uma mensagem exibida na tela do assistente de viagem: pode ser uma
// pergunta digitada pelo usuário ou uma resposta sorteada pelo bot.
class MensagemChat {
  final String texto;
  final bool doUsuario;

  MensagemChat({required this.texto, required this.doUsuario});
}
