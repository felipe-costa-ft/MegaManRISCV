.data
.include "imagens/telainicial.data"   # Inclui o arquivo de imagem background.data

.text

# Função para renderizar o fundo
.globl BACKGROUND_RENDER
BACKGROUND_RENDER:
    # Inicializa os registradores necessários
    li t1, 0xFF000000          # Endereço inicial da memória VGA - Frame 0
    li t2, 0xFF012C00          # Endereço final da memória VGA
    la s1, telainicial         # Endereço dos dados da tela na memória
    addi s1, s1, 8             # Ajusta o ponteiro para pular os dados de nlin e ncol

BACKGROUND_LOOP:  
    beq t1, t2, BACKGROUND_FIM # Se `t1` atingir o endereço final, sai do loop
    lw t3, 0(s1)               # Lê uma word (4 bytes) da imagem
    sw t3, 0(t1)               # Escreve a word na memória VGA
    addi t1, t1, 4             # Incrementa o endereço de memória VGA
    addi s1, s1, 4             # Incrementa o ponteiro para os dados da imagem
    j BACKGROUND_LOOP          # Volta para o início do loop

BACKGROUND_FIM:
    jr ra                      # Retorna para a função chamadora
