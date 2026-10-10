import 'package:flutter/material.dart';

import '../models/viagem.dart';

// Selo colorido mostrando quantos dias faltam para a viagem, se ela está
// em andamento ou se já foi realizada.
class StatusViagemBadge extends StatelessWidget {
  final Viagem viagem;

  const StatusViagemBadge({super.key, required this.viagem});

  @override
  Widget build(BuildContext context) {
    final (texto, cor) = switch (viagem.status) {
      StatusViagem.proxima => (
        _textoDiasRestantes(viagem.diasParaIda),
        Colors.lightGreen,
      ),
      StatusViagem.emAndamento => ('Em andamento', Colors.orange),
      StatusViagem.concluida => ('Viagem realizada', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  String _textoDiasRestantes(int dias) {
    return dias == 1 ? 'Falta 1 dia' : 'Faltam $dias dias';
  }
}
