import 'dart:convert';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

// Erro de validação da foto, com mensagem já pronta para mostrar ao usuário.
class ErroFoto implements Exception {
  final String mensagem;
  ErroFoto(this.mensagem);
  @override
  String toString() => mensagem;
}

// Cuida da escolha e validação da foto de capa da viagem. A imagem precisa
// ser quadrada e ter no máximo 1000x1000 pixels; depois de validada, é
// convertida para base64 para ser salva direto no documento da viagem no
// Firestore (sem precisar configurar o Firebase Storage).
class FotoViagemService {
  final _picker = ImagePicker();

  // Retorna null se o usuário cancelar a escolha.
  selecionarFotoBase64() {
    // O <String?> aqui só ajuda o Dart a entender que esse encadeamento
    // pode terminar em null (cancelado) ou numa String (foto validada).
    return _picker.pickImage(source: ImageSource.gallery).then<String?>((
      arquivo,
    ) {
      if (arquivo == null) return null;

      return arquivo.readAsBytes().then((bytes) {
        final imagem = img.decodeImage(bytes);
        if (imagem == null) {
          throw ErroFoto('Não foi possível ler essa imagem...');
        }
        if (imagem.width != imagem.height) {
          throw ErroFoto(
            'A imagem precisa ser quadrada (largura igual à altura).',
          );
        }
        if (imagem.width > 1000) {
          throw ErroFoto('A imagem pode ter no máximo 1000x1000 pixels.');
        }

        final jpg = img.encodeJpg(imagem, quality: 85);
        return base64Encode(jpg);
      });
    });
  }
}
