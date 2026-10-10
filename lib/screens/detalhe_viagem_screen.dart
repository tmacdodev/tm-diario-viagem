import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/detalhe_viagem_bloc.dart';
import '../blocs/detalhe_viagem_state.dart';
import '../models/compra_dolar.dart';
import '../models/viagem.dart';
import '../services/compra_dolar_provider.dart';
import '../services/viagem_provider.dart';
import '../widgets/mapa_destino.dart';
import 'form_viagem_screen.dart';

// Tela de detalhe: mostra os dados salvos da viagem, o mapa com o pin do
// destino, o controle manual de compras de dólar (com totalizador) e a
// área de anotações do diário, editável direto por aqui.
//
// Toda a leitura em tempo real passa pelo DetalheViagemBloc
// Essa classe só monta o Bloc e repassa a viagem
// original para a View de verdade.
class DetalheViagemScreen extends StatelessWidget {
  final Viagem viagem;

  const DetalheViagemScreen({super.key, required this.viagem});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DetalheViagemBloc(viagemId: viagem.id!),
      child: _DetalheViagemView(viagemOriginal: viagem),
    );
  }
}

class _DetalheViagemView extends StatelessWidget {
  final Viagem viagemOriginal;

  _DetalheViagemView({required this.viagemOriginal});

  final _viagemProvider = ViagemProvider();
  final _compraProvider = CompraDolarProvider();
  final _formatoData = DateFormat('dd/MM/yyyy', 'pt_BR');
  final _formatoDolar = NumberFormat.currency(locale: 'pt_BR', symbol: 'US\$');
  final _formatoReal = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  _editarAnotacoes(BuildContext context, String textoAtual) {
    final controller = TextEditingController(text: textoAtual);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anotações do diário'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    ).then((novoTexto) {
      if (novoTexto != null) {
        return _viagemProvider.atualizarAnotacoes(
          viagemOriginal.id!,
          novoTexto,
        );
      }
    });
  }

  _adicionarCompra(BuildContext context) {
    final valorController = TextEditingController();
    final cotacaoController = TextEditingController();
    DateTime dataEscolhida = DateTime.now();

    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nova compra de dólar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(_formatoData.format(dataEscolhida)),
                onPressed: () {
                  showDatePicker(
                    context: ctx,
                    initialDate: dataEscolhida,
                    firstDate: DateTime(DateTime.now().year - 1),
                    lastDate: DateTime(DateTime.now().year + 5),
                  ).then((data) {
                    if (data != null) setState(() => dataEscolhida = data);
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor comprado (US\$)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cotacaoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Cotação paga (R\$ por US\$)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    ).then((salvar) {
      if (salvar != true) return null;

      final valor = double.tryParse(valorController.text.replaceAll(',', '.'));
      final cotacao = double.tryParse(
        cotacaoController.text.replaceAll(',', '.'),
      );
      if (valor == null || valor <= 0 || cotacao == null || cotacao <= 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Informe valores válidos para continuar.'),
            ),
          );
        }
        return null;
      }

      return _compraProvider.adicionar(
        viagemOriginal.id!,
        CompraDolar(
          data: dataEscolhida,
          valorDolares: valor,
          cotacaoPaga: cotacao,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(viagemOriginal.destino),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FormViagemScreen(viagem: viagemOriginal),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<DetalheViagemBloc, DetalheViagemState>(
        builder: (context, state) {
          final viagemAtual = state.viagem;
          if (viagemAtual == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (viagemAtual.fotoBase64 != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(viagemAtual.fotoBase64!),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${viagemAtual.destino}, ${viagemAtual.pais}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_formatoData.format(viagemAtual.dataIda)} até ${_formatoData.format(viagemAtual.dataVolta)}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Orçamento: ${_formatoDolar.format(viagemAtual.orcamentoDolares)}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Localização',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              MapaDestino(
                latitude: viagemAtual.latitude,
                longitude: viagemAtual.longitude,
              ),
              const SizedBox(height: 4),
              Text(
                'Lat: ${viagemAtual.latitude.toStringAsFixed(4)}  Lon: ${viagemAtual.longitude.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.yellow.shade50,
                child: ExpansionTile(
                  // Menu suspenso (tipo toggle do Notion): o controle de
                  // câmbio fica escondido até o usuário tocar para abrir.
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Controle de câmbio',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        onPressed: () => _adicionarCompra(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar compra'),
                      ),
                    ],
                  ),
                  children: [
                    _controleDeCambio(context, viagemAtual, state.compras),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Anotações do diário',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note),
                    onPressed: () =>
                        _editarAnotacoes(context, viagemAtual.anotacoes),
                  ),
                ],
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    viagemAtual.anotacoes.isEmpty
                        ? 'Nenhuma anotação ainda. Toque no lápis para escrever.'
                        : viagemAtual.anotacoes,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Conteúdo do menu suspenso de câmbio: lista de compras + totalizador.
  // Os dados já vêm prontos do DetalheViagemState .
  Widget _controleDeCambio(
    BuildContext context,
    Viagem viagemAtual,
    List<CompraDolar> compras,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: compras.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Nenhuma compra de dólar registrada ainda.'),
            )
          : Builder(
              builder: (context) {
                final totalDolares = compras.fold<double>(
                  0,
                  (soma, c) => soma + c.valorDolares,
                );
                final totalReais = compras.fold<double>(
                  0,
                  (soma, c) => soma + c.valorReais,
                );
                final progresso = (totalDolares / viagemAtual.orcamentoDolares)
                    .clamp(0.0, 1.0);

                return Column(
                  children: [
                    Card(
                      child: Column(
                        children: compras
                            .map(
                              (c) => ListTile(
                                leading: const Icon(Icons.attach_money),
                                title: Text(
                                  '${_formatoDolar.format(c.valorDolares)}  (cotação ${c.cotacaoPaga.toStringAsFixed(2)})',
                                ),
                                subtitle: Text(
                                  '${_formatoData.format(c.data)} · ${_formatoReal.format(c.valorReais)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _compraProvider.remover(
                                    viagemAtual.id!,
                                    c.id!,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total investido em Reais R\$: ${_formatoReal.format(totalReais)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatoDolar.format(totalDolares)} comprados de ${_formatoDolar.format(viagemAtual.orcamentoDolares)} do orçamento',
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progresso,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
