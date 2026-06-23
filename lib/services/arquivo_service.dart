import 'dart:convert';
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/maquina_turing.dart';
import '../models/maquina_model.dart';

enum ResultadoArquivo { sucesso, cancelado, erro }

class ArquivoService {
  static String serializar(MaquinaModel model) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(model.toJson());
  }

  static MaquinaTuring desserializar(String jsonStr) {
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final model = MaquinaModel();
    model.fromJson(json);
    return model.maquina;
  }

  static Future<({ResultadoArquivo tipo, String? caminho, String? erro})> salvar(
    MaquinaModel model, {
    String nomeArquivo = 'maquina_turing',
  }) async {
    try {
      final conteudo = serializar(model);
      final bytes = Uint8List.fromList(utf8.encode(conteudo));

      if (kIsWeb) {
        final caminho = await FilePicker.platform.saveFile(
          dialogTitle: 'Salvar Máquina de Turing',
          fileName: '$nomeArquivo.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes,
        );
        if (caminho == null) {
          return (tipo: ResultadoArquivo.cancelado, caminho: null, erro: null);
        }
        return (tipo: ResultadoArquivo.sucesso, caminho: caminho, erro: null);
      }

      final caminho = await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar Máquina de Turing',
        fileName: '$nomeArquivo.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (caminho == null) {
        return (tipo: ResultadoArquivo.cancelado, caminho: null, erro: null);
      }

      final path = _garantirExtensaoJson(caminho);
      await File(path).writeAsString(conteudo, flush: true);

      return (tipo: ResultadoArquivo.sucesso, caminho: path, erro: null);
    } catch (e, st) {
      debugPrint('Erro ao salvar: $e\n$st');
      return (tipo: ResultadoArquivo.erro, caminho: null, erro: e.toString());
    }
  }

  static String _garantirExtensaoJson(String caminho) {
    if (caminho.toLowerCase().endsWith('.json')) return caminho;
    return '$caminho.json';
  }

  static Future<MaquinaTuring?> carregar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      String conteudo;

      if (file.bytes != null) {
        conteudo = utf8.decode(file.bytes!);
      } else if (!kIsWeb && file.path != null) {
        conteudo = await File(file.path!).readAsString();
      } else {
        return null;
      }

      return desserializar(conteudo);
    } catch (e, st) {
      debugPrint('Erro ao carregar: $e\n$st');
      return null;
    }
  }
}
