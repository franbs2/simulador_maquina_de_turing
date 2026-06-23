import 'package:flutter/material.dart';

import '../models/maquina_model.dart';
import '../widgets/fita_widget.dart';

class SimulacaoScreen extends StatelessWidget {
  final MaquinaModel model;

  const SimulacaoScreen({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FitaWidget(
            fita: model.maquina.fita,
            simboloBranco: model.maquina.simboloBranco,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.radio_button_checked, size: 14, color: theme.colorScheme.secondary),
              const SizedBox(width: 6),
              Text(
                'Estado atual: ',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
              Text(
                model.maquina.estadoAtual ?? '—',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  model.mensagemStatus,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.outline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: model.executando ? model.pararExecucao : model.executar,
                icon: Icon(model.executando ? Icons.pause : Icons.play_arrow),
                label: Text(model.executando ? 'Pausar' : 'Executar'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: model.proximoPasso,
                icon: const Icon(Icons.skip_next),
                label: const Text('Próximo passo'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: model.resetar,
                icon: const Icon(Icons.refresh),
                label: const Text('Resetar'),
              ),
              const Spacer(),
              Icon(Icons.speed, size: 18, color: theme.colorScheme.outline),
              const SizedBox(width: 8),
              SizedBox(
                width: 160,
                child: Slider(
                  value: model.velocidadeMs,
                  min: 50,
                  max: 2000,
                  divisions: 39,
                  label: '${model.velocidadeMs.round()} ms',
                  onChanged: model.definirVelocidade,
                ),
              ),
              Text(
                '${model.velocidadeMs.round()} ms',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
