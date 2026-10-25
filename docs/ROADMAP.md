# Roteiro de evolução do FinanceLab Mobile

Atualizado em 24/10/2026. Este é um plano vivo: as fases 1 e 2 começaram, e os itens restantes seguem como critérios para as próximas entregas.

## Objetivo e ponto de partida

Entregar um app Android em português que continue claro e seguro para pessoas com pouca familiaridade com finanças, baixa visão, leitores de tela, aparelhos compactos ou lentos e conexões instáveis. A demonstração local usa dados fictícios; contas reais dependem de uma API pública HTTPS, ainda não configurada.

Nas telas, priorizar uma ação principal por tarefa, títulos que expliquem o dado, valores acompanhados de período e unidade, textos curtos em português comum e ajuda contextual para termos financeiros. Em ações que apagam ou substituem dados, mostrar a consequência e uma forma de voltar ou preservar uma cópia. O objetivo é reduzir esforço de leitura e erro para pessoas de diferentes idades e experiência digital.

O app já tinha Material 3, navegação que muda para barra lateral em telas largas, valores monetários em centavos, armazenamento seguro do rascunho e testes de domínio, controlador e widgets. Os pontos abaixo formaram a linha de base antes da primeira rodada; **a acessibilidade e o desempenho em aparelho ainda precisam ser medidos**:

| Área | Evidência inicial | Risco ou oportunidade |
| --- | --- | --- |
| Gravação | O controlador faz GET, compara uma impressão digital e depois envia o documento inteiro por PUT; o servidor aceita o PUT sem revisão. | Duas gravações próximas em aparelhos diferentes podem sobrescrever uma à outra. |
| Importação | O modelo valida a forma do JSON, mas não rejeita IDs repetidos nas coleções. | Editar ou remover um item pode atingir o registro errado ou vários registros. |
| Armazenamento | O rascunho é protegido e separado por conta, mas não tem versão de esquema, data, revisão-base nem fluxo específico para descartar um rascunho ilegível. | Recuperação e migração ficam difíceis; sair da conta com pendências pode perder trabalho. |
| Layout | Há AppSpacing no tema, mas as telas ainda usam muitos espaçamentos literais; a visão geral usa cards em grade com proporção fixa. | O ritmo visual varia e textos ampliados podem apertar os cards. |
| Acessibilidade | Widgets Material e alguns botões já oferecem rótulos; não há testes dedicados de acessibilidade nem leitura das jornadas com TalkBack registrada. | Não há evidência de que métricas, barras, erros e navegação sejam compreensíveis para todos. |
| Volume | Lançamentos filtrados são montados como todos os filhos de uma lista; o resumo é calculado ao acessar o controlador. | É preciso medir o efeito com contas grandes antes de otimizar. |

## Progresso da primeira rodada

- **Dados:** o backend passou a exigir revisão/ETag no PUT e a recusar gravações concorrentes; o site enfileira gravações por sessão e o app preserva o rascunho diante de conflito. Importações com IDs repetidos são recusadas.
- **Recuperação:** rascunhos novos têm versão de esquema, datas, revisão-base e checksum. O app confere uma resposta perdida antes de repetir a gravação e exige decisão explícita para substituir uma versão remota. Um rascunho ilegível pode ser exportado ou descartado.
- **Interface:** visão geral e análise receberam composição que cresce com o texto, espaçamentos compartilhados e leitura semântica dos indicadores principais. Há testes de widget para telas compactas e fonte ampliada.
- **Ainda pendente:** medição em aparelho modesto, percurso manual com TalkBack, contraste completo, limites por volume e sincronização offline por operação. A API pública HTTPS também continua necessária para testar contas reais no celular.

## Progresso da segunda rodada — responsividade

- Login: campos inválidos recebem foco; termos e privacidade têm botões com alvo de pelo menos 48 dp. O formulário continua rolável com teclado aberto.
- Lançamentos, fundos e orçamentos: ações e textos longos crescem ou passam para outra linha em espaço estreito. O seletor de tipo não estoura a largura com fonte a 200%.
- Metas, métricas e navegação: ações continuam alcançáveis; os cards de patrimônio empilham em largura estreita e a navegação lateral permanece utilizável no tablet.
- Estados de gravação: mensagens longas rolam dentro de uma área limitada, preservando espaço para o conteúdo e acesso à ação. Tema escuro recebeu os mesmos estilos de campo, card e botão do claro.
- **Verificação automatizada:** testes de widget em 320×640 dp, texto a 200%, teclado simulado com 280 dp de altura e tablet de 900×700 dp; pares semânticos principais do tema claro e escuro medidos com contraste de pelo menos 4,5:1. Isso cobre os componentes e estados testados, não a tela inteira.
- **Verificação pendente:** rotação, toque e TalkBack em Android físico ou emulador; não havia dispositivo Android disponível neste ambiente. A medição de desempenho e o contraste de todos os elementos de tela também continuam pendentes.

## Achados nas capturas do aplicativo em uso

As capturas enviadas em 24/10/2026 mostram duas barreiras que os testes de overflow não detectaram: em **Lançamentos**, o formulário ocupa quase toda a primeira tela e empurra busca/lista para baixo; em **Análise**, histórico e orçamentos aparecem como texto e números sem uma visualização gráfica clara. O aviso da demonstração também toma espaço considerável no topo. Esta rodada trata a hierarquia visual e o acesso às tarefas, além de evitar estouro de layout. Modelo do aparelho, escala configurada e comportamento com TalkBack não foram medidos pelas capturas.

## Progresso da terceira rodada — gráficos e hierarquia

- Visão geral e análise mostram barras mensais para receitas e saídas; a análise inclui gráfico de despesas de consumo por categoria e barras de uso dos orçamentos. Cores vêm do tema claro/escuro, e legendas, valores e texto semântico acompanham as formas.
- Categorias além das cinco maiores entram em “Outras categorias” sem alterar o total; a lista completa pode ser aberta na análise. Os rótulos dos meses ficam alinhados às barras.
- Em Lançamentos, busca, filtros e lista aparecem antes do formulário. “Novo lançamento” abre o formulário, que conserva os campos se for recolhido. O aviso da demo foi abreviado na tela e mantém a explicação completa para leitor de tela.
- Testes de widget cobrem gráficos e valores, agregação de categorias, largura de 320 dp, texto a 200%, formulário recolhido e navegação. Ainda é preciso conferir a composição final e o TalkBack no aparelho do usuário.

## Ordem de execução

As fases 1 e 2 podem avançar em paralelo. A fase 4 depende do contrato de revisão da fase 1. Uma fase só termina quando seus critérios de aceite forem demonstrados, inclusive nos estados de erro.

### Fase 0 — estabelecer uma linha de base

**Entrega:** registrar uma matriz curta das jornadas de entrada, lançamento, busca, análise, importação, conflito, exportação e saída. Usar 320–360 dp, tablet, fonte padrão e 200%, tema claro/escuro, teclado aberto, TalkBack e rede ausente/intermitente. Medir o tempo e os quadros de abrir, pesquisar e rolar uma lista de 1 mil e 10 mil lançamentos em modo profile em um Android modesto. Guardar aparelho, versão, conjunto de dados e resultados para comparação.

**Aceite:** cada problema observado tem tela, passos de reprodução e impacto; “não testado em aparelho” permanece identificado como tal. Nenhum ganho de velocidade ou conformidade é declarado apenas por inspeção de código.

**Skills:** flutter-accessibility-audit, flutter-performance, flutter-testing.

### Fase 1 — proteger os dados antes de ampliar a sincronização (P0)

1. No backend, adicionar revisão por documento financeiro e gravação condicional atômica. GET devolve revisão/ETag; PUT exige a revisão recebida e retorna 409 ou 412 quando ela mudou. Migrar documentos existentes sem alterar valores.
2. No app, manter cópia local e revisão-base; em conflito, mostrar o que ficou neste aparelho e o que está no servidor, com ações explícitas para recarregar, exportar o rascunho e decidir qual versão manter. Nenhuma tentativa automática deve substituir dados remotos após 409.
3. Validar IDs únicos de lançamentos, fundos e orçamentos no app e no servidor. Rejeitar uma importação inválida antes de substituir o estado atual. Definir limites de tamanho e quantidade com mensagens que expliquem como reduzir o arquivo.
4. Versionar o envelope do rascunho com data, revisão-base e verificação de integridade. Permitir exportar pendências antes de sair e descartar apenas o rascunho danificado mediante confirmação.

**Aceite:** teste de integração com dois clientes partindo da mesma revisão: a segunda gravação é recusada e as duas edições continuam recuperáveis. Testes de JSON com IDs duplicados, limite excedido, falha de armazenamento, reinício e saída com pendência passam sem apagar dados válidos.

**Skills:** flutter-sync-conflicts, flutter-local-persistence, flutter-error-feedback, flutter-domain-rules, flutter-rest-api, flutter-security-review.

### Fase 2 — base visual e acessibilidade para as jornadas principais (P0)

1. Aplicar os tokens de espaço do tema em tela e componentes compartilhados, completando uma escala coerente de 4/8/12/16/24/32 dp quando útil. Padronizar largura de leitura, margens, títulos, estados vazios, erros e ações. Manter controles essenciais visíveis com teclado e fonte ampliada.
2. Fazer cards de métricas e linhas de análise crescerem com o conteúdo, em vez de depender de proporção fixa ou truncamento de rótulos importantes. Adaptar composição ao espaço disponível. Usar texto e valores junto com gráficos/cores.
3. Conferir os pares de cores finais: meta de 4,5:1 para texto comum, 3:1 para texto grande e 3:1 para elementos gráficos essenciais. Revisar modo claro e escuro, foco, erro e desabilitado. Alvos de toque Android com pelo menos 48 × 48 dp.
4. Percorrer com TalkBack as jornadas de demo, lançamento, filtro, exclusão, importação e conflito. Corrigir nome, papel, valor, estado e ordem de leitura de controles; anunciar erros e estado de gravação sem repetição. Preferir semântica nativa e só adicionar Semantics onde faltar contexto.
5. Rodar as diretrizes automatizadas do Flutter para rótulos, contraste e toque, além de testes de widget com texto em 200%, tela compacta e teclado. Validar manualmente as mesmas jornadas em aparelho.

**Aceite:** jornadas essenciais terminam com TalkBack; nenhuma ação fica inacessível em 320–360 dp e texto a 200%; não há overflow; estados não dependem apenas de cor; medições de contraste e alvos de toque ficam registradas.

**Skills:** flutter-design-system, flutter-responsive-layout, flutter-accessible-forms, flutter-accessibility-audit, flutter-screen-reader, flutter-testing.

### Fase 3 — escala e clareza de estados (P1)

1. Usar o perfil da fase 0 para localizar gargalos. Se a lista de lançamentos for o problema, construir linhas sob demanda (ListView.builder/SliverList), limitar trabalho por reconstrução e avaliar paginação. Se cálculo ou serialização for o problema, reduzir recálculos e considerar processamento fora do quadro apenas depois da medida.
2. Definir no backend limites claros por conta e respostas 413/422; para volume maior, planejar endpoints por item ou lote e paginação antes de prometer sincronização de grandes históricos. Reavaliar o custo de enviar o documento inteiro.
3. Diferenciar “salvo neste aparelho”, “enviando”, “confirmado no servidor”, “falha” e “conflito” em linguagem simples. Mostrar a ação possível em 401, 409, timeout e erro local, preservando a entrada da pessoa.
4. Repetir o perfil no mesmo aparelho e conjunto de dados. Registrar tempo de interação, quadros lentos, memória e regressões de usabilidade.

**Aceite:** os gargalos observados melhoram em medição comparável; filtros e rolagem seguem utilizáveis com o volume alvo definido; nenhuma mensagem diz “salvo” antes da confirmação correspondente.

**Skills:** flutter-performance, flutter-error-feedback, flutter-rest-api, flutter-clean-architecture.

### Fase 4 — uso com conexão instável e alcance maior (P2)

Depois da gravação condicional e de IDs estáveis, definir quais ações podem acontecer offline. Persistir uma fila por operação com idempotência, revisão-base e retomada segura após resposta incerta. Mostrar quantidade pendente e última sincronização; separar dados reais em cache dos dados fictícios da demo.

Se os testes de campo mostrarem necessidade, oferecer opção adicional de letras maiores e alto contraste, preservando a escala do sistema. Revisar linguagem, moeda, datas e explicações financeiras com pessoas de diferentes idades e experiência digital. Considerar outras línguas e iOS somente com requisitos e testes próprios.

**Aceite:** pendências sobrevivem a reinício e retorno da rede sem duplicação; conflito mantém ambas as versões; as opções visuais funcionam em toda a navegação, inclusive diálogos; feedback de usuários reais gera uma lista priorizada de correções.

**Skills:** flutter-data-sync, flutter-offline-resilience, flutter-adaptive-fonts, flutter-high-contrast, flutter-screen-reader.

## Skills e manutenção

As dez skills novas em .agents/skills vieram de [Flutter-AI-Skills](https://github.com/viniprati/Flutter-AI-Skills/tree/11eaf8ed115b58bf954a74626229479bf72fb4f2/skills), fixadas no commit 11eaf8ed115b58bf954a74626229479bf72fb4f2: flutter-data-sync, flutter-sync-conflicts, flutter-offline-resilience, flutter-local-persistence, flutter-error-feedback, flutter-accessibility-audit, flutter-screen-reader, flutter-adaptive-fonts, flutter-high-contrast e flutter-performance. A licença do catálogo acompanha a cópia em .agents/skills/LICENSE.flutter-ai-skills. As skills já presentes de domínio, precisão monetária, API, design, responsividade, formulários, testes e segurança continuam úteis. Selecionar por tarefa; uma skill orienta o trabalho, mas não substitui teste de backend nem teste em aparelho.

Referências para os critérios: [acessibilidade no Flutter](https://docs.flutter.dev/ui/accessibility), [teste de acessibilidade no Flutter](https://docs.flutter.dev/ui/accessibility/accessibility-testing), [design adaptável](https://docs.flutter.dev/ui/adaptive-responsive), [perfil de desempenho](https://docs.flutter.dev/perf/ui-performance) e [WCAG 2.2](https://www.w3.org/TR/WCAG22/).
