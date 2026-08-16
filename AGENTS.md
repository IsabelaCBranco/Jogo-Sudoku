# AGENTS.md — Sudoku

## 1. Objetivo

Desenvolver um jogo de Sudoku completo utilizando **Godot Engine + GDScript**, com código organizado, testável, modular e fácil de evoluir.

O jogo deve oferecer diferentes níveis de dificuldade, geração procedural de tabuleiros válidos, sistema opcional de vidas, dicas, pontuação, salvamento de progresso e estatísticas.

O agente deve priorizar:

1. Correção das regras do Sudoku.
2. Geração de puzzles válidos e com solução única.
3. Separação entre lógica do jogo e interface.
4. Código simples e testável.
5. Boa experiência do jogador.
6. Evolução incremental do projeto.

---

# 2. Stack

## Engine

* Godot 4.x
* GDScript

## Testes

Utilizar testes automatizados sempre que possível.

A lógica principal deve ser testável sem depender da renderização ou interação manual com a interface.

---

# 3. Regras gerais para o agente

Antes de modificar o projeto:

1. Leia este arquivo.
2. Analise a estrutura existente.
3. Identifique as funcionalidades já implementadas.
4. Não reescreva funcionalidades existentes sem necessidade.
5. Preserve o comportamento existente.
6. Faça alterações pequenas e isoladas.
7. Execute os testes relacionados à alteração.
8. Verifique se a alteração não quebrou outras funcionalidades.

Nunca implemente uma funcionalidade grande de uma única vez quando ela puder ser dividida em etapas menores.

---

# 4. Arquitetura

Separar o projeto conceitualmente em:

```text
UI
 ↓
Game Controller
 ↓
Game Systems
 ↓
Sudoku Core
```

A lógica do Sudoku não deve depender diretamente de elementos visuais do Godot.

## Sudoku Core

Responsável por:

* Representação do tabuleiro.
* Regras do Sudoku.
* Validação de movimentos.
* Verificação da solução.
* Geração de soluções.
* Resolução de puzzles.

## Game Systems

Responsável por:

* Dificuldade.
* Vidas.
* Dicas.
* Pontuação.
* Tempo.
* Salvamento.
* Estatísticas.

## UI

Responsável apenas pela apresentação e interação com o jogador.

Não colocar regras de negócio diretamente em:

* `Button`
* `Label`
* `Control`
* `GridContainer`
* `TextureRect`
* outros nós visuais.

---

# 5. Estrutura de diretórios

Manter uma estrutura semelhante a:

```text
res://
├── scenes/
│   ├── main_menu/
│   ├── game/
│   ├── sudoku_board/
│   ├── settings/
│   └── statistics/
│
├── scripts/
│   ├── core/
│   │   ├── sudoku_board.gd
│   │   ├── sudoku_cell.gd
│   │   └── sudoku_solver.gd
│   │
│   ├── generator/
│   │   ├── sudoku_generator.gd
│   │   └── difficulty_manager.gd
│   │
│   ├── systems/
│   │   ├── game_state.gd
│   │   ├── lives_system.gd
│   │   ├── hint_system.gd
│   │   ├── score_system.gd
│   │   ├── timer_system.gd
│   │   └── save_system.gd
│   │
│   └── ui/
│       ├── main_menu.gd
│       ├── game_ui.gd
│       ├── settings_ui.gd
│       └── statistics_ui.gd
│
├── resources/
│
├── assets/
│
└── tests/
    ├── test_sudoku_board.gd
    ├── test_sudoku_solver.gd
    ├── test_sudoku_generator.gd
    ├── test_difficulty.gd
    └── test_lives.gd
```

A estrutura pode ser adaptada caso o projeto cresça, mas a separação de responsabilidades deve ser preservada.

---

# 6. Sudoku

O jogo deve utilizar o Sudoku tradicional 9x9.

Regras:

* Cada linha deve conter os números de 1 a 9 sem repetição.
* Cada coluna deve conter os números de 1 a 9 sem repetição.
* Cada bloco 3x3 deve conter os números de 1 a 9 sem repetição.
* O puzzle deve possuir uma solução válida.
* O puzzle gerado deve possuir solução única.

O tamanho do tabuleiro não deve ser alterado sem decisão explícita do projeto.

---

# 7. Representação do tabuleiro

O tabuleiro deve possuir uma representação independente da UI.

Cada célula deve permitir identificar:

* Valor atual.
* Valor da solução.
* Se é uma célula originalmente fornecida.
* Se possui erro.
* Anotações/candidatos.

Não permitir que o jogador altere diretamente uma célula originalmente fornecida pelo puzzle.

---

# 8. Gerador de Sudoku

O gerador deve:

1. Criar uma solução completa válida.
2. Remover valores progressivamente.
3. Verificar se o puzzle continua solucionável.
4. Verificar se possui solução única.
5. Classificar a dificuldade.
6. Retornar um puzzle válido.

Nunca entregar ao jogador um puzzle sem solução única.

O gerador deve utilizar aleatoriedade controlada quando necessário para permitir testes determinísticos.

---

# 9. Dificuldades

O jogo deve possuir inicialmente cinco dificuldades:

| Nível | Nome         |
| ----- | ------------ |
| 1     | Muito Fácil  |
| 2     | Fácil        |
| 3     | Médio        |
| 4     | Difícil      |
| 5     | Especialista |

A dificuldade **não deve ser definida somente pela quantidade de células vazias**.

Sempre que possível, considerar também:

* Quantidade de candidatos.
* Necessidade de técnicas de resolução.
* Profundidade de backtracking.
* Complexidade da solução.
* Quantidade de decisões necessárias.

As faixas de células preenchidas podem ser utilizadas como parâmetro inicial, mas não como único critério.

Sugestão inicial:

```text
Muito Fácil: 45–50 preenchidas
Fácil:       36–44 preenchidas
Médio:       32–35 preenchidas
Difícil:     28–31 preenchidas
Especialista: 22–27 preenchidas
```

Esses valores podem ser ajustados após testes de jogabilidade.

---

# 10. Solver

O solver deve conseguir:

* Resolver um Sudoku.
* Verificar se existe solução.
* Contar soluções até pelo menos duas.
* Determinar se um puzzle possui solução única.

A contagem de soluções deve parar ao encontrar duas soluções quando o objetivo for apenas validar unicidade.

Isso evita processamento desnecessário.

---

# 11. Sistema de vidas

O jogo deve possuir um sistema opcional de vidas.

## Configuração padrão

O modo de vidas começa ativado.

O jogador inicia a partida com:

```text
3 vidas
```

## Quando o jogador erra

Ao inserir um número diferente da solução correta:

1. O movimento é identificado como incorreto.
2. Uma vida é removida.
3. O erro é informado visualmente.
4. O número incorreto é removido ou não confirmado.
5. A interface é atualizada.

Exemplo:

```text
♥ ♥ ♥
↓ erro
♥ ♥ ♡
```

## Fim das vidas

Quando:

```text
vidas == 0
```

a partida deve ser encerrada como derrota.

O jogador deve receber opções como:

* Jogar novamente.
* Escolher outra dificuldade.
* Voltar ao menu.

## Sistema desativado

Quando o jogador desativar o sistema de vidas:

* Não existe limite de erros.
* Erros continuam podendo ser identificados visualmente.
* Nenhuma vida é removida.
* O jogo não termina por quantidade de erros.

A lógica de vidas deve estar isolada em `LivesSystem`.

A UI não deve controlar diretamente a quantidade de vidas.

---

# 12. Configurações

O menu de configurações deve permitir controlar pelo menos:

* Sistema de vidas: Ativado/Desativado.
* Som: Ativado/Desativado.
* Música: Ativada/Desativada.
* Anotações: Ativadas/Desativadas.
* Exibição de erros: Ativada/Desativada.

As configurações devem ser persistidas entre sessões.

---

# 13. Jogabilidade

O jogador deve conseguir:

* Selecionar uma célula.
* Inserir um número.
* Remover um número.
* Utilizar anotações.
* Visualizar linha, coluna e bloco relacionados à célula.
* Identificar células preenchidas originalmente.
* Desfazer jogadas.
* Refazer jogadas.
* Reiniciar a partida.

A interação deve ser possível de forma clara tanto por mouse quanto por teclado quando apropriado.

---

# 14. Anotações

Permitir que o jogador adicione candidatos em uma célula.

Exemplo:

```text
┌─────────┐
│ 2  5  7 │
│  1  4   │
│  3    8 │
└─────────┘
```

As anotações não devem ser consideradas respostas.

Quando um número definitivo for inserido:

* Remover anotações incompatíveis da própria célula.
* Opcionalmente atualizar candidatos relacionados.

---

# 15. Sistema de dicas

Implementar três dicas, cada uma com nome e comportamento próprios:

### Dica — Sinalizar

Destaca uma célula vazia determinável (apenas um candidato válido).

### Dica — Revelar

Mostra uma possibilidade válida para uma célula.

### Dica — Preencher

Preenche automaticamente uma célula com a solução.

## Desbloqueio por vitória

As dicas são desbloqueadas permanentemente ao vencer partidas. Cada vitória
concede usos que se acumulam entre partidas e sessões:

| Vitória em  | Sinalizar | Revelar | Preencher |
| ----------- | --------- | ------- | --------- |
| Muito Fácil | 0         | 0       | 0         |
| Fácil       | +1        | 0       | 0         |
| Médio       | 0         | +1      | 0         |
| Difícil     | 0         | 0       | +1        |
| Especialista| +1        | +1      | +1        |

Regras do desbloqueio:

* O estoque de dicas é persistente e não reseta entre partidas.
* Uma dica é consumida somente quando aplicada com sucesso.
* O estoque deve ser salvo e restaurado entre sessões.
* A UI deve indicar a quantidade disponível e bloquear dicas indisponíveis.
* A recompensa de vitória é concedida no momento em que a partida é vencida.

Toda dica aplicada deve possuir uma penalidade na pontuação.

---

# 16. Pontuação

A pontuação deve considerar:

* Dificuldade.
* Tempo.
* Erros.
* Vidas restantes.
* Dicas utilizadas.

A fórmula exata pode evoluir posteriormente.

Nunca deixar a fórmula de pontuação espalhada pelo código.

Centralizar a regra em `ScoreSystem`.

---

# 17. Cronômetro

Cada partida deve registrar:

* Tempo decorrido.
* Momento de início.
* Momento de pausa.
* Tempo total ao finalizar.

O cronômetro não deve continuar contando durante uma pausa.

---

# 18. Salvamento

O jogo deve salvar automaticamente o progresso.

Salvar:

* Tabuleiro original.
* Estado atual.
* Solução.
* Dificuldade.
* Tempo.
* Vidas restantes.
* Configurações relevantes.
* Anotações.
* Estoque de dicas desbloqueadas (progresso persistente).
* Histórico necessário para desfazer/refazer.

O jogador deve conseguir continuar a partida exatamente de onde parou.

O sistema de salvamento deve ser independente da UI.

---

# 19. Estatísticas

Registrar estatísticas do jogador, como:

* Partidas iniciadas.
* Partidas concluídas.
* Partidas vencidas.
* Partidas perdidas.
* Melhor tempo por dificuldade.
* Melhor pontuação por dificuldade.
* Média de tempo.
* Quantidade média de erros.
* Quantidade de dicas utilizadas.

As estatísticas devem ser separadas dos dados da partida atual.

---

# 20. Interface

A interface deve ser simples, limpa e responsiva.

Durante a partida, exibir:

* Tabuleiro.
* Dificuldade atual.
* Cronômetro.
* Vidas, quando habilitadas.
* Pontuação.
* Botão de dica.
* Botão de desfazer.
* Botão de pausar.
* Opção de reiniciar.

O feedback visual deve ser claro para:

* Número selecionado.
* Linha/coluna/bloco relacionados.
* Erro.
* Número correto.
* Célula bloqueada.
* Vitória.
* Derrota.

Evitar excesso de elementos visuais.

---

# 21. Fluxo principal

O fluxo esperado é:

```text
Menu Principal
     ↓
Escolher dificuldade
     ↓
Configurar opções
     ↓
Gerar Sudoku
     ↓
Iniciar partida
     ↓
Jogar
     ├── Inserir número
     ├── Anotar
     ├── Desfazer
     ├── Dica
     └── Pausar
     ↓
Sudoku completo
     ↓
Validar vitória
     ↓
Calcular pontuação
     ↓
Salvar estatísticas
     ↓
Tela de resultado
```

---

# 22. Vitória

O jogador vence quando todas as células estiverem preenchidas corretamente.

Não considerar apenas:

```text
todas as células preenchidas
```

A condição correta é:

```text
tabuleiro atual == solução
```

Após a vitória:

* Parar o cronômetro.
* Calcular pontuação.
* Registrar estatísticas.
* Salvar resultado.
* Exibir tela de conclusão.

---

# 23. Derrota

A derrota ocorre quando o sistema de vidas está habilitado e:

```text
vidas == 0
```

A derrota deve:

* Parar o cronômetro.
* Registrar a partida.
* Exibir resultado.
* Permitir iniciar outra partida.

---

# 24. Testes

Toda lógica crítica deve possuir testes.

Testar obrigatoriamente:

## Board

* Tabuleiro vazio.
* Inserção válida.
* Inserção inválida.
* Células bloqueadas.
* Verificação de vitória.

## Solver

* Sudoku válido.
* Sudoku inválido.
* Sudoku com solução.
* Sudoku sem solução.
* Sudoku com múltiplas soluções.
* Sudoku com solução única.

## Generator

* Tabuleiro válido.
* Solução única.
* Diferentes seeds.
* Diferentes dificuldades.
* Não gerar puzzles impossíveis.

## Difficulty

* Classificação correta.
* Limites de dificuldade.
* Reprodutibilidade quando utilizada seed.

## Lives

* Começar com 3 vidas.
* Perder uma vida após erro.
* Não perder vida após acerto.
* Derrota ao chegar a zero.
* Sistema desativado não desconta vidas.
* Reiniciar partida restaura vidas.

## Dicas

* Vitória no Fácil concede a Sinalizar.
* Vitória no Médio concede a Revelar.
* Vitória no Difícil concede a Preencher.
* Vitória no Especialista concede uma de cada tipo.
* Vitória no Muito Fácil não concede dicas.
* Vitórias acumulam usos entre partidas.
* Consumo decrementa o estoque.
* Uso sem estoque é bloqueado.
* Persistência restaura o estoque.

## Score

* Erros aplicam penalidade.
* Dicas aplicam penalidade.
* Dificuldade influencia pontuação.
* Tempo influencia pontuação.

---

# 25. Testes determinísticos

Sempre que houver aleatoriedade:

* Permitir utilização de seed.
* Usar seeds fixas nos testes.
* Não depender de resultados aleatórios específicos.

Os testes devem ser reproduzíveis.

---

# 26. Código GDScript

Seguir boas práticas de GDScript:

* Tipagem estática sempre que possível.
* Funções pequenas.
* Classes com responsabilidade única.
* Evitar variáveis globais desnecessárias.
* Evitar `get_node()` espalhado pelo projeto.
* Utilizar sinais para comunicação entre sistemas quando apropriado.
* Evitar dependências circulares.
* Utilizar `@export` para configurações apropriadas.
* Utilizar `class_name` somente quando houver benefício real.
* Evitar código duplicado.

Exemplo:

```gdscript
func perder_vida() -> bool:
    if not vidas_ativadas:
        return false

    vidas -= 1
    vidas_alteradas.emit(vidas)

    return true
```

A lógica deve ser clara e previsível.

---

# 27. Comunicação entre sistemas

Preferir:

```text
Signals
Events
Dependency Injection simples
Interfaces bem definidas
```

Evitar:

```text
GameManager global controlando tudo
UI acessando diretamente qualquer sistema
Dependências circulares
Variáveis globais para estado de jogo
```

---

# 28. Cenas

Cada cena deve possuir uma responsabilidade clara.

Exemplo:

```text
MainMenu
Game
Settings
Statistics
Result
Pause
```

Evitar criar uma única cena gigante contendo todo o jogo.

---

# 29. Autoloads

Utilizar Autoload somente para sistemas realmente globais.

Exemplos aceitáveis:

```text
GameSettings
SaveManager
AudioManager
```

Não utilizar Autoload simplesmente para evitar passar dependências.

---

# 30. Recursos e dados

Configurações que possam ser alteradas sem modificar a lógica devem, quando apropriado, ser armazenadas em:

* Resources.
* Arquivos de configuração.
* Dados estruturados.

Evitar hardcode excessivo.

---

# 31. Performance

O jogo deve priorizar simplicidade.

Não realizar operações pesadas a cada frame sem necessidade.

O gerador e solver devem ser executados fora do fluxo visual quando possível.

Evitar:

```gdscript
_process()
```

para lógica que não precisa ser executada continuamente.

---

# 32. Segurança e integridade do jogo

O estado interno do Sudoku deve ser protegido contra alterações acidentais.

A solução do puzzle não deve ser modificada durante a partida.

O jogador não deve conseguir:

* Alterar células fornecidas.
* Alterar a solução.
* Ganhar apenas preenchendo todas as células sem verificar a solução.
* Manipular vidas através da UI.

---

# 33. Ordem de desenvolvimento

Implementar nesta ordem:

### Fase 1 — Fundação

* [ ] Criar projeto Godot.
* [ ] Configurar estrutura de diretórios.
* [ ] Criar modelo do tabuleiro.
* [ ] Implementar regras básicas.
* [ ] Criar testes do board.

### Fase 2 — Solver

* [ ] Implementar solver.
* [ ] Validar puzzles.
* [ ] Detectar múltiplas soluções.
* [ ] Garantir solução única.
* [ ] Criar testes.

### Fase 3 — Generator

* [ ] Gerar solução completa.
* [ ] Remover células.
* [ ] Validar unicidade.
* [ ] Implementar dificuldade.
* [ ] Criar testes.

### Fase 4 — Gameplay

* [ ] Criar tabuleiro visual.
* [ ] Seleção de células.
* [ ] Entrada de números.
* [ ] Validação.
* [ ] Anotações.
* [ ] Destaques.
* [ ] Desfazer/refazer.

### Fase 5 — Sistemas

* [ ] Implementar vidas.
* [ ] Implementar configurações.
* [ ] Implementar cronômetro.
* [ ] Implementar dicas.
* [ ] Implementar pontuação.

### Fase 6 — Persistência

* [ ] Salvar partida.
* [ ] Continuar partida.
* [ ] Salvar configurações.
* [ ] Salvar estatísticas.

### Fase 7 — UI

* [ ] Menu principal.
* [ ] Tela de configurações.
* [ ] Tela de pausa.
* [ ] Tela de vitória.
* [ ] Tela de derrota.
* [ ] Tela de estatísticas.

### Fase 8 — Polimento

* [ ] Animações.
* [ ] Feedback visual.
* [ ] Sons.
* [ ] Música.
* [ ] Ajustes de dificuldade.
* [ ] Correções de UX.

---

# 34. Regra para implementação de funcionalidades

Antes de implementar uma funcionalidade:

1. Identifique a responsabilidade.
2. Determine em qual camada ela pertence.
3. Verifique se já existe código relacionado.
4. Implemente a lógica.
5. Escreva testes.
6. Integre à UI.
7. Teste manualmente.
8. Verifique regressões.

Não adicionar uma funcionalidade diretamente na UI quando ela deveria pertencer a um sistema ou ao core.

---

# 35. Critério de conclusão

Uma funcionalidade somente é considerada concluída quando:

* Está implementada.
* Está integrada ao fluxo do jogo.
* Possui testes quando aplicável.
* Não quebra funcionalidades existentes.
* Possui tratamento para casos inválidos.
* Foi testada manualmente no Godot.
* O código está organizado de acordo com este documento.

---

# 36. Regra principal

Priorize:

```text
CORREÇÃO
    ↓
TESTABILIDADE
    ↓
SIMPLICIDADE
    ↓
MANUTENIBILIDADE
    ↓
EXPERIÊNCIA DO JOGADOR
```

Não adicionar complexidade sem necessidade.

Quando houver dúvida entre duas implementações, escolher a solução mais simples que mantenha a arquitetura e os requisitos do projeto.

Não implementar funcionalidades que não foram solicitadas sem antes justificar sua necessidade.
