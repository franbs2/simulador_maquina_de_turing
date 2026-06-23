class Transicao {
  String origem;
  String destino;
  String simboloLido;
  String simboloEscrito;
  String movimento;

  Transicao({
    required this.origem,
    required this.destino,
    required this.simboloLido,
    required this.simboloEscrito,
    required this.movimento,
  });

  String get rotulo => '$simboloLido/$simboloEscrito,$movimento';

  Transicao copyWith({
    String? origem,
    String? destino,
    String? simboloLido,
    String? simboloEscrito,
    String? movimento,
  }) {
    return Transicao(
      origem: origem ?? this.origem,
      destino: destino ?? this.destino,
      simboloLido: simboloLido ?? this.simboloLido,
      simboloEscrito: simboloEscrito ?? this.simboloEscrito,
      movimento: movimento ?? this.movimento,
    );
  }

  Map<String, dynamic> toJson() => {
        'origem': origem,
        'destino': destino,
        'ler': simboloLido,
        'escrever': simboloEscrito,
        'movimento': movimento,
      };

  factory Transicao.fromJson(Map<String, dynamic> json) {
    return Transicao(
      origem: json['origem'] as String,
      destino: json['destino'] as String,
      simboloLido: json['ler'] as String,
      simboloEscrito: json['escrever'] as String,
      movimento: json['movimento'] as String,
    );
  }
}
