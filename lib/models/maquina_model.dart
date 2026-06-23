import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/estado.dart';
import '../core/maquina_turing.dart';
import '../core/transicao.dart';

class MaquinaModel extends ChangeNotifier {
  MaquinaTuring maquina;
  String? estadoSelecionado;
  Transicao? transicaoSelecionada;
  String? origemTransicaoPendente;

  bool executando = false;
  double velocidadeMs = 500;
  String mensagemStatus = 'Pronto';
  Timer? _timerExecucao;

  MaquinaModel({MaquinaTuring? maquina})
      : maquina = maquina ?? MaquinaTuring();

  // --- Estados ---

  void adicionarEstado(double x, double y) {
    final nome = _proximoNomeEstado();
    maquina.estados.add(Estado(
      nome: nome,
      x: x,
      y: y,
      inicial: maquina.estados.isEmpty,
    ));
    notifyListeners();
  }

  String _proximoNomeEstado() {
    var i = maquina.estados.length;
    while (maquina.estados.any((e) => e.nome == 'q$i')) {
      i++;
    }
    return 'q$i';
  }

  void moverEstado(String nome, double x, double y) {
    final idx = maquina.estados.indexWhere((e) => e.nome == nome);
    if (idx >= 0) {
      maquina.estados[idx].x = x;
      maquina.estados[idx].y = y;
      notifyListeners();
    }
  }

  void atualizarEstado(Estado estado) {
    final idx = maquina.estados.indexWhere((e) => e.nome == estado.nome);
    if (idx < 0) return;

    if (estado.inicial) {
      for (final e in maquina.estados) {
        e.inicial = false;
      }
    }

    final nomeAntigo = maquina.estados[idx].nome;
    maquina.estados[idx] = estado;

    if (nomeAntigo != estado.nome) {
      for (final t in maquina.transicoes) {
        if (t.origem == nomeAntigo) t.origem = estado.nome;
        if (t.destino == nomeAntigo) t.destino = estado.nome;
      }
      if (estadoSelecionado == nomeAntigo) estadoSelecionado = estado.nome;
      if (maquina.estadoAtual == nomeAntigo) maquina.estadoAtual = estado.nome;
    }

    notifyListeners();
  }

  void removerEstado(String nome) {
    maquina.estados.removeWhere((e) => e.nome == nome);
    maquina.transicoes.removeWhere((t) => t.origem == nome || t.destino == nome);
    if (estadoSelecionado == nome) estadoSelecionado = null;
    if (maquina.estadoAtual == nome) maquina.estadoAtual = null;
    notifyListeners();
  }

  void selecionarEstado(String? nome) {
    estadoSelecionado = nome;
    transicaoSelecionada = null;
    notifyListeners();
  }

  // --- Transições ---

  void iniciarTransicao(String origem) {
    origemTransicaoPendente = origem;
    notifyListeners();
  }

  void cancelarTransicaoPendente() {
    origemTransicaoPendente = null;
    notifyListeners();
  }

  void adicionarTransicao(Transicao transicao) {
    maquina.transicoes.removeWhere(
      (t) =>
          t.origem == transicao.origem &&
          t.simboloLido == transicao.simboloLido,
    );
    maquina.transicoes.add(transicao);
    origemTransicaoPendente = null;
    notifyListeners();
  }

  void removerTransicao(Transicao transicao) {
    maquina.transicoes.remove(transicao);
    if (transicaoSelecionada == transicao) transicaoSelecionada = null;
    notifyListeners();
  }

  void selecionarTransicao(Transicao? transicao) {
    transicaoSelecionada = transicao;
    estadoSelecionado = null;
    notifyListeners();
  }

  // --- Simulação ---

  void definirEntrada(String entrada) {
    maquina.entradaInicial = entrada;
    maquina.resetar();
    mensagemStatus = 'Entrada: "$entrada"';
    notifyListeners();
  }

  void definirSimboloBranco(String simbolo) {
    final s = simbolo.isEmpty ? '_' : simbolo[0];
    maquina.simboloBranco = s;
    maquina.fita = maquina.fita.comSimboloBranco(s);
    notifyListeners();
  }

  ResultadoPasso? proximoPasso() {
    pararExecucao();
    final resultado = maquina.executarPasso();
    _atualizarMensagem(resultado);
    notifyListeners();
    return resultado;
  }

  void executar() {
    if (executando) {
      pararExecucao();
      return;
    }
    executando = true;
    mensagemStatus = 'Executando...';
    notifyListeners();
    _timerExecucao = Timer.periodic(
      Duration(milliseconds: velocidadeMs.round()),
      (_) {
        final resultado = maquina.executarPasso();
        _atualizarMensagem(resultado);
        if (resultado.tipo != ResultadoExecucao.sucesso) {
          pararExecucao();
        } else {
          notifyListeners();
        }
      },
    );
  }

  void pararExecucao() {
    _timerExecucao?.cancel();
    _timerExecucao = null;
    if (!executando) return;
    executando = false;
    notifyListeners();
  }

  void resetar() {
    pararExecucao();
    maquina.resetar();
    mensagemStatus = 'Máquina resetada';
    notifyListeners();
  }

  void definirVelocidade(double ms) {
    velocidadeMs = ms;
    if (executando) {
      pararExecucao();
      executar();
    }
    notifyListeners();
  }

  void _atualizarMensagem(ResultadoPasso resultado) {
    switch (resultado.tipo) {
      case ResultadoExecucao.sucesso:
        mensagemStatus =
            'δ(${resultado.estadoAnterior}, ${resultado.simboloLido}) → '
            '(${resultado.simboloEscrito}, ${resultado.transicao?.movimento}, ${resultado.estadoAtual})';
      case ResultadoExecucao.estadoFinal:
        mensagemStatus = 'Estado final alcançado: ${resultado.estadoAtual}';
      case ResultadoExecucao.semTransicao:
        mensagemStatus =
            'Sem transição para (${resultado.estadoAnterior}, ${resultado.simboloLido})';
      case ResultadoExecucao.limiteExcedido:
        mensagemStatus = 'Limite de passos excedido';
    }
  }

  void carregarMaquina(MaquinaTuring nova) {
    pararExecucao();
    maquina = nova;
    estadoSelecionado = null;
    transicaoSelecionada = null;
    origemTransicaoPendente = null;
    mensagemStatus = 'Máquina carregada';
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'estados': maquina.estados.map((e) => e.toJson()).toList(),
        'transicoes': maquina.transicoes.map((t) => t.toJson()).toList(),
        'simboloBranco': maquina.simboloBranco,
        'entradaInicial': maquina.entradaInicial,
      };

  void fromJson(Map<String, dynamic> json) {
    final estados = (json['estados'] as List)
        .map((e) => Estado.fromJson(e as Map<String, dynamic>))
        .toList();
    final transicoes = (json['transicoes'] as List)
        .map((t) => Transicao.fromJson(t as Map<String, dynamic>))
        .toList();

    carregarMaquina(MaquinaTuring(
      estados: estados,
      transicoes: transicoes,
      simboloBranco: json['simboloBranco'] as String? ?? '_',
      entradaInicial: json['entradaInicial'] as String? ?? '',
    ));
  }

  static MaquinaModel exemploIncrementoBinario() {
    final model = MaquinaModel();
    model.maquina.estados.addAll([
      Estado(nome: 'q0', x: 120, y: 200, inicial: true),
      Estado(nome: 'q1', x: 320, y: 120),
      Estado(nome: 'q2', x: 520, y: 200, finalState: true),
    ]);
    model.maquina.transicoes.addAll([
      Transicao(origem: 'q0', destino: 'q0', simboloLido: '0', simboloEscrito: '0', movimento: 'R'),
      Transicao(origem: 'q0', destino: 'q1', simboloLido: '1', simboloEscrito: '1', movimento: 'R'),
      Transicao(origem: 'q0', destino: 'q2', simboloLido: '_', simboloEscrito: '_', movimento: 'L'),
      Transicao(origem: 'q1', destino: 'q1', simboloLido: '0', simboloEscrito: '0', movimento: 'R'),
      Transicao(origem: 'q1', destino: 'q1', simboloLido: '1', simboloEscrito: '1', movimento: 'R'),
      Transicao(origem: 'q1', destino: 'q0', simboloLido: '_', simboloEscrito: '1', movimento: 'L'),
    ]);
    model.maquina.entradaInicial = '101';
    model.maquina.resetar();
    return model;
  }

  @override
  void dispose() {
    pararExecucao();
    super.dispose();
  }
}
