# FinanceLab Mobile

Interface Android em Flutter/Dart para o FinanceLab. Usa a API e o banco do
projeto web; o aplicativo nunca se conecta diretamente ao MongoDB.

## Estado atual

- Interface Material 3 em português para visão geral, lançamentos, análise,
  métricas, orçamentos, fundos e metas.
- Login com a sessão `fp_session` da API existente. O token de sessão fica no
  armazenamento seguro do aparelho.
- Modo de demonstração com dados fictícios para revisar a interface sem API.
- Exportação autenticada dos dados pessoais em JSON, cópia local financeira em
  JSON, importação de JSON financeiro (inclusive do arquivo de portabilidade)
  e solicitação de eliminação de dados pela API.
- Rascunhos pendentes guardados no armazenamento seguro do aparelho, por conta.
  Após reiniciar, o aplicativo recupera o rascunho e pede nova tentativa de
  gravação. A interface oferece uma cópia local antes de descartá-lo.
- Gravação condicional com revisão da API: alterações de dois aparelhos não
  substituem silenciosamente umas às outras. Em conflito, a tela permite
  comparar resumos, exportar a cópia local e escolher qual versão manter.
- Cards e análise adaptados a telas compactas e texto ampliado, com leitura
  semântica dos indicadores principais.
- Indicadores de consumo, aportes, orçamentos, patrimônio, histórico mensal e
  projeção simples do mês. Área administrativa com indicadores agregados.

O [roteiro de evolução](docs/ROADMAP.md) organiza as próximas melhorias de
integridade dos dados, acessibilidade, layout, desempenho e uso com rede
instável, com critérios de aceite para cada fase.

O endereço da API ainda não está definido. Sem `API_BASE_URL`, o aplicativo
oferece a opção **Explorar demonstração** e o login local abaixo:

- E-mail: `demo@financelab.local`
- Senha: `demo123`

Essas credenciais são públicas e dão acesso apenas a dados fictícios no
aparelho. São reconhecidas antes de qualquer chamada à API, inclusive em um
APK que também tenha `API_BASE_URL`. O botão de demonstração continua
disponível nos dois casos. Nenhum dado da demonstração é enviado ao servidor
ou preservado depois de sair.

## Preparar e executar

Requer Flutter 3.47.7 (a mesma versão da integração contínua), Android SDK e
um emulador ou aparelho Android. Na raiz deste repositório:

```bash
flutter pub get
flutter doctor -v
flutter devices
flutter run
```

Quando a API estiver publicada em HTTPS e `/api/health` responder `200`, use:

```bash
flutter run --dart-define=API_BASE_URL=https://seu-dominio.example
```

`API_BASE_URL` é configuração pública do aplicativo, não um local para senhas
ou chaves. O login usa `POST /api/auth/login`, recebe o cookie HTTP-only
`fp_session` e usa `GET /api/auth/me` para restaurar a sessão. Os dados usam
`GET/PUT /api/finance-data`. O GET precisa devolver `ETag: "rev-N"`; o app
envia esse valor em `If-Match` no PUT. O servidor retorna `412` quando a
revisão mudou e `428` quando falta a revisão. Publique o backend atualizado
antes de distribuir um APK conectado a contas reais; sem ETag, o app recusa a
gravação para preservar os dados. O backend precisa estar acessível pelo aparelho.

## Verificar e gerar um APK de teste

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

O APK de teste fica em `build/app/outputs/flutter-apk/app-debug.apk` e pode ser
instalado com `adb install`. Para incluir a API no APK, passe
`--dart-define=API_BASE_URL=https://seu-dominio.example` ao comando de build.

## Versionamento e versões demo

O código usa Git na branch `main`. A versão do aplicativo fica em
`pubspec.yaml`, no formato `MAJOR.MINOR.PATCH+BUILD`. O Flutter usa
`MAJOR.MINOR.PATCH` como `versionName` do Android e `BUILD` como
`versionCode`. A cada APK distribuído, aumente `BUILD`; não reutilize uma
tag. A primeira demo foi `0.1.0+1` / `v0.1.0-demo.1`; a segunda usa
`0.1.0+2` / `v0.1.0-demo.2`; esta revisão usa
`0.1.0+3` / `v0.1.0-demo.3`.

Para publicar uma nova demo, faça commit do novo `version` na `main`, envie
a branch e execute:

```bash
./tool/release_demo.sh
```

O script exige `main` limpa e sincronizada, roda análise/testes/build, confere
`versionCode`, `versionName` e o certificado da demo anterior, cria a tag Git
e publica o APK como prévia no GitHub. Requer Flutter, Android SDK e `gh`
autenticado. As demos precisam ser compiladas neste ambiente com a mesma
chave de depuração local para permitir atualização sobre a instalação anterior.
O CI também verifica a relação entre `pubspec.yaml` e tags demo. Para um
lançamento de produção, use assinatura própria e uma tag `vMAJOR.MINOR.PATCH`.

## Assinatura e distribuição Android

Uma build de release **nunca** usa a chave de depuração. Antes de executar
`flutter build apk --release` ou `flutter build appbundle --release`, crie uma
chave de produção fora do repositório e o arquivo local
`android/key.properties` (ambos ignorados pelo Git):

```properties
# Caminho relativo a android/app, ou absoluto, para o seu arquivo de chave.
storeFile=../../segredos/financelab-upload.jks
storePassword=senha-do-cofre
keyAlias=financelab-upload
keyPassword=senha-da-chave
```

Guarde as senhas em um cofre de segredos; não as passe por `--dart-define`, não
as registre em CI e não versione `key.properties` nem a chave. Sem as quatro
propriedades e um `storeFile` legível, tarefas de release falham com uma
mensagem explícita. Para publicar na Play Store, gere um AAB assinado:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://seu-dominio.example
```

O repositório inclui CI em GitHub Actions que executa análise, testes e uma
build de depuração. A assinatura de produção permanece exclusivamente no
ambiente de distribuição.

## Organização

- `lib/domain`: modelos, valores monetários em centavos e resumo financeiro.
- `lib/data`: cliente HTTP, sessão e rascunhos em armazenamento seguro.
- `lib/ui`: tema Material 3 e telas.
- `lib/app_controller.dart`: estado da sessão e fila de gravações.
- `.agents/skills`: skills Flutter selecionadas de
  [Flutter-AI-Skills](https://github.com/viniprati/Flutter-AI-Skills).

O documento financeiro inteiro é gravado pela API. As gravações do aplicativo
são sequenciais e usam revisão/ETag para impedir sobrescrita concorrente no
servidor. O rascunho local continua disponível para exportação ou descarte
explícito; uma resposta perdida é conferida com nova leitura antes de repetir
o PUT. A decisão de manter a cópia do aparelho sobre a do servidor requer
confirmação e uma nova verificação da revisão. Ainda não há sincronização
offline automática nem mesclagem por item. Exportação em PDF/XLSX do site
ainda não foi portada; o aplicativo oferece JSON compatível.

O app não é uma entrega de produção enquanto não houver uma API pública HTTPS
configurada e testada no aparelho: sem `API_BASE_URL`, ele funciona apenas no
modo de demonstração.
