# Android Gesture Navigation - Análise do Problema

## 🔍 Problema Identificado

O usuário relata que:
- A caixa com destino e botões está **subindo** (reduzindo espaço superior)
- Mas o espaço **inferior permanece igual**, ficando **sobreposto pela barra de navegação**
- Barra de navegação configurada em modo **gesture** (invisível, aparece ao deslizar de baixo para cima)

## 📚 Conceitos do Android

### Tipos de Navegação

1. **Three-button navigation** (3 botões): back, home, recents
   - Barra sempre visível
   - `MediaQuery.of(context).viewPadding.bottom` retorna altura da barra (~48dp)

2. **Gesture navigation** (gestos):
   - Barra **invisível** por padrão
   - Apenas linha fina na parte inferior (~10-20dp)
   - Aparece ao deslizar de baixo para cima
   - `MediaQuery.of(context).viewPadding.bottom` pode retornar 0 ou valor pequeno

### SystemUiMode no Android

Android 10+ (API 29+) introduziu:
- **Edge-to-edge**: App ocupa tela inteira, incluindo áreas do sistema
- **Insets**: Sistema informa quais áreas são ocupadas por barras do sistema

## ⚠️ Problema do SafeArea

```dart
SafeArea(
  maintainBottomViewPadding: true,
  child: Container(...)
)
```

**O que acontece:**
- `SafeArea` lê `MediaQuery.viewPadding.bottom`
- Em gesture navigation, esse valor pode ser 0 ou muito pequeno
- `maintainBottomViewPadding: true` **não adiciona padding**, apenas mantém o existente
- Resultado: conteúdo fica sobreposto à área de gestos

## ✅ Solução Correta

### Opção 1: Usar viewInsets + viewPadding
```dart
final bottomInset = MediaQuery.of(context).viewInsets.bottom;
final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
final totalBottom = bottomInset + bottomPadding;

Positioned(
  bottom: 0,
  child: Container(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: 16 + totalBottom, // Adiciona espaço para gestos
    ),
  ),
)
```

### Opção 2: Usar SafeArea + padding extra
```dart
SafeArea(
  minimum: const EdgeInsets.only(bottom: 16), // Padding mínimo garantido
  child: Container(
    padding: const EdgeInsets.all(16),
    ...
  ),
)
```

### Opção 3: MediaQuery.removePadding + padding manual
```dart
MediaQuery.removePadding(
  context: context,
  removeTop: false,
  removeBottom: true,
  child: Container(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: 16 + MediaQuery.of(context).viewPadding.bottom.clamp(16.0, 100.0),
    ),
  ),
)
```

## 🎯 Implementação Recomendada

Para **home_page.dart** (Card de destino):
```dart
Positioned(
  bottom: 0,
  left: 16,
  right: 16,
  child: SafeArea(
    minimum: const EdgeInsets.only(bottom: 16), // Garante espaço mínimo
    child: Card(
      child: Padding(...),
    ),
  ),
)
```

Para **trip_monitoring_page.dart** (Botões de ação):
```dart
Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: Container(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: 16 + MediaQuery.of(context).viewPadding.bottom.clamp(8.0, 48.0),
    ),
    color: Colors.white,
    child: Column(...),
  ),
)
```

## 🧪 Como Testar

1. **Verificar tipo de navegação:**
```dart
debugPrint('Bottom padding: ${MediaQuery.of(context).viewPadding.bottom}');
debugPrint('Bottom inset: ${MediaQuery.of(context).viewInsets.bottom}');
```

2. **Testar nos 2 modos:**
   - Configurações → Sistema → Gestos → Navegação do sistema
   - Alternar entre "Navegação com gestos" e "Navegação com 3 botões"

3. **Verificar edge-to-edge:**
   - Em `android/app/src/main/res/values/styles.xml`
   - Procurar por `windowDrawsSystemBarBackgrounds` ou `windowTranslucentNavigation`

## 📖 Referências

- [Flutter SafeArea](https://api.flutter.dev/flutter/widgets/SafeArea-class.html)
- [MediaQuery](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html)
- [Android Gesture Navigation](https://developer.android.com/develop/ui/views/layout/edge-to-edge)
