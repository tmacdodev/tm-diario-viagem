import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/chat_bot_bloc.dart';
import '../blocs/chat_bot_event.dart';
import '../blocs/chat_bot_state.dart';
import '../models/mensagem_chat.dart';

// Tela do "assistente de viagem": um chat simples onde qualquer pergunta
// recebe uma dica aleatória de uma lista fixa.
class ChatBotScreen extends StatelessWidget {
  const ChatBotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatBotBloc(),
      child: const _ChatBotView(),
    );
  }
}

class _ChatBotView extends StatefulWidget {
  const _ChatBotView();

  @override
  State<_ChatBotView> createState() => _ChatBotViewState();
}

class _ChatBotViewState extends State<_ChatBotView> {
  final _perguntaController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _perguntaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enviarPergunta(BuildContext context) {
    final texto = _perguntaController.text.trim();
    if (texto.isEmpty) return;

    context.read<ChatBotBloc>().add(PerguntaEnviada(texto));
    _perguntaController.clear();

    // Rola para o final depois que a nova mensagem for desenhada.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistente de viagem')),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBotBloc, ChatBotState>(
              builder: (context, state) {
                if (state.mensagens.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Pergunte algo como "o que eu posso estar esquecendo de levar?" '
                        'e receba uma dica aleatória.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: state.mensagens.length,
                  itemBuilder: (context, index) =>
                      _BalaoMensagem(mensagem: state.mensagens[index]),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _perguntaController,
                      decoration: const InputDecoration(
                        hintText: 'Pergunte algo...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _enviarPergunta(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _enviarPergunta(context),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalaoMensagem extends StatelessWidget {
  final MensagemChat mensagem;

  const _BalaoMensagem({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Align(
      alignment: mensagem.doUsuario
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: mensagem.doUsuario ? cores.primary : cores.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          mensagem.texto,
          style: TextStyle(
            color: mensagem.doUsuario
                ? cores.onPrimary
                : cores.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
