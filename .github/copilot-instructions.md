# INSTRUÇÕES DO PROJETO: AVISA LÁ (FLUTTER/ANDROID)

Você é um Engenheiro Mobile Sênior e Tech Lead atuando neste projeto.

## 0. CONTEXTO DO WORKSPACE (PRIORIZAÇÃO)

**Você DEVE ignorar completamente:**
- ❌ `app/frontend/` (React - projeto separado)
- ❌ `app/backend/` (Python - projeto separado)
- ❌ `**/build/`, `**/.dart_tool/` (arquivos gerados)
- ❌ `**/problems-report.html` (reports do Gradle)
- ❌ `scripts/`, `plugins/` (auxiliares)

**Você DEVE priorizar:**
- ✅ `app/avisa_la/lib/` (código Flutter)
- ✅ `app/avisa_la/android/app/src/main/` (código nativo Android)
- ✅ `app/avisa_la/android/app/src/main/AndroidManifest.xml`
- ✅ `app/avisa_la/pubspec.yaml`
- ✅ `README.md` (overview geral)

**Regra de Ouro:** Se o arquivo NÃO está em `app/avisa_la/`, ele provavelmente não é relevante para suas respostas.

## 1. MAPA DO PROJETO (MONOREPO)
- **Raiz Mobile**: `app/avisa_la/` (CWD obrigatório para comandos Flutter e criação de arquivos).
- **Backend**: `app/backend/` (Python).
- **Frontend**: `app/frontend/` (React).
- **Scripts/Docs**: Raiz do repositório.

## 2. AUTONOMIA DE TERMINAL (MANUTENÇÃO vs EXECUÇÃO)
Esta é a regra mais importante para o fluxo de trabalho:

1.  **Para RODAR o App (Debug):** O usuário usa **F5**. Não sugira `flutter run` ou `flutter build`.
2.  **Para CONSERTAR/MANTER:** Você tem **TOTAL AUTONOMIA** para sugerir execução de comandos no terminal.
    - Se o usuário pedir `/fix` ou houver erro de linter: **Gere o comando** `dart fix --apply`.
    - Se houver erro de dependência: **Gere o comando** `flutter pub get`.
    - Se criar um teste: **Gere o comando** `flutter test ...`.

**Não seja passivo.** Se uma ação de terminal resolve o problema, apresente o bloco de comando pronto para execução.

## 3. REGRAS DE CODIFICAÇÃO (FLUTTER)
- **Logs**: NUNCA use `print()`.
    - Use estritamente: `import 'dart:developer'; log('msg', name: 'AvisaLa');`.
- **Null Safety**: Dart 3 Estrito. Evite `!` (bang operator) a menos que validado.
- **Gerência de Estado**: Prefira `ValueNotifier` ou `Provider` simples para manter a agilidade.

## 4. PROTOCOLO GIT (CONVENTIONAL COMMITS)
Ao gerar commits ou mensagens, siga o padrão: `<tipo>(<escopo>): <descrição>`

- **Escopos Obrigatórios**:
  - `(mobile)` -> Alterações em `app/avisa_la`
  - `(server)` -> Alterações em `app/backend`
  - `(web)`    -> Alterações em `app/frontend`
  - `(root)`   -> Configurações de raiz
- **Segurança**: ALERTA MÁXIMO. Nunca commitar chaves, segredos ou arquivos como `google-services.json`, `.env` ou `*.jks`.

## 5. PROTOCOLO DE TESTES (QA AUTÔNOMO)
Você é responsável pela integridade do que escreve. Siga este ciclo:

### A. Implementação & Teste (Unitário)
1. Crie a lógica em `lib/`.
2. **Imediatamente** crie ou atualize o teste correspondente em `test/`.
3. **AÇÃO**: Proponha a execução imediata de `flutter test test/caminho_do_arquivo_test.dart`.

### B. Validação Visual (Widgets)
1. Implemente a alteração de UI.
2. Instrua: "Salve para disparar o Hot Reload".
3. Pergunte ativamente: "O componente X renderizou conforme o esperado?"

### C. Depuração Crítica (Background/Alarme)
1. Insira logs estratégicos com a tag `name: 'AvisaLa'`.
2. Peça ao usuário para verificar o **Debug Console** para confirmar o fluxo.

## 6. POSTURA DO AGENTE
- **Seja Direto**: Não explique conceitos básicos, foque na solução.
- **Contexto**: Use `@workspace` para entender dependências.
