import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/estado.dart';
import '../core/grupo_transicao.dart';
import '../core/transicao.dart';
import '../models/maquina_model.dart';
import '../services/arquivo_service.dart';
import '../widgets/estado_widget.dart';
import '../widgets/transicao_widget.dart';
import 'simulacao_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  int _abaLateral = 0;
  bool _painelExpandido = true;
  final _canvasKey = GlobalKey();
  final _entradaController = TextEditingController();
  final _simboloBrancoController = TextEditingController(text: '_');
  bool _modoAdicionarEstado = false;
  bool _modoTransicao = false;
  String? _transicaoDestinoHover;
  final _posicaoArraste = ValueNotifier<Offset?>(null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final model = context.read<MaquinaModel>();
      _entradaController.text = model.maquina.entradaInicial;
      _simboloBrancoController.text = model.maquina.simboloBranco;
    });
  }

  @override
  void dispose() {
    _entradaController.dispose();
    _simboloBrancoController.dispose();
    _posicaoArraste.dispose();
    super.dispose();
  }

  Future<void> _salvar(BuildContext context) async {
    final model = context.read<MaquinaModel>();
    final resultado = await ArquivoService.salvar(model);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    switch (resultado.tipo) {
      case ResultadoArquivo.sucesso:
        messenger.showSnackBar(
          SnackBar(content: Text('Máquina salva em ${resultado.caminho}')),
        );
      case ResultadoArquivo.cancelado:
        break;
      case ResultadoArquivo.erro:
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: ${resultado.erro ?? 'desconhecido'}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    }
  }

  Future<void> _carregar(BuildContext context) async {
    final maquina = await ArquivoService.carregar();
    if (maquina != null && context.mounted) {
      context.read<MaquinaModel>().carregarMaquina(maquina);
      _entradaController.text = maquina.entradaInicial;
      _simboloBrancoController.text = maquina.simboloBranco;
    }
  }

  Future<void> _dialogTransicao(
    BuildContext context,
    MaquinaModel model,
    String origem,
    String destino,
  ) async {
    final existentes = transicoesNaAresta(model.maquina.transicoes, origem, destino);
    final lerController = TextEditingController(text: '0');
    final escreverController = TextEditingController(text: '0');
    var movimento = 'R';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Nova Transição'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$origem → $destino', style: const TextStyle(fontFamily: 'monospace')),
                if (existentes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Já nesta seta:',
                    style: Theme.of(ctx).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      existentes.map((t) => t.rotulo).join('\n'),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cada símbolo lido diferente vira uma linha na mesma seta.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.outline,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: lerController,
                  decoration: const InputDecoration(
                    labelText: 'Símbolo lido',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 1,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: escreverController,
                  decoration: const InputDecoration(
                    labelText: 'Símbolo escrito',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 1,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: movimento,
                  decoration: const InputDecoration(
                    labelText: 'Movimento',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'L', child: Text('Esquerda (L)')),
                    DropdownMenuItem(value: 'R', child: Text('Direita (R)')),
                  ],
                  onChanged: (v) => setDialogState(() => movimento = v ?? 'R'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Criar')),
            ],
          ),
        );
      },
    );

    if (confirmado == true) {
      model.adicionarTransicao(Transicao(
        origem: origem,
        destino: destino,
        simboloLido: lerController.text.isEmpty ? '_' : lerController.text,
        simboloEscrito: escreverController.text.isEmpty ? '_' : escreverController.text,
        movimento: movimento,
      ));
    }

    lerController.dispose();
    escreverController.dispose();
    _cancelarArrasteTransicao(model);
  }

  void _atualizarArrasteTransicao(MaquinaModel model, Offset pos) {
    _posicaoArraste.value = pos;
    var hover = _estadoEmPosicao(pos, model);
    if (hover == model.origemTransicaoPendente) hover = null;
    if (hover != _transicaoDestinoHover) {
      setState(() => _transicaoDestinoHover = hover);
    }
  }

  void _cancelarArrasteTransicao(MaquinaModel model) {
    model.cancelarTransicaoPendente();
    _posicaoArraste.value = null;
    if (_transicaoDestinoHover != null) {
      setState(() => _transicaoDestinoHover = null);
    }
  }

  Offset? _globalParaCanvas(Offset global) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.globalToLocal(global);
  }

  String? _estadoEmPosicao(Offset pos, MaquinaModel model) {
    for (final e in model.maquina.estados) {
      if ((pos - Offset(e.x, e.y)).distance <= kRaioEstado) return e.nome;
    }
    return null;
  }

  void _criarEstadoDuploClique(MaquinaModel model, double x, double y) {
    model.adicionarEstado(x, y);
    setState(() => _modoAdicionarEstado = false);
  }

  void _criarEstadoComConfig(MaquinaModel model, double x, double y) {
    model.adicionarEstado(x, y);
    final novo = model.maquina.estados.last;
    _editarEstado(context, model, novo);
    setState(() => _modoAdicionarEstado = false);
  }

  void _iniciarArrasteTransicao(MaquinaModel model, String origem, Offset pos) {
    if (!_modoTransicao) return;
    model.iniciarTransicao(origem);
    _posicaoArraste.value = pos;
    if (_transicaoDestinoHover != null) {
      setState(() => _transicaoDestinoHover = null);
    }
  }

  void _finalizarArrasteTransicao(BuildContext context, MaquinaModel model, Offset pos) {
    if (pos.dx < 0) {
      _cancelarArrasteTransicao(model);
      return;
    }

    final origem = model.origemTransicaoPendente;
    final destino = _estadoEmPosicao(pos, model);

    if (origem != null && destino != null && origem != destino) {
      _dialogTransicao(context, model, origem, destino);
    } else {
      _cancelarArrasteTransicao(model);
      if (origem != null && destino == null && _modoTransicao) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solte sobre outro estado para configurar a transição'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _editarEstado(BuildContext context, MaquinaModel model, Estado estado) {
    final nomeController = TextEditingController(text: estado.nome);
    var inicial = estado.inicial;
    var finalState = estado.finalState;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar Estado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                title: const Text('Estado inicial'),
                value: inicial,
                onChanged: (v) => setDialogState(() => inicial = v),
              ),
              SwitchListTile(
                title: const Text('Estado final'),
                value: finalState,
                onChanged: (v) => setDialogState(() => finalState = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                model.removerEstado(estado.nome);
                Navigator.pop(ctx);
              },
              child: Text('Excluir', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                model.atualizarEstado(estado.copyWith(
                  nome: nomeController.text.trim().isEmpty ? estado.nome : nomeController.text.trim(),
                  inicial: inicial,
                  finalState: finalState,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    ).then((_) => nomeController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MaquinaModel>(
      builder: (context, model, _) {
        return Scaffold(
          body: Column(
            children: [
              _BarraSuperior(
                onSalvar: () => _salvar(context),
                onCarregar: () => _carregar(context),
              ),
              Expanded(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: _painelExpandido ? 280 : 0,
                      child: ClipRect(
                        child: _painelExpandido
                            ? _PainelLateral(
                                aba: _abaLateral,
                                onAbaChanged: (i) => setState(() => _abaLateral = i),
                                model: model,
                                entradaController: _entradaController,
                                simboloBrancoController: _simboloBrancoController,
                                onEditarEstado: (e) => _editarEstado(context, model, e),
                                onRecolher: () => setState(() => _painelExpandido = false),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    _BotaoTogglePainel(
                      expandido: _painelExpandido,
                      onToggle: () => setState(() => _painelExpandido = !_painelExpandido),
                    ),
                    Expanded(
                      child: _CanvasAutomato(
                        canvasKey: _canvasKey,
                        model: model,
                        modoAdicionarEstado: _modoAdicionarEstado,
                        modoTransicao: _modoTransicao,
                        posicaoArraste: _posicaoArraste,
                        transicaoDestinoHover: _transicaoDestinoHover,
                        globalParaCanvas: _globalParaCanvas,
                        estadoEmPosicao: (pos) => _estadoEmPosicao(pos, model),
                        onToggleModoAdicionar: () => setState(() {
                          _modoAdicionarEstado = !_modoAdicionarEstado;
                          if (_modoAdicionarEstado) _modoTransicao = false;
                        }),
                        onToggleModoTransicao: () => setState(() {
                          _modoTransicao = !_modoTransicao;
                          if (_modoTransicao) {
                            _modoAdicionarEstado = false;
                          } else {
                            _cancelarArrasteTransicao(model);
                          }
                        }),
                        onTapCanvas: (pos) {
                          if (_modoAdicionarEstado) {
                            _criarEstadoComConfig(model, pos.dx, pos.dy);
                          }
                        },
                        onDoubleTap: (pos) => _criarEstadoDuploClique(model, pos.dx, pos.dy),
                        onIniciarTransicao: (nome, pos) =>
                            _iniciarArrasteTransicao(model, nome, pos),
                        onAtualizarTransicao: (pos) =>
                            _atualizarArrasteTransicao(model, pos),
                        onFinalizarTransicao: (pos) =>
                            _finalizarArrasteTransicao(context, model, pos),
                        onCancelarTransicao: () => _cancelarArrasteTransicao(model),
                      ),
                    ),
                  ],
                ),
              ),
              SimulacaoScreen(model: model),
            ],
          ),
        );
      },
    );
  }
}

class _BarraSuperior extends StatelessWidget {
  final VoidCallback onSalvar;
  final VoidCallback onCarregar;

  const _BarraSuperior({required this.onSalvar, required this.onCarregar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.memory, color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simulador de Máquina de Turing',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Teoria da Computação',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onCarregar,
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Carregar'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onSalvar,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _BotaoTogglePainel extends StatelessWidget {
  final bool expandido;
  final VoidCallback onToggle;

  const _BotaoTogglePainel({required this.expandido, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          width: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              right: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
          ),
          child: Center(
            child: Icon(
              expandido ? Icons.chevron_left : Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }
}

class _PainelLateral extends StatelessWidget {
  final int aba;
  final ValueChanged<int> onAbaChanged;
  final MaquinaModel model;
  final TextEditingController entradaController;
  final TextEditingController simboloBrancoController;
  final void Function(Estado) onEditarEstado;
  final VoidCallback onRecolher;

  const _PainelLateral({
    required this.aba,
    required this.onAbaChanged,
    required this.model,
    required this.entradaController,
    required this.simboloBrancoController,
    required this.onEditarEstado,
    required this.onRecolher,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(
          right: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 4, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _AbaLateral(
                          label: 'Estados',
                          icon: Icons.circle_outlined,
                          selecionada: aba == 0,
                          onTap: () => onAbaChanged(0),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _AbaLateral(
                          label: 'Transições',
                          icon: Icons.arrow_forward,
                          selecionada: aba == 1,
                          onTap: () => onAbaChanged(1),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _AbaLateral(
                          label: 'Configurações',
                          icon: Icons.settings_outlined,
                          selecionada: aba == 2,
                          onTap: () => onAbaChanged(2),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Recolher painel',
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: onRecolher,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (aba) {
              0 => _ListaEstados(model: model, onEditarEstado: onEditarEstado),
              1 => _ListaTransicoes(model: model),
              _ => _Configuracoes(
                  model: model,
                  entradaController: entradaController,
                  simboloBrancoController: simboloBrancoController,
                ),
            },
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Duplo clique no canvas para criar estado.\n'
              'Transição: ative "Transição" e arraste de uma bolinha até outra.\n'
              'Mover: arraste o círculo (modo normal).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AbaLateral extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selecionada;
  final VoidCallback onTap;

  const _AbaLateral({
    required this.label,
    required this.icon,
    required this.selecionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cor = selecionada ? theme.colorScheme.primary : theme.colorScheme.outline;

    return Material(
      color: selecionada
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selecionada
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: cor),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selecionada
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                    fontWeight: selecionada ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListaEstados extends StatelessWidget {
  final MaquinaModel model;
  final void Function(Estado) onEditarEstado;

  const _ListaEstados({required this.model, required this.onEditarEstado});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: model.maquina.estados.length,
      itemBuilder: (context, i) {
        final e = model.maquina.estados[i];
        final ativo = model.maquina.estadoAtual == e.nome;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: model.estadoSelecionado == e.nome
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4)
              : null,
          child: ListTile(
            dense: true,
            leading: Icon(
              e.finalState ? Icons.flag : (e.inicial ? Icons.play_arrow : Icons.circle),
              size: 20,
              color: ativo ? Theme.of(context).colorScheme.secondary : null,
            ),
            title: Text('(${e.nome})', style: const TextStyle(fontFamily: 'monospace')),
            subtitle: Text(
              [
                if (e.inicial) 'inicial',
                if (e.finalState) 'final',
                if (ativo) '● ativo',
              ].join(' · '),
            ),
            onTap: () => model.selecionarEstado(e.nome),
            onLongPress: () => onEditarEstado(e),
            trailing: IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => onEditarEstado(e),
            ),
          ),
        );
      },
    );
  }
}

class _ListaTransicoes extends StatelessWidget {
  final MaquinaModel model;

  const _ListaTransicoes({required this.model});

  @override
  Widget build(BuildContext context) {
    final grupos = agruparTransicoes(model.maquina.transicoes);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: grupos.length,
      itemBuilder: (context, i) {
        final grupo = grupos[i];
        final ativa = grupo.contem(model.maquina.ultimaTransicao);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: ativa
              ? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.4)
              : null,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            title: Text(
              '${grupo.origem} → ${grupo.destino}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            subtitle: Text(
              grupo.rotuloCompleto,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            children: [
              for (final t in grupo.transicoes)
                ListTile(
                  dense: true,
                  title: Text(t.rotulo, style: const TextStyle(fontFamily: 'monospace')),
                  selected: model.transicaoSelecionada == t,
                  onTap: () => model.selecionarTransicao(t),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 18,
                    ),
                    onPressed: () => model.removerTransicao(t),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Configuracoes extends StatelessWidget {
  final MaquinaModel model;
  final TextEditingController entradaController;
  final TextEditingController simboloBrancoController;

  const _Configuracoes({
    required this.model,
    required this.entradaController,
    required this.simboloBrancoController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: entradaController,
            decoration: const InputDecoration(
              labelText: 'Entrada inicial (fita)',
              hintText: '101',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.text_fields),
            ),
            onChanged: model.definirEntrada,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: simboloBrancoController,
            decoration: const InputDecoration(
              labelText: 'Símbolo branco',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.space_bar),
            ),
            maxLength: 1,
            onChanged: model.definirSimboloBranco,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              model.carregarMaquina(MaquinaModel.exemploIncrementoBinario().maquina);
              entradaController.text = model.maquina.entradaInicial;
              simboloBrancoController.text = model.maquina.simboloBranco;
            },
            icon: const Icon(Icons.science),
            label: const Text('Carregar exemplo'),
          ),
        ],
      ),
    );
  }
}

class _CanvasAutomato extends StatelessWidget {
  final GlobalKey canvasKey;
  final MaquinaModel model;
  final bool modoAdicionarEstado;
  final bool modoTransicao;
  final ValueNotifier<Offset?> posicaoArraste;
  final String? transicaoDestinoHover;
  final Offset? Function(Offset global)? globalParaCanvas;
  final String? Function(Offset pos) estadoEmPosicao;
  final VoidCallback onToggleModoAdicionar;
  final VoidCallback onToggleModoTransicao;
  final void Function(Offset pos) onTapCanvas;
  final void Function(Offset pos) onDoubleTap;
  final void Function(String nome, Offset pos) onIniciarTransicao;
  final void Function(Offset pos) onAtualizarTransicao;
  final void Function(Offset pos) onFinalizarTransicao;
  final VoidCallback onCancelarTransicao;

  const _CanvasAutomato({
    required this.canvasKey,
    required this.model,
    required this.modoAdicionarEstado,
    required this.modoTransicao,
    required this.posicaoArraste,
    required this.transicaoDestinoHover,
    required this.globalParaCanvas,
    required this.estadoEmPosicao,
    required this.onToggleModoAdicionar,
    required this.onToggleModoTransicao,
    required this.onTapCanvas,
    required this.onDoubleTap,
    required this.onIniciarTransicao,
    required this.onAtualizarTransicao,
    required this.onFinalizarTransicao,
    required this.onCancelarTransicao,
  });

  Offset _destinoVisual(Offset cursor, Offset origemCentro) {
    final hover = transicaoDestinoHover;
    if (hover == null) return cursor;
    try {
      final e = model.maquina.estados.firstWhere((s) => s.nome == hover);
      return pontoBordaEstado(Offset(e.x, e.y), origemCentro);
    } catch (_) {
      return cursor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Estado? origemPendente;
    if (model.origemTransicaoPendente != null) {
      try {
        origemPendente = model.maquina.estados
            .firstWhere((e) => e.nome == model.origemTransicaoPendente);
      } catch (_) {}
    }

    return Container(
      color: theme.colorScheme.surface,
      child: Stack(
        key: canvasKey,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: modoAdicionarEstado ? (d) => onTapCanvas(d.localPosition) : null,
              onDoubleTapDown: modoTransicao ? null : (d) => onDoubleTap(d.localPosition),
              child: CustomPaint(
                painter: _GridPainter(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
              ),
            ),
          ),
          for (final grupo in agruparTransicoes(model.maquina.transicoes))
            TransicaoWidget(
              grupo: grupo,
              estados: model.maquina.estados,
              ativa: grupo.contem(model.maquina.ultimaTransicao),
              selecionada: grupo.contem(model.transicaoSelecionada),
              transicaoAtiva: model.maquina.ultimaTransicao,
            ),
          if (origemPendente != null)
            ValueListenableBuilder<Offset?>(
              valueListenable: posicaoArraste,
              builder: (context, cursor, _) {
                if (cursor == null) return const SizedBox.shrink();
                final origem = Offset(origemPendente!.x, origemPendente.y);
                final destino = _destinoVisual(cursor, origem);
                return IgnorePointer(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: TransicaoPendentePainter(
                      origem: origem,
                      destino: destino,
                      cor: transicaoDestinoHover != null
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.secondary,
                    ),
                  ),
                );
              },
            ),
          for (final e in model.maquina.estados)
            EstadoWidget(
              estado: e,
              selecionado: model.estadoSelecionado == e.nome,
              ativo: model.maquina.estadoAtual == e.nome,
              origemPendente: model.origemTransicaoPendente == e.nome,
              destinoHover: transicaoDestinoHover == e.nome,
              modoTransicao: modoTransicao,
              onTap: modoTransicao ? null : () => model.selecionarEstado(e.nome),
              onArrastar: modoTransicao ? null : (x, y) => model.moverEstado(e.nome, x, y),
            ),
          if (modoTransicao)
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (e) {
                  if (model.origemTransicaoPendente != null) return;
                  final pos = globalParaCanvas?.call(e.position);
                  if (pos == null) return;
                  final nome = estadoEmPosicao(pos);
                  if (nome != null) onIniciarTransicao(nome, pos);
                },
                onPointerMove: (e) {
                  if (model.origemTransicaoPendente == null) return;
                  final pos = globalParaCanvas?.call(e.position);
                  if (pos != null) onAtualizarTransicao(pos);
                },
                onPointerUp: (e) {
                  if (model.origemTransicaoPendente == null) return;
                  final pos = globalParaCanvas?.call(e.position);
                  if (pos != null) onFinalizarTransicao(pos);
                },
                onPointerCancel: (_) {
                  if (model.origemTransicaoPendente != null) onCancelarTransicao();
                },
              ),
            ),
          if (model.maquina.estados.isEmpty)
            IgnorePointer(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    Text(
                      'Duplo clique para adicionar um estado',
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            ),
          if (modoTransicao)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.04),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 56),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          model.origemTransicaoPendente != null
                              ? 'Solte sobre o estado de destino'
                              : 'Arraste de uma bolinha até outra',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (modoAdicionarEstado)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: theme.colorScheme.primary.withValues(alpha: 0.04),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'Clique no canvas para posicionar e configurar o estado',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            child: _BarraFerramentasCanvas(
              modoAdicionarEstado: modoAdicionarEstado,
              modoTransicao: modoTransicao,
              onToggleAdicionar: onToggleModoAdicionar,
              onToggleTransicao: onToggleModoTransicao,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraFerramentasCanvas extends StatelessWidget {
  final bool modoAdicionarEstado;
  final bool modoTransicao;
  final VoidCallback onToggleAdicionar;
  final VoidCallback onToggleTransicao;

  const _BarraFerramentasCanvas({
    required this.modoAdicionarEstado,
    required this.modoTransicao,
    required this.onToggleAdicionar,
    required this.onToggleTransicao,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Adicionar estado no canvas',
              child: FilledButton.tonalIcon(
                onPressed: onToggleAdicionar,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Estado'),
                style: FilledButton.styleFrom(
                  backgroundColor: modoAdicionarEstado
                      ? theme.colorScheme.primaryContainer
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: 'Arrastar de uma bolinha até outra',
              child: FilledButton.tonalIcon(
                onPressed: onToggleTransicao,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Transição'),
                style: FilledButton.styleFrom(
                  backgroundColor: modoTransicao
                      ? theme.colorScheme.secondaryContainer
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const step = 32.0;
    final paint = Paint()..color = color..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
