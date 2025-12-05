#!/bin/bash
# Script para simular movimento de GPS no emulador
# Uso: ./emulator-gps-test.sh

export ANDROID_SDK_ROOT=~/Android/Sdk
ADB="$ANDROID_SDK_ROOT/platform-tools/adb -s emulator-5554"

# Coordenadas de teste (São Paulo, Brasil)
# Ponto inicial: Av Paulista (perto de Consolação)
START_LAT="-23.561414"
START_LON="-46.656139"

# Ponto final: Av Brasil (cerca de 2km de distância)
END_LAT="-23.541414"
END_LON="-46.636139"

echo "🗺️  Iniciando simulação de GPS no emulador..."
echo "Ponto inicial: $START_LAT, $START_LON"
echo "Ponto final: $END_LAT, $END_LON"

# Verificar se o emulador está conectado
if ! $ADB shell getprop sys.boot_completed > /dev/null 2>&1; then
    echo "❌ Emulador não respondendo. Verifique a conexão."
    exit 1
fi

echo "✅ Emulador conectado"

# Enviar coordenadas iniciais
echo "📍 Enviando posição inicial..."
$ADB emu geo fix $START_LON $START_LAT

sleep 3

# Simular movimento em direção ao destino
echo "🚗 Simulando movimento..."

# Criar pontos intermediários (5 passos)
for i in {1..5}; do
    # Calcular posição intermediária (interpolação linear)
    PROGRESS=$(echo "scale=4; $i / 5" | bc)
    
    LAT=$(echo "$START_LAT + ($END_LAT - $START_LAT) * $PROGRESS" | bc)
    LON=$(echo "$START_LON + ($END_LON - $START_LON) * $PROGRESS" | bc)
    
    echo "  Passo $i/5: Lat=$LAT, Lon=$LON"
    $ADB emu geo fix $LON $LAT
    
    sleep 5  # Aguardar 5 segundos entre atualizações
done

# Enviar velocidade simulada (aproximadamente 15 km/h = 4.17 m/s)
echo "⚡ Simulando velocidade (4.17 m/s)..."
$ADB emu geo fix $END_LON $END_LAT 4.17

echo "✅ Simulação concluída!"
echo ""
echo "Próximas ações:"
echo "1. Abra o app no emulador"
echo "2. Selecione um destino próximo ao ponto final"
echo "3. Inicie o monitoramento"
echo "4. Observe a distância diminuindo e o tempo estimado"
echo "5. O alarme deve disparar quando chegar perto do destino"
