class Estado {
  String nome;
  double x;
  double y;
  bool inicial;
  bool finalState;

  Estado({
    required this.nome,
    this.x = 0,
    this.y = 0,
    this.inicial = false,
    this.finalState = false,
  });

  Estado copyWith({
    String? nome,
    double? x,
    double? y,
    bool? inicial,
    bool? finalState,
  }) {
    return Estado(
      nome: nome ?? this.nome,
      x: x ?? this.x,
      y: y ?? this.y,
      inicial: inicial ?? this.inicial,
      finalState: finalState ?? this.finalState,
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'x': x,
        'y': y,
        'inicial': inicial,
        'final': finalState,
      };

  factory Estado.fromJson(Map<String, dynamic> json) {
    return Estado(
      nome: json['nome'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      inicial: json['inicial'] as bool? ?? false,
      finalState: json['final'] as bool? ?? false,
    );
  }
}
