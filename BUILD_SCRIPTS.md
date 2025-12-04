# Scripts de Build - Avisa Lá

## 🚀 Scripts Disponíveis

### 1. `./run-hot.sh` - **DESENVOLVIMENTO RÁPIDO** ⚡
**Uso:** Testes rápidos com hot reload
```bash
./run-hot.sh
```
- ✅ Inicia em modo debug (~30s primeira vez)
- ✅ Hot reload ativo (pressione 'r')
- ✅ Mudanças em segundos (sem rebuild)
- ✅ Ideal para testar UI e lógica

**Comandos durante execução:**
- `r` - Hot reload (rápido, mantém estado)
- `R` - Hot restart (reinicia app)
- `q` - Sair

---

### 2. `./build-install-fast.sh` - Build Release com Versão
**Uso:** Build completo com versão incrementada
```bash
./build-install-fast.sh
```
- ✅ Incrementa versão automaticamente (1.0.0+2 → 1.0.0+3)
- ✅ Build release otimizado
- ✅ Instala no dispositivo
- ⏱️ ~6 minutos (Gradle)

---

### 3. `./increment-version.sh` - Apenas Incrementar Versão
**Uso:** Incrementa build number sem fazer build
```bash
./increment-version.sh
```
- Atualiza `pubspec.yaml`
- Exemplo: `1.0.0+5` → `1.0.0+6`

---

### 4. `./build-install.sh` - Build Original
**Uso:** Build e install tradicional
```bash
./build-install.sh
```
- Build release padrão
- Sem incremento automático de versão

---

## 📋 Fluxo Recomendado

### Para desenvolvimento diário:
```bash
# 1. Inicie em modo debug (primeira vez ~30s)
./run-hot.sh

# 2. Faça mudanças no código
# 3. Pressione 'r' no terminal (hot reload em ~2s)
# 4. Repita quantas vezes precisar
```

### Para build final/teste completo:
```bash
# Incrementa versão + build + install
./build-install-fast.sh
```

---

## 🎯 Versão Dinâmica

A versão mostrada no app é carregada automaticamente do `pubspec.yaml`:
- **Automático:** Usa `package_info_plus`
- **Atualiza:** A cada `build-install-fast.sh`
- **Formato:** `v1.0.0+build`

---

## ⚡ Hot Reload vs Release Build

| Aspecto | Hot Reload | Release Build |
|---------|------------|---------------|
| **Tempo** | ~2s | ~6min |
| **Uso** | Desenvolvimento | Produção |
| **Quando** | 99% do tempo | Build final |
| **Script** | `run-hot.sh` | `build-install-fast.sh` |

---

## 💡 Dicas

1. **Use hot reload para tudo**: UI, lógica, correções rápidas
2. **Release apenas quando**: Testar background service, notificações, build final
3. **Versão automática**: Sempre use `build-install-fast.sh` para releases
4. **Primeira execução**: Hot reload demora ~30s, depois é instantâneo
