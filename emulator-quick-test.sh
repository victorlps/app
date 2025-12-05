#!/bin/bash
# Script RÁPIDO para testar alarme no emulador
# Simula movimento de 5km até 100m do destino

export ANDROID_SDK_ROOT=~/Android/Sdk
ADB="$ANDROID_SDK_ROOT/platform-tools/adb -s emulator-5554"

echo "🚗 Teste Rápido: Simulando aproximação ao destino..."
echo ""

# Verificar conexão
if ! $ADB shell getprop sys.boot_completed > /dev/null 2>&1; then
    echo "❌ Emulador desconectado"
    exit 1
fi

# Posição 1: 5km de distância
echo "1️⃣  Posição inicial (5km de distância)..."
$ADB emu geo fix -46.656139 -23.561414
sleep 4

# Posição 2: 2km de distância  
echo "2️⃣  Movimento (2km de distância)..."
$ADB emu geo fix -46.646139 -23.551414
sleep 4

# Posição 3: 500m de distância
echo "3️⃣  Aproximando (500m de distância)..."
$ADB emu geo fix -46.644139 -23.549414
sleep 4

# Posição 4: 200m de distância
echo "4️⃣  Muito perto (200m - limite de alarme)..."
$ADB emu geo fix -46.643139 -23.548414
sleep 4

# Posição 5: 50m (deve disparar alarme!)
echo "5️⃣  CRÍTICO! (50m - alarme deve soar!)... 🔔"
$ADB emu geo fix -46.642889 -23.548164
sleep 2

echo ""
echo "✅ Teste concluído!"
echo "   Verifique no emulador se o alarme disparou."
echo ""
echo "   Se não disparou:"
echo "   - Ver logs: adb -s emulator-5554 logcat | grep -i alarm"
echo "   - Aumentar distância de alerta para 1km"
echo "   - Executar script de novo"
