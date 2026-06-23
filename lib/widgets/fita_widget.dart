import 'package:flutter/material.dart';

import '../core/fita.dart';

class FitaWidget extends StatelessWidget {
  final Fita fita;
  final String simboloBranco;

  const FitaWidget({
    super.key,
    required this.fita,
    this.simboloBranco = '_',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final celulas = fita.celulasVisiveis(raio: 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fita',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.outline,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in celulas) ...[
                _CelulaFita(
                  indice: entry.key,
                  simbolo: entry.value,
                  cabecote: entry.key == fita.posicao,
                  simboloBranco: simboloBranco,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        _IndicadorCabecote(fita: fita, celulas: celulas),
      ],
    );
  }
}

class _CelulaFita extends StatelessWidget {
  final int indice;
  final String simbolo;
  final bool cabecote;
  final String simboloBranco;

  const _CelulaFita({
    required this.indice,
    required this.simbolo,
    required this.cabecote,
    required this.simboloBranco,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exibir = simbolo == simboloBranco ? simboloBranco : simbolo;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: cabecote
            ? theme.colorScheme.secondary.withValues(alpha: 0.2)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cabecote
              ? theme.colorScheme.secondary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: cabecote ? 2 : 1,
        ),
        boxShadow: cabecote
            ? [
                BoxShadow(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            exibir,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: cabecote
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.onSurface,
            ),
          ),
          Text(
            '$indice',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicadorCabecote extends StatelessWidget {
  final Fita fita;
  final List<MapEntry<int, String>> celulas;

  const _IndicadorCabecote({required this.fita, required this.celulas});

  @override
  Widget build(BuildContext context) {
    if (celulas.isEmpty) return const SizedBox.shrink();

    final idx = celulas.indexWhere((c) => c.key == fita.posicao);
    if (idx < 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final offset = idx * 48.0 + 22;

    return SizedBox(
      height: 20,
      child: Stack(
        children: [
          Positioned(
            left: offset - 6,
            child: Icon(
              Icons.arrow_drop_up,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
