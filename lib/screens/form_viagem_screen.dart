import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/viagem.dart';
import '../services/foto_viagem_service.dart';
import '../services/geocoding_service.dart';
import '../services/viagem_provider.dart';

// Tela de cadastro/edição de viagem. Se [viagem] for passada, o formulário
// já vem preenchido e o salvar faz um update; caso contrário, cria uma nova.
class FormViagemScreen extends StatefulWidget {
  final Viagem? viagem;

  const FormViagemScreen({super.key, this.viagem});

  @override
  State<FormViagemScreen> createState() => _FormViagemScreenState();
}

class _FormViagemScreenState extends State<FormViagemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _provider = ViagemProvider();
  final _geocodingService = GeocodingService();
  final _fotoService = FotoViagemService();
  final _formatoData = DateFormat('dd/MM/yyyy', 'pt_BR');

  final _buscaCidadeController = TextEditingController();
  final _orcamentoController = TextEditingController();
  final _anotacoesController = TextEditingController();

  // Dados do destino, preenchidos pela geocodificação ou pela viagem existente.
  String? _destino;
  String? _pais;
  double? _latitude;
  double? _longitude;

  DateTime? _dataIda;
  DateTime? _dataVolta;

  String? _fotoBase64;

  bool _buscando = false;
  String? _erroBusca;
  List<ResultadoCidade> _resultadosBusca = [];

  bool get _editando => widget.viagem != null;

  @override
  void initState() {
    super.initState();
    final viagem = widget.viagem;
    if (viagem != null) {
      _destino = viagem.destino;
      _pais = viagem.pais;
      _latitude = viagem.latitude;
      _longitude = viagem.longitude;
      _dataIda = viagem.dataIda;
      _dataVolta = viagem.dataVolta;
      _orcamentoController.text = viagem.orcamentoDolares.toStringAsFixed(2);
      _anotacoesController.text = viagem.anotacoes;
      _fotoBase64 = viagem.fotoBase64;
    }
  }

  @override
  void dispose() {
    _buscaCidadeController.dispose();
    _orcamentoController.dispose();
    _anotacoesController.dispose();
    super.dispose();
  }

  // Sem async/await: .then() trata o sucesso, .catchError() trata o erro
  // (equivalente ao try/catch) e .whenComplete() sempre roda no final
  // (equivalente ao finally).
  _buscarCidade() {
    final nome = _buscaCidadeController.text.trim();
    if (nome.isEmpty) return;

    setState(() {
      _buscando = true;
      _erroBusca = null;
      _resultadosBusca = [];
    });

    _geocodingService
        .buscarCidade(nome)
        .then((resultados) => setState(() => _resultadosBusca = resultados))
        .catchError((erro) {
          if (erro is ErroApi) {
            setState(() => _erroBusca = erro.mensagem);
          } else {
            throw erro;
          }
        })
        .whenComplete(() => setState(() => _buscando = false));
  }

  void _selecionarCidade(ResultadoCidade resultado) {
    setState(() {
      _destino = resultado.nome;
      _pais = resultado.pais;
      _latitude = resultado.latitude;
      _longitude = resultado.longitude;
      _resultadosBusca = [];
      _buscaCidadeController.clear();
    });
  }

  _escolherFoto() {
    _fotoService
        .selecionarFotoBase64()
        .then((foto) {
          if (foto != null) setState(() => _fotoBase64 = foto);
        })
        .catchError((erro) {
          if (erro is ErroFoto && mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(erro.mensagem)));
          } else if (erro is! ErroFoto) {
            throw erro;
          }
        });
  }

  _escolherData({required bool ida}) {
    final inicial = ida
        ? (_dataIda ?? DateTime.now())
        : (_dataVolta ?? _dataIda ?? DateTime.now());
    showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
    ).then((data) {
      if (data == null) return;
      setState(() {
        if (ida) {
          _dataIda = data;
        } else {
          _dataVolta = data;
        }
      });
    });
  }

  _salvar() {
    if (!_formKey.currentState!.validate()) return;

    if (_destino == null ||
        _pais == null ||
        _latitude == null ||
        _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Busque e selecione a cidade de destino.'),
        ),
      );
      return;
    }
    if (_dataIda == null || _dataVolta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione as datas de ida e volta.')),
      );
      return;
    }
    if (_dataVolta!.isBefore(_dataIda!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A data de volta não pode ser antes da data de ida.'),
        ),
      );
      return;
    }

    final orcamento = double.parse(
      _orcamentoController.text.replaceAll(',', '.'),
    );

    final salvando = _editando
        ? _provider.atualizar(
            widget.viagem!.copyWith(
              destino: _destino,
              pais: _pais,
              latitude: _latitude,
              longitude: _longitude,
              dataIda: _dataIda,
              dataVolta: _dataVolta,
              orcamentoDolares: orcamento,
              anotacoes: _anotacoesController.text,
              fotoBase64: _fotoBase64,
              limparFoto: _fotoBase64 == null,
            ),
          )
        : _provider.adicionar(
            Viagem(
              destino: _destino!,
              pais: _pais!,
              latitude: _latitude!,
              longitude: _longitude!,
              dataIda: _dataIda!,
              dataVolta: _dataVolta!,
              orcamentoDolares: orcamento,
              anotacoes: _anotacoesController.text,
              criadoEm: DateTime.now(),
              fotoBase64: _fotoBase64,
            ),
          );

    salvando.then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  _confirmarExclusao() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir viagem'),
        content: const Text('Deseja realmente excluir essa viagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim'),
          ),
        ],
      ),
    ).then((confirmou) {
      if (confirmou == true) {
        return _provider.remover(widget.viagem!.id!).then((_) {
          if (mounted) {
            Navigator.of(context).popUntil((rota) => rota.isFirst);
          }
        });
      }
    });
  }

  // Quadrado de 120x120 com a foto escolhida (ou um placeholder), um botão
  // para remover a foto atual e a dica do tamanho exigido.
  Widget _campoFoto(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _escolherFoto,
          child: Stack(
            children: [
              // Animação de transição suave: quando uma foto é escolhida, o
              // quadrado cresce, fica com cantos mais arredondados e troca
              // o fundo colorido pela própria imagem.
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: _fotoBase64 != null ? 140 : 120,
                height: _fotoBase64 != null ? 140 : 120,
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _fotoBase64 != null
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(
                    _fotoBase64 != null ? 24 : 12,
                  ),
                ),
                child: _fotoBase64 != null
                    ? Image.memory(
                        base64Decode(_fotoBase64!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Icon(
                        Icons.add_a_photo_outlined,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                      ),
              ),
              if (_fotoBase64 != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => setState(() => _fotoBase64 = null),
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Imagem quadrada, até 1000x1000 pixels',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar viagem' : 'Nova viagem'),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        actions: [
          if (_editando)
            IconButton(
              onPressed: _confirmarExclusao,
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
            ),
          IconButton(
            onPressed: _salvar,
            icon: const Icon(Icons.check),
            color: Colors.green,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Foto da viagem',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Center(child: _campoFoto(context)),
            const SizedBox(height: 24),
            Text('Destino', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_destino != null)
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.place),
                  title: Text('$_destino, $_pais'),
                  subtitle: Text(
                    'Lat: ${_latitude!.toStringAsFixed(2)}  Lon: ${_longitude!.toStringAsFixed(2)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Buscar outra cidade',
                    onPressed: () => setState(() {
                      _destino = null;
                      _pais = null;
                      _latitude = null;
                      _longitude = null;
                    }),
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _buscaCidadeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da cidade',
                        hintText: 'Ex: New York',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _buscarCidade(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _buscando ? null : _buscarCidade,
                    icon: _buscando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                  ),
                ],
              ),
              if (_erroBusca != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _erroBusca!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: _buscarCidade,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              if (_resultadosBusca.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: _resultadosBusca
                        .map(
                          (r) => ListTile(
                            leading: const Icon(Icons.location_city),
                            title: Text(r.descricao),
                            onTap: () => _selecionarCidade(r),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
            const SizedBox(height: 24),
            Text('Datas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _escolherData(ida: true),
                    icon: const Icon(Icons.flight_takeoff, color: Colors.green),
                    label: Text(
                      _dataIda == null
                          ? 'Data de ida'
                          : _formatoData.format(_dataIda!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _escolherData(ida: false),
                    icon: const Icon(Icons.flight_land, color: Colors.red),
                    label: Text(
                      _dataVolta == null
                          ? 'Data de volta'
                          : _formatoData.format(_dataVolta!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Orçamento', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _orcamentoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Orçamento em dólares (US\$)',
                prefixText: 'US\$ ',
                border: OutlineInputBorder(),
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Informe o orçamento.';
                }
                final numero = double.tryParse(valor.replaceAll(',', '.'));
                if (numero == null || numero <= 0) {
                  return 'Informe um valor válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Anotações', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _anotacoesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Escreva aqui as anotações do seu diário...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: _salvar,
              child: const Text('Salvar viagem'),
            ),
          ],
        ),
      ),
    );
  }
}
