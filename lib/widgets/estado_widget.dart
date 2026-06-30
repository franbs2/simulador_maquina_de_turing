import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/estado.dart';

const double kRaioEstado = 36;
const double kAlturaLoopAuto = 52.0;
const double _anguloInicioLoopAuto = 5 * math.pi / 6; // 150° — borda superior esquerda
const double _anguloFimLoopAuto = math.pi / 6; // 30° — borda superior direita

/// Laço de autotransição curvado acima do estado (nunca passa pelo interior).
({Offset inicio, Offset fim, Offset controle1, Offset controle2}) geometriaAutoTransicao(
  Offset centro,
) {
  final inicio = Offset(
    centro.dx + math.cos(_anguloInicioLoopAuto) * kRaioEstado,
    centro.dy + math.sin(_anguloInicioLoopAuto) * kRaioEstado,
  );
  final fim = Offset(
    centro.dx + math.cos(_anguloFimLoopAuto) * kRaioEstado,
    centro.dy + math.sin(_anguloFimLoopAuto) * kRaioEstado,
  );
  final abertura = kRaioEstado * 1.1;
  final topo = centro.dy - kRaioEstado - kAlturaLoopAuto;
  final controle1 = Offset(centro.dx - abertura, topo);
  final controle2 = Offset(centro.dx + abertura, topo);
  return (inicio: inicio, fim: fim, controle1: controle1, controle2: controle2);
}

Path pathAutoTransicao(Offset centro) {
  final g = geometriaAutoTransicao(centro);
  return Path()
    ..moveTo(g.inicio.dx, g.inicio.dy)
    ..cubicTo(
      g.controle1.dx,
      g.controle1.dy,
      g.controle2.dx,
      g.controle2.dy,
      g.fim.dx,
      g.fim.dy,
    );
}

Offset pontoBezierCubica(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  final u = 1 - t;
  return Offset(
    u * u * u * p0.dx + 3 * u * u * t * p1.dx + 3 * u * t * t * p2.dx + t * t * t * p3.dx,
    u * u * u * p0.dy + 3 * u * u * t * p1.dy + 3 * u * t * t * p2.dy + t * t * t * p3.dy,
  );
}

class EstadoWidget extends StatefulWidget {
  final Estado estado;
  final bool selecionado;
  final bool ativo;
  final bool origemPendente;
  final bool destinoHover;
  final bool modoTransicao;
  final VoidCallback? onTap;
  final void Function(double x, double y)? onArrastar;

  const EstadoWidget({
    super.key,
    required this.estado,
    this.selecionado = false,
    this.ativo = false,
    this.origemPendente = false,
    this.destinoHover = false,
    this.modoTransicao = false,
    this.onTap,
    this.onArrastar,
  });

  @override
  State<EstadoWidget> createState() => _EstadoWidgetState();
}

class _EstadoWidgetState extends State<EstadoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Offset? _dragOffset;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.ativo) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(EstadoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ativo && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.ativo && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _rotulo {
    final n = widget.estado.nome;
    if (widget.estado.finalState) return '(($n))';
    return '($n)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corBase = widget.estado.finalState
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;
    var cor = corBase;
    if (widget.origemPendente) {
      cor = theme.colorScheme.secondary;
    } else if (widget.destinoHover) {
      cor = theme.colorScheme.tertiary;
    }

    return Positioned(
      left: widget.estado.x - kRaioEstado + (_dragOffset?.dx ?? 0),
      top: widget.estado.y - kRaioEstado + (_dragOffset?.dy ?? 0),
      child: IgnorePointer(
        ignoring: widget.modoTransicao,
        child: MouseRegion(
          cursor: widget.modoTransicao ? SystemMouseCursors.cell : SystemMouseCursors.grab,
          child: GestureDetector(
            onTap: widget.onTap,
            onPanStart: widget.onArrastar != null ? (_) => _dragOffset = Offset.zero : null,
            onPanUpdate: widget.onArrastar != null
                ? (d) => setState(() => _dragOffset = (_dragOffset ?? Offset.zero) + d.delta)
                : null,
            onPanEnd: widget.onArrastar != null
                ? (_) {
                    if (_dragOffset != null) {
                      widget.onArrastar!(
                        widget.estado.x + _dragOffset!.dx,
                        widget.estado.y + _dragOffset!.dy,
                      );
                    }
                    setState(() => _dragOffset = null);
                  }
                : null,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final glow = widget.ativo ? 8 + _pulseController.value * 12 : 0.0;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  width: kRaioEstado * 2,
                  height: kRaioEstado * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cor.withValues(alpha: widget.ativo ? 0.25 : 0.12),
                    border: Border.all(
                      color: widget.destinoHover
                          ? theme.colorScheme.tertiary
                          : (widget.selecionado ? Colors.white : cor),
                      width: widget.destinoHover
                          ? 3.5
                          : (widget.selecionado ? 3 : (widget.ativo ? 2.5 : 2)),
                    ),
                    boxShadow: [
                      if (widget.modoTransicao && !widget.origemPendente)
                        BoxShadow(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                          blurRadius: 6,
                        ),
                      if (widget.destinoHover)
                        BoxShadow(
                          color: theme.colorScheme.tertiary.withValues(alpha: 0.45),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      if (widget.ativo || widget.selecionado || widget.origemPendente)
                        BoxShadow(
                          color: cor.withValues(
                            alpha: 0.4 + _pulseController.value * 0.3,
                          ),
                          blurRadius: glow,
                          spreadRadius: widget.ativo ? 2 : 0,
                        ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Text(
                  _rotulo,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Desenha uma seta curva entre dois estados.
class TransicaoPainter extends CustomPainter {
  final Offset origem;
  final Offset destino;
  final List<String> rotulos;
  final bool ativa;
  final bool selecionada;
  final Color cor;
  final String? rotuloAtivo;

  TransicaoPainter({
    required this.origem,
    required this.destino,
    required this.rotulos,
    this.ativa = false,
    this.selecionada = false,
    required this.cor,
    this.rotuloAtivo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dx = destino.dx - origem.dx;
    final dy = destino.dy - origem.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    final paint = Paint()
      ..color = ativa ? cor : cor.withValues(alpha: selecionada ? 0.9 : 0.55)
      ..strokeWidth = ativa ? 3 : (selecionada ? 2.5 : 1.8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (dist < 1) {
      _paintAutoTransicao(canvas, origem, paint);
      return;
    }

    final ux = dx / dist;
    final uy = dy / dist;

    final start = Offset(
      origem.dx + ux * kRaioEstado,
      origem.dy + uy * kRaioEstado,
    );
    final end = Offset(
      destino.dx - ux * kRaioEstado,
      destino.dy - uy * kRaioEstado,
    );

    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final perpX = -uy * 40;
    final perpY = ux * 40;
    final control = Offset(mid.dx + perpX, mid.dy + perpY);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    canvas.drawPath(path, paint);
    _desenharSeta(canvas, start, control, end, paint.color);
    _desenharRotulos(canvas, _pointOnQuad(start, control, end, 0.5));
  }

  void _paintAutoTransicao(Canvas canvas, Offset centro, Paint paint) {
    final g = geometriaAutoTransicao(centro);
    canvas.drawPath(pathAutoTransicao(centro), paint);
    _desenharSetaCubica(canvas, g.inicio, g.controle1, g.controle2, g.fim, paint.color);
    _desenharRotulos(
      canvas,
      pontoBezierCubica(g.inicio, g.controle1, g.controle2, g.fim, 0.5),
    );
  }

  void _desenharSetaCubica(
    Canvas canvas,
    Offset start,
    Offset c1,
    Offset c2,
    Offset end,
    Color cor,
  ) {
    const t = 0.98;
    final arrowTip = pontoBezierCubica(start, c1, c2, end, t);
    final arrowBase = pontoBezierCubica(start, c1, c2, end, t - 0.04);
    final angle = math.atan2(arrowTip.dy - arrowBase.dy, arrowTip.dx - arrowBase.dx);
    const arrowSize = 12.0;

    final arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(
        arrowTip.dx - arrowSize * math.cos(angle - 0.4),
        arrowTip.dy - arrowSize * math.sin(angle - 0.4),
      )
      ..lineTo(
        arrowTip.dx - arrowSize * math.cos(angle + 0.4),
        arrowTip.dy - arrowSize * math.sin(angle + 0.4),
      )
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = cor
        ..style = PaintingStyle.fill,
    );
  }

  void _desenharSeta(Canvas canvas, Offset start, Offset control, Offset end, Color cor) {
    const t = 0.98;
    final arrowTip = _pointOnQuad(start, control, end, t);
    final arrowBase = _pointOnQuad(start, control, end, t - 0.04);
    final angle = math.atan2(arrowTip.dy - arrowBase.dy, arrowTip.dx - arrowBase.dx);
    const arrowSize = 12.0;

    final arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(
        arrowTip.dx - arrowSize * math.cos(angle - 0.4),
        arrowTip.dy - arrowSize * math.sin(angle - 0.4),
      )
      ..lineTo(
        arrowTip.dx - arrowSize * math.cos(angle + 0.4),
        arrowTip.dy - arrowSize * math.sin(angle + 0.4),
      )
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = cor
        ..style = PaintingStyle.fill,
    );
  }

  void _desenharRotulos(Canvas canvas, Offset labelPos) {
    if (rotulos.isEmpty) return;

    const fontSize = 11.0;
    const lineHeight = 14.0;
    const padding = 4.0;
    const bgColor = Color(0xFF1A1D2E);

    final painters = <TextPainter>[];
    var maxWidth = 0.0;

    for (final rotulo in rotulos) {
      final destacado = rotulo == rotuloAtivo;
      final tp = TextPainter(
        text: TextSpan(
          text: rotulo,
          style: TextStyle(
            color: destacado ? cor : cor.withValues(alpha: ativa ? 1 : 0.88),
            fontSize: fontSize,
            fontWeight: destacado ? FontWeight.bold : FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painters.add(tp);
      if (tp.width > maxWidth) maxWidth = tp.width;
    }

    final totalHeight = painters.length * lineHeight;
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: labelPos,
        width: maxWidth + padding * 2,
        height: totalHeight + padding * 2,
      ),
      const Radius.circular(4),
    );

    canvas.drawRRect(
      boxRect,
      Paint()..color = bgColor.withValues(alpha: 0.92),
    );

    var y = labelPos.dy - totalHeight / 2 + padding / 2;
    for (final tp in painters) {
      tp.paint(canvas, Offset(labelPos.dx - tp.width / 2, y));
      y += lineHeight;
    }
  }

  Offset _pointOnQuad(Offset p0, Offset p1, Offset p2, double t) {
    final x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
    final y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant TransicaoPainter oldDelegate) =>
      oldDelegate.ativa != ativa ||
      oldDelegate.selecionada != selecionada ||
      oldDelegate.rotulos != rotulos ||
      oldDelegate.rotuloAtivo != rotuloAtivo;
}

/// Ponto na borda do círculo do estado em direção ao destino.
Offset pontoBordaEstado(Offset centro, Offset destino, [double raio = kRaioEstado]) {
  final d = destino - centro;
  final dist = d.distance;
  if (dist < 1) return centro;
  return centro + Offset(d.dx / dist * raio, d.dy / dist * raio);
}
