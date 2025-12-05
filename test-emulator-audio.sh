#!/bin/bash
# Script para testar áudio no emulador

export ANDROID_SDK_ROOT=~/Android/Sdk
ADB="$ANDROID_SDK_ROOT/platform-tools/adb -s emulator-5554"

echo "🔊 Testando áudio no emulador..."
echo ""

# 1. Verificar volumes
echo "1️⃣  Verificando volumes..."
RING=$($ADB shell settings get system volume_ring)
NOTIF=$($ADB shell settings get system volume_notification)
MUSIC=$($ADB shell settings get system volume_music)
ALARM=$($ADB shell settings get system volume_alarm)

echo "   Ring: $RING"
echo "   Notification: $NOTIF"
echo "   Music: $MUSIC"
echo "   Alarm: $ALARM"
echo ""

# 2. Aumentar volumes ao máximo
echo "2️⃣  Aumentando volumes ao máximo..."
$ADB shell "settings put system volume_ring 7 && settings put system volume_notification 7 && settings put system volume_music 7 && settings put system volume_alarm 7"
echo "   ✅ Volumes em máximo"
echo ""

# 3. Desativar modo silencioso
echo "3️⃣  Desativando modo silencioso..."
$ADB shell "settings put global zen_mode 0"
echo "   ✅ Modo silencioso desativado"
echo ""

# 4. Tocar um som de teste
echo "4️⃣  Tocando som de teste..."
echo "   Use: adb -s emulator-5554 shell am broadcast -a android.media.RINGTONE_PICKER"
$ADB shell "am broadcast -a android.intent.action.RINGTONE_PICKED"
echo ""

# 5. Tentar tocar arquivo de som de teste
echo "5️⃣  Tocando alarme do sistema..."
$ADB shell "am startservice -a android.intent.action.VIEW -d file:///system/media/audio/alarms/Argon.ogg"
sleep 3

echo "✅ Teste concluído!"
echo ""
echo "Se não ouviu nada:"
echo "  1. Verifique volume do computador"
echo "  2. Verifique se emulador tem saída de áudio"
echo "  3. Tente telnet para tocar som manualmente:"
echo "     telnet localhost 5554"
echo "     avdevice volume call 15"
echo "     exit"
