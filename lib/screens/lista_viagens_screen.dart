import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../blocs/viagens_bloc.dart';
import '../blocs/viagens_state.dart';
import '../models/viagem.dart';
import '../services/viagem_provider.dart';
import '../widgets/status_viagem_badge.dart';
import 'chat_bot_screen.dart';
import 'detalhe_viagem_screen.dart';
import 'form_viagem_screen.dart';

// Tela inicial: lista as viagens em tempo real através do ViagensBloc
// ordenadas pela data de ida, com opção de
// abrir o detalhe, criar uma nova viagem ou excluir arrastando o card. O
// botão flutuante abre um pequeno menu com os atalhos de "nova viagem" e
// "assistente de viagem".
class ListaViagensScreen extends StatefulWidget {
  const ListaViagensScreen({super.key});

  @override
  State<ListaViagensScreen> createState() => _ListaViagensScreenState();
}

class _ListaViagensScreenState extends State<ListaViagensScreen> {
  final _provider = ViagemProvider();
  late final _viagensBloc = ViagensBloc(provider: _provider);
  final _formatoData = DateFormat('dd/MM/yyyy', 'pt_BR');
  final _formatoDolar = NumberFormat.currency(locale: 'pt_BR', symbol: 'US\$');

  bool _menuAberto = false;

  @override
  void dispose() {
    _viagensBloc.close();
    super.dispose();
  }

  void _alternarMenu() => setState(() => _menuAberto = !_menuAberto);

  void _abrirNovaViagem() {
    setState(() => _menuAberto = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FormViagemScreen()),
    );
  }

  void _abrirAssistente() {
    setState(() => _menuAberto = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatBotScreen()),
    );
  }

  // Miniatura quadrada da viagem: a foto cadastrada, ou um ícone de
  // placeholder quando a viagem ainda não tem foto.
  Widget _fotoViagem(BuildContext context, Viagem viagem) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: viagem.fotoBase64 != null
            ? Image.memory(base64Decode(viagem.fotoBase64!), fit: BoxFit.cover)
            : Container(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  Icons.image_outlined,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
      ),
    );
  }

  _confirmarExclusao(BuildContext context, Viagem viagem) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir viagem'),
        content: Text('Deseja excluir a viagem para ${viagem.destino}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    ).then((confirmou) {
      if (confirmou == true) {
        return _provider.remover(viagem.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: _viagensBloc, child: _buildScaffold());
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 12,
        // Título dentro de uma caixa arredondada com sombra, esticado para
        // ocupar a largura toda com FittedBox, em maiúsculo e fonte moderna.
        // A altura precisa ficar travada num SizedBox, senão o FittedBox
        // não tem limite e deixa o texto gigante.
        title: SizedBox(
          height: 48,
          width: double.infinity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                'DIÁRIO DE VIAGEM',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<ViagensBloc, ViagensState>(
        builder: (context, state) {
          if (state.erro != null) {
            return Center(
              child: Text('Erro ao carregar viagens: ${state.erro}'),
            );
          }
          if (state.carregando) {
            return const Center(child: CircularProgressIndicator());
          }

          final viagens = state.viagens;
          if (viagens.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.card_travel, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhuma viagem cadastrada ainda.\nToque no botão + para começar.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: viagens.length,
            itemBuilder: (context, index) {
              final viagem = viagens[index];
              return Dismissible(
                key: ValueKey(viagem.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) {
                  // a remoção já acontece via stream do Firestore
                  return _confirmarExclusao(context, viagem).then((_) => false);
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: _fotoViagem(context, viagem),
                    title: Text(
                      '${viagem.destino}, ${viagem.pais}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${_formatoData.format(viagem.dataIda)} - ${_formatoData.format(viagem.dataVolta)}\n'
                        'Orçamento: ${_formatoDolar.format(viagem.orcamentoDolares)}',
                      ),
                    ),
                    isThreeLine: true,
                    trailing: StatusViagemBadge(viagem: viagem),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalheViagemScreen(viagem: viagem),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_menuAberto) ...[
            _ItemMenuFlutuante(
              heroTag: 'fab-assistente',
              icon: Icons.smart_toy_outlined,
              rotulo: 'Assistente',
              onPressed: _abrirAssistente,
            ),
            const SizedBox(height: 12),
            _ItemMenuFlutuante(
              heroTag: 'fab-nova-viagem',
              icon: Icons.flight_takeoff,
              rotulo: 'Nova viagem',
              onPressed: _abrirNovaViagem,
            ),
            const SizedBox(height: 16),
          ],
          GestureDetector(
            // Toque longo no FAB (fechado) cadastra viagens de exemplo, para demonstração.
            /*onLongPress: _menuAberto
                ? null
                : () {
                    _provider.semearExemplos().then((_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Viagens de exemplo adicionadas!'),
                          ),
                        );
                      }
                    });
                  },*/
            child: FloatingActionButton(
              heroTag: 'fab-principal',
              tooltip: _menuAberto ? 'Fechar menu' : 'Abrir menu',
              onPressed: _alternarMenu,
              child: AnimatedRotation(
                turns: _menuAberto ? 0 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(_menuAberto ? Icons.close : Icons.menu),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Um item do menu flutuante: um rótulo e um botão pequeno, que sobe com
// uma leve animação de entrada quando o menu é aberto.
class _ItemMenuFlutuante extends StatelessWidget {
  final Object heroTag;
  final IconData icon;
  final String rotulo;
  final VoidCallback onPressed;

  const _ItemMenuFlutuante({
    required this.heroTag,
    required this.icon,
    required this.rotulo,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, valor, child) => Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, (1 - valor) * 16),
          child: child,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(rotulo),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: heroTag,
            onPressed: onPressed,
            child: Icon(icon),
          ),
        ],
      ),
    );
  }
}
