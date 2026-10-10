// Eventos que o ChatBotBloc sabe processar.
abstract class ChatBotEvent {
  const ChatBotEvent();
}

// Disparado quando o usuário envia uma pergunta no campo de texto.
// O texto da pergunta não influencia a resposta (ela é sempre sorteada),
// mas é guardado para aparecer no histórico da conversa.
class PerguntaEnviada extends ChatBotEvent {
  final String pergunta;

  const PerguntaEnviada(this.pergunta);
}
