import 'dart:io';

Future<String> lerArquivoLocal(String caminho) {
  return File(caminho).readAsString();
}
