import 'package:flutter/material.dart';

// Mostra um mapa-múndi (projeção equirretangular) com um pin vermelho na
// posição do destino, calculada a partir da latitude/longitude salvas.
class MapaDestino extends StatelessWidget {
  final double latitude;
  final double longitude;

  const MapaDestino({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  static const _aspectRatioMapa = 1280 / 602;

  @override
  Widget build(BuildContext context) {
    final alinhamentoX = (longitude / 180).clamp(-1.0, 1.0);
    final alinhamentoY = (-latitude / 90).clamp(-1.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _aspectRatioMapa,
        child: Stack(
          children: [
            Image.asset(
              'assets/images/world_map_grey.png',
              fit: BoxFit.fill,
              width: double.infinity,
              height: double.infinity,
            ),
            Align(
              alignment: Alignment(alinhamentoX, alinhamentoY),
              child: Transform.translate(
                offset: const Offset(0, -14),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 28,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
