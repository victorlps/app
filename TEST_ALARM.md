# Como Testar o Alarme de Chegada

## Situação Atual
O alarme funciona de duas formas:
1. **Modo Estático:** Toca quando a distância real <= distância configurada (200m, 500m ou 1km)
2. **Modo Dinâmico:** Toca quando o tempo estimado do Google Maps <= tempo configurado (5 min padrão)

## Problema para Testes
- Você precisa estar REALMENTE próximo do destino
- No escritório/casa, é difícil simular movimento real
- Emulador não simula GPS facilmente

## Soluções para Testar

### Opção 1: Botão de Teste (RECOMENDADO)
Adicionar um botão "Testar Alarme" na tela de monitoramento que:
- Dispara a notificação de chegada imediatamente
- Mostra som + vibração + notificação
- Não interfere com o alarme real

### Opção 2: Reduzir Temporariamente as Distâncias
Mudar temporariamente:
- Distância mínima: 200m → 5000m (5km)
- Tempo mínimo: 5 min → 60 min

Assim você pode testar sem sair de casa (apenas selecionando um destino a 3-4km).

### Opção 3: Mock de Localização (Mais Complexo)
- Usar app "Fake GPS" no Android
- Habilitar "Localizações simuladas" nas opções de desenvolvedor
- Simular caminhada até o destino

### Opção 4: Usar Emulador com GPS Simulado
- Emulador permite definir rotas GPS
- Pode simular movimento em velocidade controlada
- Mais trabalhoso de configurar

## Qual você prefere?
Eu recomendo **Opção 1** - é rápida, não afeta o código de produção e testa a notificação real.
