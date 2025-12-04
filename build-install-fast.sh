#!/bin/bash
# Build e install rápido com incremento automático de versão
# Usa DEBUG mode (muito mais rápido) para desenvolvimento

set -e

echo "🔢 Incrementando versão..."
./increment-version.sh

echo "🏗️  Compilando APK (debug - RÁPIDO)..."
cd avisa_la
flutter build apk --debug

echo "📱 Instalando no dispositivo..."
flutter install -d RQCW307SRFT

echo "✅ Build e instalação concluídos em tempo recorde!"
