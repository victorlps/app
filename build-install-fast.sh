#!/bin/bash
# Build e install rápido com incremento automático de versão

set -e

echo "🔢 Incrementando versão..."
./increment-version.sh

echo "🏗️  Compilando APK (release)..."
cd avisa_la
flutter build apk --release

echo "📱 Instalando no dispositivo..."
flutter install -d RQCW307SRFT

echo "✅ Build e instalação concluídos!"
