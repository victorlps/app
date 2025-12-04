#!/bin/bash
# Build release (otimizado) - Use APENAS para versão final/produção

set -e

echo "🔢 Incrementando versão..."
./increment-version.sh

echo "🏗️  Compilando APK (release - otimizado para produção)..."
cd avisa_la
flutter build apk --release

echo "📱 Instalando no dispositivo..."
flutter install -d RQCW307SRFT

echo "✅ Build release concluído!"
