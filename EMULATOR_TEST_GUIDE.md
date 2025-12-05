# Guia: Testando o Alarme de Chegada com Emulador

## Status Atual
✅ Emulador Pixel_8 rodando
✅ App instalado no emulador
✅ Script de simulação de GPS criado

## Como Testar

### 1. Verifique o App no Emulador
O app já deve estar aberto. Se não estiver:
```bash
export ANDROID_SDK_ROOT=~/Android/Sdk
$ANDROID_SDK_ROOT/platform-tools/adb -s emulator-5554 shell am start -n com.example.avisa_la/com.example.avisa_la.MainActivity
```

### 2. Selecione um Destino no Emulador
- Na tela principal, busque por um endereço
- Use algo como "Av Brasil, São Paulo" ou qualquer lugar próximo ao ponto de teste
- O ponto inicial de teste é: **Av Paulista, São Paulo** (-23.561414, -46.656139)

### 3. Inicie o Monitoramento
- Selecione o destino
- Clique em "Iniciar Monitoramento"
- Configure:
  - Distância de alerta: 200m (padrão)
  - Modo: Dinâmico (para testar com Google Maps API)
  - Tempo: 5 minutos (padrão)

### 4. Rode o Script de Simulação GPS
Em outro terminal:
```bash
cd /home/vlps/dev/avisa_la_e/app
./emulator-gps-test.sh
```

O script vai:
1. Enviar posição inicial (Av Paulista)
2. Simular 5 passos de movimento gradual até Av Brasil (~2km)
3. Cada passo leva ~5 segundos
4. Total: ~30 segundos

### 5. Observe no Emulador
**Enquanto o script roda, veja no emulador:**
- ✅ Localização atualizando (icone GPS)
- ✅ Distância diminuindo na tela de monitoramento
- ✅ Tempo estimado atualizando
- ✅ Mapa mostrando seu movimento

### 6. Espere o Alarme
Quando a distância ficar ≤ 200m (ou tempo ≤ 5 min em modo dinâmico):
- 🔔 Notificação deve aparecer
- 📢 Som do alarme
- 📳 Vibração

## Alternativas de Teste

### Teste Rápido sem Script
```bash
export ANDROID_SDK_ROOT=~/Android/Sdk
ADB="$ANDROID_SDK_ROOT/platform-tools/adb -s emulator-5554"

# Posição 1: 5km de distância
$ADB emu geo fix -46.656139 -23.561414

sleep 3

# Posição 2: 1km de distância
$ADB emu geo fix -46.646139 -23.551414

sleep 3

# Posição 3: 100m (deve disparar alarme!)
$ADB emu geo fix -46.645739 -23.551014
```

### Aumentar Distância DE ALERTA para Teste Mais Fácil
Se quiser testar de novo rapidinho, aumente a distância:
1. Volte à home
2. Selecione destino de novo
3. Configure distância: **1000m** (1km) em vez de 200m
4. Execute script de novo

## Logs para Debug
Ver logs enquanto testa:
```bash
export ANDROID_SDK_ROOT=~/Android/Sdk
$ANDROID_SDK_ROOT/platform-tools/adb -s emulator-5554 logcat | grep -E "(flutter|GPS|Alarme|Notif|Distance)"
```

## Problemas?

### Emulador offline
```bash
export ANDROID_SDK_ROOT=~/Android/Sdk
$ANDROID_SDK_ROOT/platform-tools/adb kill-server
$ANDROID_SDK_ROOT/platform-tools/adb start-server
$ANDROID_SDK_ROOT/platform-tools/adb devices
```

### App não abre
```bash
export ANDROID_SDK_ROOT=~/Android/Sdk
$ANDROID_SDK_ROOT/platform-tools/adb -s emulator-5554 shell pm list packages | grep avisa
```

### Simular GPS manual (telnet)
```bash
telnet localhost 5554
geo fix -46.656139 -23.561414
exit
```

## Próximos Passos
1. Executar teste
2. Validar se alarme toca
3. Se não tocar, coletar logs
4. Debugar problema específico
