import 'package:dio/dio.dart';

import 'api_client.dart';

// Um resultado de busca de cidade retornado pela API de geocodificação.
class ResultadoCidade {
  final String nome;
  final String pais;
  final double latitude;
  final double longitude;
  final String? regiao;

  ResultadoCidade({
    required this.nome,
    required this.pais,
    required this.latitude,
    required this.longitude,
    this.regiao,
  });

  // Texto amigável para mostrar numa lista de opções
  String get descricao => regiao != null && regiao!.isNotEmpty
      ? '$nome, $regiao - $pais'
      : '$nome, $pais';
}

// Exceção com mensagem já traduzida para o usuário, lançada pelos serviços
// que consomem APIs externas.
class ErroApi implements Exception {
  final String mensagem;
  ErroApi(this.mensagem);
  @override
  String toString() => mensagem;
}

// Consome a API de geocodificação do Open-Meteo para transformar o nome
// de uma cidade digitada pelo usuário em país + latitude + longitude.
class GeocodingService {
  static const _baseUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  buscarCidade(String nomeCidade) {
    return ApiClient.dio
        .get(
          _baseUrl,
          queryParameters: {'name': nomeCidade, 'count': 5, 'language': 'pt'},
        )
        .then((resposta) {
          final resultados = resposta.data['results'] as List<dynamic>?;
          if (resultados == null || resultados.isEmpty) {
            throw ErroApi('Nenhuma cidade encontrada com esse nome.');
          }

          return resultados.map((item) {
            return ResultadoCidade(
              nome: item['name'] as String,
              pais: item['country'] as String? ?? 'Desconhecido',
              latitude: (item['latitude'] as num).toDouble(),
              longitude: (item['longitude'] as num).toDouble(),
              regiao: item['admin1'] as String?,
            );
          }).toList();
        })
        .catchError((erro) {
          if (erro is DioException) {
            throw ErroApi(_traduzirErroDio(erro));
          }
          throw erro;
        });
  }

  String _traduzirErroDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'A busca demorou demais para responder. Verifique sua conexão e tente novamente.';
      case DioExceptionType.connectionError:
        return 'Sem conexão com a internet. Verifique o Wi-Fi ou os dados móveis.';
      default:
        return 'Não foi possível buscar a cidade agora. Tente novamente.';
    }
  }
}
