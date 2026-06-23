import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<String?> salvarConteudoEmArquivo({
  required String nomeArquivo,
  required String conteudo,
}) async {
  final caminho = await FilePicker.platform.saveFile(
    dialogTitle: 'Salvar Máquina de Turing',
    fileName: nomeArquivo,
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (caminho == null) return null;

  final path = caminho.toLowerCase().endsWith('.json') ? caminho : '$caminho.json';
  await File(path).writeAsString(conteudo, flush: true);
  return path;
}
