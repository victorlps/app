#!/bin/bash
# Script para incrementar automaticamente a versão do app

PUBSPEC_FILE="avisa_la/pubspec.yaml"

# Ler versão atual
CURRENT_VERSION=$(grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //')
VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

# Incrementar build number
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_VERSION="${VERSION_NAME}+${NEW_BUILD_NUMBER}"

# Atualizar pubspec.yaml
sed -i "s/^version: .*/version: ${NEW_VERSION}/" "$PUBSPEC_FILE"

echo "✅ Versão atualizada: ${CURRENT_VERSION} → ${NEW_VERSION}"
