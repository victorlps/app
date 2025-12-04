# Como Verificar as Mudanças

## ✅ O que foi instalado agora (v1.0.0+3)

### 1. Versão no AppBar
- Abra o app
- Na tela principal, no topo, ao lado de "Avisa Lá"
- Deve aparecer um badge cinza com **"v1.0.0+3"**

### 2. Botões SEM Sobreposição
Para testar:
1. Selecione um destino
2. Configure alertas
3. Clique em "Iniciar Viagem"
4. Na tela de monitoramento, **role até o final**
5. Os botões "Cheguei ao Destino" e "Cancelar Viagem" devem estar **completamente visíveis**
6. Não devem ser cortados pela barra de navegação do Android

## 🔍 Se não estiver funcionando

Execute o script de reinstalação limpa:
```bash
cd /home/vlps/dev/avisa_la_e/app
./reinstall.sh
```

Ou manualmente:
```bash
# Desinstalar completamente
adb -s RQCW307SRFT uninstall com.example.avisa_la

# Reinstalar
cd avisa_la
flutter clean
flutter pub get
flutter build apk --debug
adb -s RQCW307SRFT install build/app/outputs/flutter-apk/app-debug.apk
adb -s RQCW307SRFT shell am start -n com.example.avisa_la/.MainActivity
```

## 📊 Versões

- Anterior: v1.0.0+1 ou v1.0.0+2
- **Atual: v1.0.0+3**
- Próxima: Use `./increment-version.sh` antes de buildar

## 🐛 Debug

Se a versão mostrar "v..." ou "v1.0.0+2":
- O package_info_plus não carregou
- Reinstale usando `./reinstall.sh`

Se os botões ainda estiverem sobrepostos:
- O código antigo ainda está instalado
- Desinstale completamente o app
- Reinstale usando `./reinstall.sh`
