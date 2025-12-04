# Scripts de Build Otimizado - Avisa Lá

## 🚀 Scripts Disponíveis

### 1. `./run-hot.sh` - **DESENVOLVIMENTO** ⚡ **RECOMENDADO**
```bash
./run-hot.sh
```
- ✅ Hot reload (~2s por mudança)
- ✅ Debug mode (rápido!)
- ✅ Ideal para 99% do desenvolvimento
- Pressione `r` para hot reload, `R` para restart, `q` para sair

---

### 2. `./build-install-fast.sh` - Debug Build Rápido
```bash
./build-install-fast.sh
```
- ✅ Versão incrementada automaticamente
- ✅ Debug mode (1-2 min de build)
- ✅ Instala no dispositivo
- Use para testes rápidos

---

### 3. `./build-release.sh` - Release Final
```bash
./build-release.sh
```
- ✅ Versão incrementada automaticamente
- ✅ Release mode otimizado (6 min de build)
- ✅ Instala no dispositivo
- ⚠️ **Use APENAS para versão final/produção**

---

### 4. `./increment-version.sh` - Bump Versão
```bash
./increment-version.sh
```
- Manual: incrementa build number em pubspec.yaml

---

## 📊 Comparação

| Script | Modo | Tempo | Uso |
|--------|------|-------|-----|
| `run-hot.sh` | Debug | ~30s* + 2s reload | Desenvolvimento |
| `build-install-fast.sh` | Debug | ~1-2 min | Testes rápidos |
| `build-release.sh` | Release | ~6 min | Produção |

*Primeira vez. Depois é hot reload em 2s.

---

## 🎯 Fluxo Recomendado

### Desenvolvimento (99% do tempo):
```bash
./run-hot.sh          # Inicia uma vez
# Edita código
# Pressiona 'r'      # Vê mudança em 2s
# Repete
```

### Antes de submeter:
```bash
./build-install-fast.sh  # Debug build rápido
```

### Produção (raríssimo):
```bash
./build-release.sh  # Release otimizado
```

---

## 💡 Por que não usar Release em Dev?

**Antes (release toda vez):**
```
Mudança: 30s
Build release: 6 min ❌
Instala: 30s
Resultado: 1s
Total: ~7 min POR mudança 😫
```

**Agora (hot reload):**
```
Mudança: 30s
Hot reload: 2s ✅
Resultado: 1s
Total: ~33s POR mudança 🚀
```

**Economia: 6:30 por mudança = 1 hora/dia em 10 mudanças!**

---

## 🔧 Resumo

```
run-hot.sh           → Hot reload (padrão)
build-install-fast   → Debug build (testes)
build-release.sh     → Release final (raro)
```

## 🎁 Bônus: Versão Automática

- Cada build incrementa automaticamente a versão
- Mostrada no AppBar da HomePage
- Recarrega em runtime
