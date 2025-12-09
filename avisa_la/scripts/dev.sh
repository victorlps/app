#!/bin/bash

# Script de desenvolvimento para Avisa Lá
# Otimizado para Samsung S23 + Pop!_OS

set -e

PROJECT_DIR="avisa_la"
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo -e "${BOLD}🚀 Avisa Lá - Dev Helper${NC}"
    echo ""
    echo -e "${BLUE}Comandos de Desenvolvimento:${NC}"
    echo ""
    echo -e "  ${GREEN}start${NC}          Inicia o app no S23 (debug mode)"
    echo -e "  ${GREEN}stop${NC}           Para o app em execução"
    echo -e "  ${GREEN}restart${NC}        Reinicia o app"
    echo -e "  ${GREEN}logs${NC}           Mostra logs do Flutter"
    echo -e "  ${GREEN}adb-logs${NC}       Mostra logs do Android (filtrado)"
    echo ""
    echo -e "${BLUE}Testes:${NC}"
    echo ""
    echo -e "  ${GREEN}test${NC}           Executa todos os testes"
    echo -e "  ${GREEN}test-watch${NC}     Executa testes em modo watch"
    echo -e "  ${GREEN}coverage${NC}       Gera relatório de cobertura"
    echo ""
    echo -e "${BLUE}Análise e Formatação:${NC}"
    echo ""
    echo -e "  ${GREEN}analyze${NC}        Analisa o código"
    echo -e "  ${GREEN}format${NC}         Formata todo o código"
    echo -e "  ${GREEN}fix${NC}            Aplica fixes automáticos"
    echo ""
    echo -e "${BLUE}Manutenção:${NC}"
    echo ""
    echo -e "  ${GREEN}clean${NC}          Limpa build e reinstala dependências"
    echo -e "  ${GREEN}pub-get${NC}        Atualiza dependências"
    echo -e "  ${GREEN}pub-upgrade${NC}    Atualiza para últimas versões"
    echo -e "  ${GREEN}pub-outdated${NC}   Lista dependências desatualizadas"
    echo ""
    echo -e "${BLUE}Build:${NC}"
    echo ""
    echo -e "  ${GREEN}build-debug${NC}    Gera APK debug"
    echo -e "  ${GREEN}build-release${NC}  Gera APK release"
    echo -e "  ${GREEN}install${NC}        Instala APK debug no S23"
    echo ""
    echo -e "${BLUE}Dispositivo:${NC}"
    echo ""
    echo -e "  ${GREEN}devices${NC}        Lista dispositivos conectados"
    echo -e "  ${GREEN}s23-check${NC}      Verifica conexão do S23"
    echo -e "  ${GREEN}s23-info${NC}       Informações detalhadas do S23"
    echo -e "  ${GREEN}s23-screenshot${NC} Captura tela do S23"
    echo -e "  ${GREEN}adb-restart${NC}    Reinicia servidor ADB"
    echo ""
    echo -e "${BLUE}Diagnóstico:${NC}"
    echo ""
    echo -e "  ${GREEN}doctor${NC}         Executa flutter doctor"
    echo -e "  ${GREEN}permissions${NC}    Verifica permissões do app"
    echo -e "  ${GREEN}service-status${NC} Status do background service"
    echo ""
    echo -e "${YELLOW}💡 Dica: Durante o desenvolvimento, use hot reload (Ctrl+S no VS Code)${NC}"
}

check_s23() {
    if flutter devices 2>/dev/null | grep -qi "SM-S911B\|samsung\|s23"; then
        return 0
    else
        return 1
    fi
}

get_s23_id() {
    flutter devices 2>/dev/null | grep -i "SM-S911B\|samsung\|s23" | awk '{print $5}' | tr -d '•' | head -1
}

cmd_start() {
    if ! check_s23; then
        echo -e "${RED}❌ S23 não detectado!${NC}"
        echo "Execute: adb devices"
        exit 1
    fi
    
    S23_ID=$(get_s23_id)
    echo -e "${GREEN}🚀 Iniciando Avisa Lá no S23...${NC}"
    echo -e "${YELLOW}Device ID: $S23_ID${NC}"
    echo ""
    
    cd "$PROJECT_DIR"
    flutter run --debug \
        --device-id="$S23_ID" \
        --dart-define=ENVIRONMENT=dev
}

cmd_stop() {
    echo -e "${YELLOW}⏹️  Parando app...${NC}"
    # Encontra e mata processos do Flutter
    pkill -f "flutter run" || true
    echo -e "${GREEN}✓ App parado${NC}"
}

cmd_restart() {
    echo -e "${YELLOW}🔄 Reiniciando app...${NC}"
    cmd_stop
    sleep 2
    cmd_start
}

cmd_logs() {
    echo -e "${BLUE}📋 Logs do Flutter (Ctrl+C para sair)${NC}"
    echo ""
    cd "$PROJECT_DIR"
    flutter logs
}

cmd_adb_logs() {
    if ! check_s23; then
        echo -e "${RED}❌ S23 não detectado!${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}📋 Logs do Android - Filtrado para Avisa Lá (Ctrl+C para sair)${NC}"
    echo ""
    adb logcat | grep -i "flutter\|avisa\|geolocator\|notification\|background"
}

cmd_test() {
    echo -e "${GREEN}🧪 Executando testes...${NC}"
    cd "$PROJECT_DIR"
    flutter test
}

cmd_test_watch() {
    echo -e "${GREEN}👀 Executando testes em modo watch...${NC}"
    cd "$PROJECT_DIR"
    flutter test --watch
}

cmd_coverage() {
    echo -e "${GREEN}📊 Gerando cobertura de testes...${NC}"
    cd "$PROJECT_DIR"
    flutter test --coverage
    
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        echo -e "${GREEN}✓ Relatório HTML gerado: coverage/html/index.html${NC}"
        
        # Abrir no navegador se disponível
        if command -v xdg-open &> /dev/null; then
            xdg-open coverage/html/index.html 2>/dev/null &
        fi
    else
        echo -e "${YELLOW}⚠️  Instale lcov para gerar HTML: sudo apt install lcov${NC}"
    fi
}

cmd_analyze() {
    echo -e "${GREEN}🔍 Analisando código...${NC}"
    cd "$PROJECT_DIR"
    flutter analyze
}

cmd_format() {
    echo -e "${GREEN}✨ Formatando código...${NC}"
    cd "$PROJECT_DIR"
    dart format lib/ test/ -l 80
    echo -e "${GREEN}✓ Código formatado${NC}"
}

cmd_fix() {
    echo -e "${GREEN}🔧 Aplicando fixes automáticos...${NC}"
    cd "$PROJECT_DIR"
    dart fix --apply
    echo -e "${GREEN}✓ Fixes aplicados${NC}"
}

cmd_clean() {
    echo -e "${YELLOW}🧹 Limpando projeto...${NC}"
    cd "$PROJECT_DIR"
    flutter clean
    echo -e "${GREEN}📦 Reinstalando dependências...${NC}"
    flutter pub get
    echo -e "${GREEN}✓ Pronto!${NC}"
}

cmd_pub_get() {
    echo -e "${GREEN}📦 Atualizando dependências...${NC}"
    cd "$PROJECT_DIR"
    flutter pub get
}

cmd_pub_upgrade() {
    echo -e "${GREEN}⬆️  Atualizando para últimas versões...${NC}"
    cd "$PROJECT_DIR"
    flutter pub upgrade
}

cmd_pub_outdated() {
    echo -e "${GREEN}📋 Dependências desatualizadas:${NC}"
    cd "$PROJECT_DIR"
    flutter pub outdated
}

cmd_build_debug() {
    echo -e "${GREEN}📦 Gerando APK debug...${NC}"
    cd "$PROJECT_DIR"
    flutter build apk --debug
    echo -e "${GREEN}✓ APK gerado: build/app/outputs/flutter-apk/app-debug.apk${NC}"
}

cmd_build_release() {
    echo -e "${GREEN}🚀 Gerando APK release...${NC}"
    cd "$PROJECT_DIR"
    flutter build apk --release
    echo -e "${GREEN}✓ APK gerado: build/app/outputs/flutter-apk/app-release.apk${NC}"
}

cmd_install() {
    if ! check_s23; then
        echo -e "${RED}❌ S23 não detectado!${NC}"
        exit 1
    fi
    
    APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
    
    if [ ! -f "$APK_PATH" ]; then
        echo -e "${YELLOW}APK não encontrado. Gerando...${NC}"
        cmd_build_debug
    fi
    
    echo -e "${GREEN}📲 Instalando no S23...${NC}"
    adb install -r "$APK_PATH"
    echo -e "${GREEN}✓ Instalado!${NC}"
}

cmd_devices() {
    echo -e "${GREEN}📱 Dispositivos conectados:${NC}"
    echo ""
    flutter devices
}

cmd_s23_check() {
    echo -e "${YELLOW}🔍 Verificando S23...${NC}"
    
    if check_s23; then
        S23_ID=$(get_s23_id)
        echo -e "${GREEN}✅ S23 Conectado!${NC}"
        echo -e "Device ID: ${BLUE}$S23_ID${NC}"
    else
        echo -e "${RED}❌ S23 não encontrado!${NC}"
        echo ""
        echo "Troubleshooting:"
        echo "1. Conecte via USB"
        echo "2. Ative 'Depuração USB' no S23"
        echo "3. Execute: adb devices"
        echo "4. Autorize o computador no S23"
    fi
}

cmd_s23_info() {
    if ! check_s23; then
        echo -e "${RED}❌ S23 não detectado!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}📱 Informações do S23:${NC}"
    echo ""
    echo -e "${BOLD}Modelo:${NC}"
    adb shell getprop ro.product.model
    echo ""
    echo -e "${BOLD}Versão Android:${NC}"
    adb shell getprop ro.build.version.release
    echo ""
    echo -e "${BOLD}API Level:${NC}"
    adb shell getprop ro.build.version.sdk
    echo ""
    echo -e "${BOLD}Bateria:${NC}"
    adb shell dumpsys battery | grep level
    echo ""
    echo -e "${BOLD}Espaço Livre:${NC}"
    adb shell df -h /data | tail -1
}

cmd_s23_screenshot() {
    if ! check_s23; then
        echo -e "${RED}❌ S23 não detectado!${NC}"
        exit 1
    fi
    
    FILENAME="screenshot_$(date +%Y%m%d_%H%M%S).png"
    echo -e "${GREEN}📸 Capturando screenshot...${NC}"
    adb shell screencap -p | sed 's/\r$//' > "$FILENAME"
    echo -e "${GREEN}✓ Salvo: $FILENAME${NC}"
    
    if command -v xdg-open &> /dev/null; then
        xdg-open "$FILENAME" 2>/dev/null &
    fi
}

cmd_adb_restart() {
    echo -e "${YELLOW}🔄 Reiniciando servidor ADB...${NC}"
    adb kill-server
    sleep 1
    adb start-server
    sleep 2
    echo -e "${GREEN}✓ ADB reiniciado${NC}"
    echo ""
    adb devices
}

cmd_doctor() {
    echo -e "${GREEN}🏥 Flutter Doctor:${NC}"
    echo ""
    flutter doctor -v
}

cmd_permissions() {
    if ! check_s23; then
        echo -e "${RED}❌ S23 não detectado!${NC}"
        exit 1
    fi
    
    PACKAGE="com.example.avisa_la"
    
    echo -e "${GREEN}🔒 Permissões do Avisa Lá:${NC}"
    echo ""
    adb shell dumpsys package "$PACKAGE" | grep -A 20 "runtime permissions:"
}

cmd_service_status() {
    if ! check_s23; then
        echo -e "${RED}❌ S23 não detectado!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}⚙️  Status do Background Service:${NC}"
    echo ""
    adb shell dumpsys activity services | grep -A 10 "BackgroundService"
}

# Main
case "${1:-help}" in
    start) cmd_start ;;
    stop) cmd_stop ;;
    restart) cmd_restart ;;
    logs) cmd_logs ;;
    adb-logs) cmd_adb_logs ;;
    test) cmd_test ;;
    test-watch) cmd_test_watch ;;
    coverage) cmd_coverage ;;
    analyze) cmd_analyze ;;
    format) cmd_format ;;
    fix) cmd_fix ;;
    clean) cmd_clean ;;
    pub-get) cmd_pub_get ;;
    pub-upgrade) cmd_pub_upgrade ;;
    pub-outdated) cmd_pub_outdated ;;
    build-debug) cmd_build_debug ;;
    build-release) cmd_build_release ;;
    install) cmd_install ;;
    devices) cmd_devices ;;
    s23-check) cmd_s23_check ;;
    s23-info) cmd_s23_info ;;
    s23-screenshot) cmd_s23_screenshot ;;
    adb-restart) cmd_adb_restart ;;
    doctor) cmd_doctor ;;
    permissions) cmd_permissions ;;
    service-status) cmd_service_status ;;
    help|--help|-h) show_help ;;
    *)
        echo -e "${RED}❌ Comando desconhecido: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
