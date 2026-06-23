class Fita {
  final String simboloBranco;
  final Map<int, String> _celulas = {};
  int posicao;

  Fita({
    this.simboloBranco = '_',
    this.posicao = 0,
  });

  String ler() => _celulas[posicao] ?? simboloBranco;

  void escrever(String simbolo) {
    _celulas[posicao] = simbolo;
  }

  void moverEsquerda() => posicao--;

  void moverDireita() => posicao++;

  void carregarEntrada(String entrada) {
    _celulas.clear();
    posicao = 0;
    for (var i = 0; i < entrada.length; i++) {
      _celulas[i] = entrada[i];
    }
  }

  Fita copia() {
    final nova = Fita(simboloBranco: simboloBranco, posicao: posicao);
    nova._celulas.addAll(_celulas);
    return nova;
  }

  Fita comSimboloBranco(String novo) {
    final nova = Fita(simboloBranco: novo, posicao: posicao);
    nova._celulas.addAll(_celulas);
    return nova;
  }

  /// Retorna células visíveis em torno do cabeçote para exibição.
  List<MapEntry<int, String>> celulasVisiveis({int raio = 8}) {
    final indices = <int>{posicao};
    for (var i = posicao - raio; i <= posicao + raio; i++) {
      indices.add(i);
    }
    for (final k in _celulas.keys) {
      if ((k - posicao).abs() <= raio) indices.add(k);
    }
    final sorted = indices.toList()..sort();
    return sorted.map((i) => MapEntry(i, _celulas[i] ?? simboloBranco)).toList();
  }

  Map<String, dynamic> toJson() => {
        'simboloBranco': simboloBranco,
        'posicao': posicao,
        'celulas': _celulas.map((k, v) => MapEntry(k.toString(), v)),
      };

  factory Fita.fromJson(Map<String, dynamic> json) {
    final fita = Fita(
      simboloBranco: json['simboloBranco'] as String? ?? '_',
      posicao: json['posicao'] as int? ?? 0,
    );
    final celulas = json['celulas'] as Map<String, dynamic>?;
    if (celulas != null) {
      for (final entry in celulas.entries) {
        fita._celulas[int.parse(entry.key)] = entry.value as String;
      }
    }
    return fita;
  }
}
