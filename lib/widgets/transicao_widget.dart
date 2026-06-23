import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/estado.dart';
import '../core/grupo_transicao.dart';
import '../core/transicao.dart';
import 'estado_widget.dart';

class TransicaoWidget extends StatelessWidget {
  final GrupoTransicao grupo;
  final List<Estado> estados;
  final bool ativa;
  final bool selecionada;
  final Transicao? transicaoAtiva;
  final VoidCallback? onTap;

  const TransicaoWidget({
    super.key,
    required this.grupo,
    required this.estados,
    this.ativa = false,
    this.selecionada = false,
    this.transicaoAtiva,
    this.onTap,
  });

  Estado? _estado(String nome) {
    try {
      return estados.firstWhere((e) => e.nome == nome);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final origem = _estado(grupo.origem);
    final destino = _estado(grupo.destino);
    if (origem == null || destino == null) return const SizedBox.shrink();

    final cor = ativa
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.outline;

    return IgnorePointer(
      child: CustomPaint(
        painter: TransicaoPainter(
          origem: Offset(origem.x, origem.y),
          destino: Offset(destino.x, destino.y),
          rotulos: grupo.rotulos,
          ativa: ativa,
          selecionada: selecionada,
          cor: cor,
          rotuloAtivo: transicaoAtiva?.rotulo,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// Seta temporária enquanto o usuário arrasta de um estado para outro.
class TransicaoPendentePainter extends CustomPainter {
  final Offset origem;
  final Offset destino;
  final Color cor;

  TransicaoPendentePainter({
    required this.origem,
    required this.destino,
    this.cor = const Color(0xFFFFB74D),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inicio = pontoBordaEstado(origem, destino);
    final dx = destino.dx - inicio.dx;
    final dy = destino.dy - inicio.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 2) return;

    final paint = Paint()
      ..color = cor.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final mid = Offset((inicio.dx + destino.dx) / 2, (inicio.dy + destino.dy) / 2);
    final perpLen = math.min(dist * 0.15, 30.0);
    final perpX = -dy / dist * perpLen;
    final perpY = dx / dist * perpLen;
    final control = Offset(mid.dx + perpX, mid.dy + perpY);

    final path = Path()
      ..moveTo(inicio.dx, inicio.dy)
      ..quadraticBezierTo(control.dx, control.dy, destino.dx, destino.dy);

    canvas.drawPath(path, paint);

    final angle = math.atan2(destino.dy - control.dy, destino.dx - control.dx);
    const arrowSize = 13.0;

    final arrowPath = Path()
      ..moveTo(destino.dx, destino.dy)
      ..lineTo(
        destino.dx - arrowSize * math.cos(angle - 0.42),
        destino.dy - arrowSize * math.sin(angle - 0.42),
      )
      ..lineTo(
        destino.dx - arrowSize * math.cos(angle + 0.42),
        destino.dy - arrowSize * math.sin(angle + 0.42),
      )
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = cor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    canvas.drawCircle(
      destino,
      5,
      Paint()
        ..color = cor.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant TransicaoPendentePainter oldDelegate) =>
      oldDelegate.origem != origem ||
      oldDelegate.destino != destino ||
      oldDelegate.cor != cor;
}
