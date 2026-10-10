import '../models/mensagem_chat.dart';

// Estado do ChatBotBloc: só o histórico de mensagens trocadas na conversa.
class ChatBotState {
  final List<MensagemChat> mensagens;

  const ChatBotState({this.mensagens = const []});

  ChatBotState copyWith({List<MensagemChat>? mensagens}) {
    return ChatBotState(mensagens: mensagens ?? this.mensagens);
  }
}
