import 'package:dio/dio.dart';

// Instância única do Dio usada por todos os serviços que consomem APIs
// externas. O LogInterceptor imprime cada requisição/resposta no console,
// útil para mostrar a comunicação com a internet durante a apresentação.
class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  )..interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
}
