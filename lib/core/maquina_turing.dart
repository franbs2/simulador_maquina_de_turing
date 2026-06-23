import 'estado.dart';
import 'fita.dart';
import 'transicao.dart';

enum ResultadoExecucao {
  sucesso,
  semTransicao,
  estadoFinal,
  limiteExcedido,
}

class ResultadoPasso {
  final ResultadoExecucao tipo;
  final Transicao? transicao;
  final String simboloLido;
  final String simboloEscrito;
  final String estadoAnterior;
  final String estadoAtual;
  final int posicaoAnterior;
  final int posicaoAtual;

  const ResultadoPasso({
    required this.tipo,
    this.transicao,
    required this.simboloLido,
    required this.simboloEscrito,
    required this.estadoAnterior,
    required this.estadoAtual,
    required this.posicaoAnterior,
    required this.posicaoAtual,
  });
}

class MaquinaTuring {
  List<Estado> estados;
  List<Transicao> transicoes;
  String? estadoAtual;
  Fita fita;
  String simboloBranco;
  String entradaInicial;

  Transicao? ultimaTransicao;
  bool emEstadoFinal;

  MaquinaTuring({
    List<Estado>? estados,
    List<Transicao>? transicoes,
    this.simboloBranco = '_',
    this.entradaInicial = '',
    Fita? fita,
  })  : estados = estados ?? [],
        transicoes = transicoes ?? [],
        fita = fita ?? Fita(simboloBranco: simboloBranco),
        emEstadoFinal = false {
    _inicializarEstado();
  }

  void _inicializarEstado() {
    final inicial = estados.where((e) => e.inicial).toList();
    estadoAtual = inicial.isNotEmpty ? inicial.first.nome : null;
    emEstadoFinal = false;
    ultimaTransicao = null;
  }

  Estado? get estadoAtualObj {
    if (estadoAtual == null) return null;
    try {
      return estados.firstWhere((e) => e.nome == estadoAtual);
    } catch (_) {
      return null;
    }
  }

  bool get emEstadoFinalAtual {
    final obj = estadoAtualObj;
    return obj?.finalState ?? false;
  }

  Transicao? _buscarTransicao(String estado, String simbolo) {
    try {
      return transicoes.firstWhere(
        (t) => t.origem == estado && t.simboloLido == simbolo,
      );
    } catch (_) {
      return null;
    }
  }

  ResultadoPasso executarPasso() {
    if (estadoAtual == null) {
      return ResultadoPasso(
        tipo: ResultadoExecucao.semTransicao,
        simboloLido: fita.ler(),
        simboloEscrito: fita.ler(),
        estadoAnterior: '',
        estadoAtual: '',
        posicaoAnterior: fita.posicao,
        posicaoAtual: fita.posicao,
      );
    }

    if (emEstadoFinalAtual) {
      emEstadoFinal = true;
      return ResultadoPasso(
        tipo: ResultadoExecucao.estadoFinal,
        simboloLido: fita.ler(),
        simboloEscrito: fita.ler(),
        estadoAnterior: estadoAtual!,
        estadoAtual: estadoAtual!,
        posicaoAnterior: fita.posicao,
        posicaoAtual: fita.posicao,
      );
    }

    final simboloLido = fita.ler();
    final transicao = _buscarTransicao(estadoAtual!, simboloLido);

    if (transicao == null) {
      return ResultadoPasso(
        tipo: ResultadoExecucao.semTransicao,
        simboloLido: simboloLido,
        simboloEscrito: simboloLido,
        estadoAnterior: estadoAtual!,
        estadoAtual: estadoAtual!,
        posicaoAnterior: fita.posicao,
        posicaoAtual: fita.posicao,
      );
    }

    final estadoAnterior = estadoAtual!;
    final posicaoAnterior = fita.posicao;

    fita.escrever(transicao.simboloEscrito);

    final mov = transicao.movimento.toUpperCase();
    if (mov == 'L') {
      fita.moverEsquerda();
    } else if (mov == 'R') {
      fita.moverDireita();
    }

    estadoAtual = transicao.destino;
    ultimaTransicao = transicao;
    emEstadoFinal = emEstadoFinalAtual;

    return ResultadoPasso(
      tipo: emEstadoFinal ? ResultadoExecucao.estadoFinal : ResultadoExecucao.sucesso,
      transicao: transicao,
      simboloLido: simboloLido,
      simboloEscrito: transicao.simboloEscrito,
      estadoAnterior: estadoAnterior,
      estadoAtual: estadoAtual!,
      posicaoAnterior: posicaoAnterior,
      posicaoAtual: fita.posicao,
    );
  }

  List<ResultadoPasso> executarCompleto({int limite = 10000}) {
    final passos = <ResultadoPasso>[];
    for (var i = 0; i < limite; i++) {
      final resultado = executarPasso();
      passos.add(resultado);
      if (resultado.tipo != ResultadoExecucao.sucesso) break;
    }
    if (passos.isNotEmpty &&
        passos.last.tipo == ResultadoExecucao.sucesso &&
        passos.length >= limite) {
      passos.add(ResultadoPasso(
        tipo: ResultadoExecucao.limiteExcedido,
        simboloLido: fita.ler(),
        simboloEscrito: fita.ler(),
        estadoAnterior: estadoAtual ?? '',
        estadoAtual: estadoAtual ?? '',
        posicaoAnterior: fita.posicao,
        posicaoAtual: fita.posicao,
      ));
    }
    return passos;
  }

  void resetar() {
    fita.carregarEntrada(entradaInicial);
    _inicializarEstado();
  }

  MaquinaTuring copia() {
    return MaquinaTuring(
      estados: estados.map((e) => e.copyWith()).toList(),
      transicoes: transicoes.map((t) => t.copyWith()).toList(),
      simboloBranco: simboloBranco,
      entradaInicial: entradaInicial,
      fita: fita.copia(),
    )..estadoAtual = estadoAtual;
  }
}
