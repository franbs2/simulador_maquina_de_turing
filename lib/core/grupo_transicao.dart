import 'transicao.dart';

/// Agrupa transições que compartilham a mesma seta visual (mesmo par origem → destino).
class GrupoTransicao {
  final String origem;
  final String destino;
  final List<Transicao> transicoes;

  const GrupoTransicao({
    required this.origem,
    required this.destino,
    required this.transicoes,
  });

  List<String> get rotulos =>
      transicoes.map((t) => t.rotulo).toList(growable: false);

  String get rotuloCompleto => rotulos.join('\n');

  bool contem(Transicao? t) => t != null && transicoes.contains(t);

  bool get ativo => transicoes.isNotEmpty;
}

List<GrupoTransicao> agruparTransicoes(List<Transicao> transicoes) {
  final map = <String, List<Transicao>>{};

  for (final t in transicoes) {
    final chave = '${t.origem}\u0000${t.destino}';
    map.putIfAbsent(chave, () => []).add(t);
  }

  return map.entries.map((e) {
    final lista = e.value
      ..sort((a, b) => a.simboloLido.compareTo(b.simboloLido));
    return GrupoTransicao(
      origem: lista.first.origem,
      destino: lista.first.destino,
      transicoes: lista,
    );
  }).toList();
}

/// Transições já existentes na mesma aresta (origem → destino).
List<Transicao> transicoesNaAresta(
  List<Transicao> transicoes,
  String origem,
  String destino,
) {
  return transicoes
      .where((t) => t.origem == origem && t.destino == destino)
      .toList()
    ..sort((a, b) => a.simboloLido.compareTo(b.simboloLido));
}
