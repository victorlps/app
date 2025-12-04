#!/bin/bash
# Reinstalar app com as mudanças mais recentes

set -e

cd /home/vlps/dev/avisa_la_e/app/avisa_la

echo "🧹 Limpando cache..."
flutter clean

echo "📦 Instalando dependências..."
flutter pub get

echo "🔨 Compilando debug APK..."
flutter build apk --debug

echo "📱 Instalando no dispositivo..."
adb -s RQCW307SRFT install -r build/app/outputs/flutter-apk/app-debug.apk

echo "🚀 Abrindo app..."
sleep 2
adb -s RQCW307SRFT shell am start -n com.example.avisa_la/.MainActivity

echo "✅ Reinstalação completa! Mudanças devem estar visíveis."
