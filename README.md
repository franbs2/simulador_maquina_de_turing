# Simulador Visual de Máquina de Turing

Aplicativo educacional em **Flutter/Dart** para criar, editar e simular Máquinas de Turing de forma visual. Desenvolvido para estudo de **Teoria da Computação**, com motor de simulação 100% local (sem backend) e animações em tempo real.

---

## Sumário

- [Visão geral](#visão-geral)
- [Funcionalidades](#funcionalidades)
- [Requisitos](#requisitos)
- [Instalação e execução](#instalação-e-execução)
- [Como usar](#como-usar)
- [Formato do arquivo JSON](#formato-do-arquivo-json)
- [Arquitetura do projeto](#arquitetura-do-projeto)
- [Motor da máquina](#motor-da-máquina)
- [Testes](#testes)
- [Dependências](#dependências)

---

## Visão geral

O simulador permite:

1. **Desenhar** o autômato (estados e transições) em um canvas interativo.
2. **Configurar** a fita de entrada e o símbolo branco.
3. **Executar** a máquina passo a passo ou em modo contínuo.
4. **Salvar e carregar** máquinas em arquivos JSON.

Toda a lógica de simulação roda em Dart puro no cliente, garantindo baixa latência para animações fluidas.

---

## Funcionalidades

### Editor visual

| Recurso | Descrição |
|---------|-----------|
| Criar estados | Duplo clique no canvas ou botão **Estado** |
| Mover estados | Arrastar o círculo do estado |
| Editar estados | Painel lateral **Estados** → ícone de editar |
| Criar transições | Modo **Transição** → arrastar de uma bolinha até outra |
| Múltiplas δ na mesma seta | Várias transições entre os mesmos estados, com rótulos empilhados (`0/Y,R`, `1/X,R`, …) |
| Painel lateral | Abas **Estados**, **Transições** e **Configurações** (recolhível) |
| Persistência | Salvar / carregar em `.json` |

### Simulação

| Controle | Ação |
|----------|------|
| **Executar** | Roda a máquina automaticamente até parar |
| **Pausar** | Interrompe a execução (botão volta para **Executar**) |
| **Próximo passo** | Executa exatamente uma transição δ |
| **Resetar** | Restaura fita e estado inicial |
| **Velocidade** | Slider de 50 ms a 2000 ms entre passos |

Durante a simulação:

- O **estado atual** pulsa com destaque visual.
- A **transição usada** fica destacada na seta.
- A **fita** é atualizada em tempo real com o cabeçote visível.

### Exemplo incluído

Ao abrir o app, é carregado um exemplo de **incrementador binário** com entrada `101`.

---

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.11+**
- Dart **3.11+**
- Plataformas suportadas: **Linux**, **Windows**, **macOS**, **Web**, **Android**, **iOS**

---

## Instalação e execução

```bash
# Clone ou entre na pasta do projeto
cd simulador_maquina_de_turing

# Instale as dependências
flutter pub get

# Execute (escolha o dispositivo disponível)
flutter run -d linux      # Linux
flutter run -d chrome     # Navegador
flutter run -d windows    # Windows
```

### Build de produção

```bash
flutter build linux
flutter build web
flutter build apk
```

Os artefatos ficam em `build/`.

---

## Como usar

### 1. Criar estados

- **Duplo clique** em qualquer área vazia do canvas → cria um estado `q0`, `q1`, …
- Ou clique em **Estado** na barra do canvas e depois clique para posicionar (abre o diálogo de configuração).

No diálogo de edição você pode:

- Renomear o estado
- Marcar como **estado inicial**
- Marcar como **estado final** (exibido como `((qf))`)
- Excluir o estado

### 2. Criar transições

1. Clique em **Transição** na barra do canvas.
2. **Clique e arraste** de um estado até outro.
3. Preencha o formulário:

   | Campo | Significado |
   |-------|-------------|
   | Símbolo lido | Símbolo atual na fita |
   | Símbolo escrito | Símbolo a gravar |
   | Movimento | `L` (esquerda) ou `R` (direita) |

4. A transição aparece na seta no formato `lido/escrito,movimento` (ex.: `1/1,R`).

Para adicionar outra regra na **mesma seta** (ex.: `0/Y,R` e `1/X,R` entre `q0` e `q1`), repita o arraste entre os mesmos estados com um **símbolo lido diferente**.

> **Nota:** Por definição formal, cada par *(estado, símbolo lido)* admite no máximo uma transição. Duas regras com o mesmo símbolo lido no mesmo estado se substituem.

### 3. Configurar a simulação

Na aba **Configurações** do painel lateral:

- **Entrada inicial** — conteúdo inicial da fita (ex.: `101`)
- **Símbolo branco** — célula vazia (padrão: `_`)

### 4. Executar

Use os controles na parte inferior da tela:

```
▶ Executar  |  ⏭ Próximo passo  |  ↻ Resetar  |  Velocidade ────
```

### 5. Salvar e carregar

- **Salvar** — abre o diálogo do sistema; o arquivo `.json` é gravado no caminho escolhido.
- **Carregar** — seleciona um `.json` e restaura estados, transições, posições e configurações.

---

## Formato do arquivo JSON

```json
{
  "estados": [
    {
      "nome": "q0",
      "x": 120.0,
      "y": 200.0,
      "inicial": true,
      "final": false
    },
    {
      "nome": "q1",
      "x": 320.0,
      "y": 120.0,
      "inicial": false,
      "final": false
    }
  ],
  "transicoes": [
    {
      "origem": "q0",
      "destino": "q1",
      "ler": "1",
      "escrever": "1",
      "movimento": "R"
    },
    {
      "origem": "q0",
      "destino": "q1",
      "ler": "0",
      "escrever": "Y",
      "movimento": "R"
    }
  ],
  "simboloBranco": "_",
  "entradaInicial": "101"
}
```

| Campo | Descrição |
|-------|-----------|
| `estados[].nome` | Identificador do estado |
| `estados[].x`, `y` | Posição no canvas (pixels) |
| `estados[].inicial` | `true` se for o estado inicial |
| `estados[].final` | `true` se for estado de aceitação |
| `transicoes[].origem` / `destino` | Estados da aresta |
| `transicoes[].ler` | Símbolo lido (δ) |
| `transicoes[].escrever` | Símbolo escrito |
| `transicoes[].movimento` | `L` ou `R` |
| `simboloBranco` | Símbolo das células vazias |
| `entradaInicial` | Palavra de entrada na fita |

---

## Arquitetura do projeto

```
lib/
├── core/                    # Motor da Máquina de Turing (sem UI)
│   ├── estado.dart          # Estado com posição no canvas
│   ├── transicao.dart       # Função δ
│   ├── fita.dart            # Fita infinita
│   ├── maquina_turing.dart  # Execução: passo, completo, reset
│   └── grupo_transicao.dart # Agrupa transições na mesma seta
├── models/
│   └── maquina_model.dart   # Estado da UI + ChangeNotifier
├── services/
│   └── arquivo_service.dart # Serialização JSON e I/O de arquivos
├── widgets/
│   ├── estado_widget.dart   # Círculo do estado + painter de setas
│   ├── transicao_widget.dart
│   └── fita_widget.dart     # Visualização da fita
├── screens/
│   ├── editor_screen.dart   # Editor + canvas + painel lateral
│   └── simulacao_screen.dart# Controles e fita de simulação
└── main.dart                # Tema e inicialização
```

### Separação de responsabilidades

| Camada | Responsabilidade |
|--------|------------------|
| `core/` | Lógica pura da MT — testável sem Flutter |
| `models/` | Ponte entre motor e interface (`Provider`) |
| `widgets/` | Componentes visuais reutilizáveis |
| `screens/` | Composição das telas |
| `services/` | Persistência em arquivo |

---

## Motor da máquina

### Classe `MaquinaTuring`

| Método | Descrição |
|--------|-----------|
| `executarPasso()` | Aplica uma transição δ e retorna `ResultadoPasso` |
| `executarCompleto()` | Executa até estado final, sem transição ou limite |
| `resetar()` | Restaura fita e estado inicial |

### Classe `Fita`

Simula fita **infinita** em ambas as direções:

```dart
fita.ler()            // símbolo na posição do cabeçote
fita.escrever('1')    // grava símbolo
fita.moverDireita()   // move cabeçote →
fita.moverEsquerda()  // move cabeçote ←
```

### Função de transição δ

Cada `Transicao` representa:

```
δ(estado_atual, símbolo_lido) → (símbolo_escrito, movimento, próximo_estado)
```

Exibido visualmente como: `símbolo_lido/símbolo_escrito,movimento`

---

## Testes

```bash
flutter test
```

Os testes cobrem:

- Comportamento da fita infinita
- Execução de passos e detecção de estado final
- Agrupamento de transições na mesma aresta

---

## Dependências

| Pacote | Uso |
|--------|-----|
| [provider](https://pub.dev/packages/provider) | Gerenciamento de estado (`ChangeNotifier`) |
| [file_picker](https://pub.dev/packages/file_picker) | Diálogos nativos de salvar/abrir arquivo |

---

## Licença

Projeto educacional. Uso livre para fins acadêmicos.
