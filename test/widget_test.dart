import 'package:flutter_test/flutter_test.dart';
import 'package:simulador_maquina_de_turing/core/estado.dart';
import 'package:simulador_maquina_de_turing/core/fita.dart';
import 'package:simulador_maquina_de_turing/core/grupo_transicao.dart';
import 'package:simulador_maquina_de_turing/core/maquina_turing.dart';
import 'package:simulador_maquina_de_turing/core/transicao.dart';

void main() {
  group('Fita', () {
    test('simula fita infinita com símbolo branco', () {
      final fita = Fita();
      expect(fita.ler(), '_');
      fita.escrever('1');
      expect(fita.ler(), '1');
      fita.moverDireita();
      expect(fita.ler(), '_');
      fita.moverEsquerda();
      expect(fita.ler(), '1');
    });
  });

  group('MaquinaTuring', () {
    test('executa um passo corretamente', () {
      final maquina = MaquinaTuring(
        estados: [
          Estado(nome: 'q0', inicial: true),
          Estado(nome: 'q1'),
        ],
        transicoes: [
          Transicao(
            origem: 'q0',
            destino: 'q1',
            simboloLido: '1',
            simboloEscrito: '0',
            movimento: 'R',
          ),
        ],
        entradaInicial: '1',
      );
      maquina.resetar();

      final passo = maquina.executarPasso();
      expect(passo.tipo, ResultadoExecucao.sucesso);
      expect(passo.simboloLido, '1');
      expect(passo.simboloEscrito, '0');
      expect(maquina.estadoAtual, 'q1');
      expect(maquina.fita.posicao, 1);
    });

    test('detecta estado final', () {
      final maquina = MaquinaTuring(
        estados: [
          Estado(nome: 'q0', inicial: true, finalState: true),
        ],
        entradaInicial: '0',
      );
      maquina.resetar();

      final passo = maquina.executarPasso();
      expect(passo.tipo, ResultadoExecucao.estadoFinal);
    });
  });

  group('GrupoTransicao', () {
    test('agrupa transições com mesma origem e destino', () {
      final transicoes = [
        Transicao(origem: 'q0', destino: 'q1', simboloLido: '1', simboloEscrito: 'X', movimento: 'R'),
        Transicao(origem: 'q0', destino: 'q1', simboloLido: '0', simboloEscrito: 'Y', movimento: 'R'),
        Transicao(origem: 'q0', destino: 'q2', simboloLido: '1', simboloEscrito: '1', movimento: 'L'),
      ];

      final grupos = agruparTransicoes(transicoes);

      expect(grupos.length, 2);
      final q0q1 = grupos.firstWhere((g) => g.destino == 'q1');
      expect(q0q1.rotulos, ['0/Y,R', '1/X,R']);
    });
  });
}
