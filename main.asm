# ==============================================================================================
# SEÇÃO DE DADOS (.data)
# Configuração e mapeamento das imagens, variáveis de estado e arquivos de áudio do jogo.
# ==============================================================================================
.data

# Diretivas de inclusão dos arquivos de imagem (.data) convertidos para formato Bitmap
.include "imagens/felix.data"
.include "imagens/fundo.data"
.include "imagens/tile.data"
.include "imagens/telainicial.data"
.include "imagens/AndarPDireitaFelix.data"
.include "imagens/AndarPEsquerdaFelix.data"
.include "imagens/FelixOutroLado.data"
.include "imagens/FelixOutroLadoRebaixado.data"
.include "imagens/FelixRebaixado.data"

# Estrutura de dados para reprodução da música (Midi / Áudio)
# Formato: [Quantidade de notas, Índice da nota atual, Timestamp da última nota, (Nota, Duração, Instrumento)...]
notas: .word 9, 0, 0, 67, 1000, 0, 74, 1000, 0, 70, 1500, 0, 69, 500, 0, 67, 500, 0, 70, 500, 0, 69, 500, 0, 67, 500, 0, 66, 500, 0,

# Variáveis de Posicionamento e Controle
CHAR_POS:     .half 30, 120       # Posição atual do Félix na tela: X (coluna), Y (linha)
OLD_CHAR_POS: .half 0, 0          # Posição anterior do Félix (para controle de rastro ou lógica antiga)

BG_POS:     .half 0, 0            # Posição atual de leitura do fundo (Scroll X, Scroll Y)
OLD_BG_POS: .half 0, 0            # Posição anterior de leitura do fundo

# Limites de movimentação do cenário de fundo (Câmera)
BG_X_MIN:  .half 0                # Limite mínimo de rolagem do cenário para a esquerda
BG_X_MAX:  .half 80               # Limite máximo de rolagem do cenário para a direita

# Limites absolutos do personagem Félix na janela de exibição da tela (320x240)
FELIX_X_MIN: .half 0              # Limite físico esquerdo para o personagem
FELIX_X_MAX: .half 304            # Limite físico direito (320 total - largura aproximada do sprite)
FELIX_Y_MIN: .half 0              # Limite físico superior para o personagem
FELIX_Y_MAX: .half 224            # Limite físico inferior (240 total - altura aproximada do sprite)

FELIX_DIR:   .word 1              # Direção do Félix: 0 = Olhando para a Direita, 1 = Olhando para a Esquerda
FELIX_FRAME: .word 0              # Contador de ciclos/frames globais usado para ditar a velocidade da animação

# ==============================================================================================
# SEÇÃO DE CÓDIGO (.text)
# Rotinas de inicialização, loop principal, processamento de entrada e renderização gráfica.
# ==============================================================================================
.text

# ----------------------------------------------------------------------------------------------
# SETUP: Tela Inicial
# Exibe a tela de introdução do jogo no Framebuffer 0 e aguarda a interação do usuário.
# ----------------------------------------------------------------------------------------------
SETUP:
    la  a0, telainicial           # Endereço da imagem da tela inicial
    li  a1, 0                     # Posição X = 0
    li  a2, 0                     # Posição Y = 0
    li  a3, 0                     # Framebuffer alvo = 0
    call PRINT                    # Renderiza a imagem na tela

# ----------------------------------------------------------------------------------------------
# KEY1: Espera por Tecla
# Loop de polling que trava a execução até que qualquer tecla seja pressionada no teclado do simulador.
# ----------------------------------------------------------------------------------------------
KEY1:
    li  t1, 0xFF200000            # Endereço de controle do Teclado (MMIO)
WAIT_KEY:
    lw  t0, 0(t1)                 # Lê o status do teclado
    andi t0, t0, 0x0001           # Isola o bit de "tecla pressionada"
    beq t0, zero, WAIT_KEY        # Se for 0 (nenhuma tecla), continua esperando
    lw  t2, 4(t1)                 # Lê o código ASCII da tecla pressionada
    sw  t2, 12(t1)                # Limpa o buffer de entrada do teclado escrevendo no receptor

    # Desenha o fundo inicial em ambos os Framebuffers (0 e 1) para preparar o Double Buffering
    la   a0, fundo                # Endereço da imagem de fundo
    lh   a1, 0(a0)                # Passa a largura/posição inicial para o buffer
    li   a2, 0
    li   a3, 0                    # Renderiza no Framebuffer 0
    call PRINT_BACKGROUND
    li   a3, 1                    # Renderiza no Framebuffer 1
    call PRINT_BACKGROUND

# ----------------------------------------------------------------------------------------------
# GAME_LOOP: Loop Principal do Jogo
# Controla o fluxo cíclico: Áudio -> Animação -> Entrada -> Desenho -> Inversão de Tela -> Delay
# ----------------------------------------------------------------------------------------------
GAME_LOOP:

    # ------------------------------------------------------------------------------------------
    # SISTEMA DE ÁUDIO/MÚSICA: Processamento de Notas via Chamadas de Sistema (Syscalls)
    # ------------------------------------------------------------------------------------------
    la  s1, notas                 # Carrega o vetor de controle de notas musicais
    lw  s2, 0(s1)                 # s2 = Total de notas existentes na partitura
    lw  s3, 4(s1)                 # s3 = Índice da nota que deve ser tocada no momento
    lw  s4, 8(s1)                 # s4 = Timestamp em milissegundos de quando a última nota começou

    li  t0, 12                    # Cada nota estruturada ocupa 12 bytes (3 palavras de 4 bytes)
    mul s5, t0, s3                # Multiplica o índice atual pelo tamanho da estrutura
    add s5, s5, s1                # Aponta para o endereço exato da nota atual

    li  a7, 30                    # Syscall 30: Obtém o tempo atual do sistema em milissegundos
    ecall                         # Retorna o tempo em a0
    sub s6, a0, s4                # s6 = Tempo decorrido (Tempo Atual - Tempo da Última Nota)

    lw  t1, 4(s5)                 # Carrega a duração necessária para a nota atual
    bgtu t1, s6, MF0              # Se a duração for maior que o tempo decorrido, pula o processamento (mantém a nota tocando)

    bne s3, s2, MF1               # Se o índice atual não chegou ao fim da música, pula para tocar
    li  s3, 0                     # Caso contrário, zera o índice para reiniciar a música (Loop)
    mv  s5, s1                    # Reseta o ponteiro base de notas para o início
MF1:
    addi s5, s5, 12               # Avança para a próxima nota no array
    li  a7, 31                    # Syscall 31: Toca uma nota MIDI síncrona/assíncrona
    lw  a0, 0(s5)                 # a0 = Altura da nota (Pitch)
    lw  a1, 4(s5)                 # a1 = Duração da nota em milissegundos
    li  a2, 0                     # a2 = Instrumento (0 = Piano)
    li  a3, 60                    # a3 = Volume (Dinâmica)
    ecall                         # Executa o som da nota
    li  a7, 30                    # Syscall 30: Obtém o tempo exato pós-reprodução
    ecall
    sw  a0, 8(s1)                 # Atualiza o timestamp da última nota tocada na memória
    addi s3, s3, 1                # Incrementa o índice da nota
    sw  s3, 4(s1)                 # Salva o novo índice na variável correspondente

MF0:
    # ------------------------------------------------------------------------------------------
    # CONTROLE DE FRAME / ANIMAÇÃO
    # ------------------------------------------------------------------------------------------
    la  t0, FELIX_FRAME           # Carrega a variável de controle de frames da animação
    lw  t1, 0(t0)                 # Incrementa o contador global de ticks a cada iteração do loop
    addi t1, t1, 1
    sw  t1, 0(t0)

    call SELECT_FELIX             # Escolhe dinamicamente qual sprite do Félix renderizar em a0
    call KEY2                     # Captura a entrada do teclado e processa a movimentação
    xori s0, s0, 1                # Alterna o frame visível/lógico do Double Buffering (0 para 1 ou 1 para 0)

    # ------------------------------------------------------------------------------------------
    # RENDERIZAÇÃO DOS GRÁFICOS (Ordem de camadas: Personagem -> Fundo -> Delay)
    # ------------------------------------------------------------------------------------------
    la  t0, CHAR_POS              # Carrega a estrutura de posição do Félix
    lh  a1, 0(t0)                 # a1 = Posição X
    lh  a2, 2(t0)                 # a2 = Posição Y
    mv  a3, s0                    # a3 = Framebuffer de escrita atual (s0)
    call PRINT                    # Desenha o sprite selecionado do personagem

    li   t0, 0xFF200604           # Endereço de controle do Frame Buffer da placa gráfica (LED de exibição)
    sw   s0, 0(t0)                # Exibe na tela o frame atual, evitando screen tearing/piscadas

    la   t0, BG_POS               # Carrega a estrutura de posição da Câmera/Fundo
    la   a0, fundo                # a0 = Endereço da imagem completa de fundo
    lh   a1, 0(t0)                # a1 = Deslocamento X da câmera
    lh   a2, 2(t0)                # a2 = Deslocamento Y da câmera (não modificado)
    mv   a3, s0                   # Determina o Framebuffer oposto para renderização de background
    xori a3, a3, 1                # Inverte o índice do buffer de escrita secundário
    call PRINT_BACKGROUND         # Desenha o plano de fundo atualizado com o scroll correspondente

    # Configuração de taxa de atualização (Frame Rate Delay)
    li a0, 30                     # Define um tempo de espera de 30 milissegundos
    li a7, 32                     # Syscall 32: Sleep / Delay de hardware
    ecall                         # Executa a pausa antes de reiniciar o loop

    j GAME_LOOP                   # Retorna ao início do loop principal do jogo

# ----------------------------------------------------------------------------------------------
# KEY2: Processamento e Tratamento de Entrada Assíncrona
# Lê os registradores de entrada do teclado e redireciona o fluxo para a rotina de movimento adequada.
# ----------------------------------------------------------------------------------------------
KEY2:
    li  t1, 0xFF200000            # Endereço base de controle do teclado (Mapeado em Memória)
    lw  t0, 0(t1)                 # Lê o registrador de status de prontidão
    andi t0, t0, 0x0001           # Verifica se há um novo caractere disponível
    beq  t0, zero, KEY2_FIM       # Se nenhuma tecla foi tocada, finaliza a subrotina
    lw   t2, 4(t1)                # Lê o valor ASCII da tecla correspondente

    li  t0, 'a'
    beq t2, t0, MOVE_LEFT         # Se pressionado 'a', desvia para movimentação à esquerda

    li  t0, 'd'
    beq t2, t0, MOVE_RIGHT        # Se pressionado 'd', desvia para movimentação à direita

    li  t0, 'w'
    beq t2, t0, MOVE_UP           # Se pressionado 'w', desvia para movimentação para cima

    li  t0, 's'
    beq t2, t0, MOVE_DOWN         # Se pressionado 's', desvia para movimentação para baixo

KEY2_FIM:
    ret                           # Retorna para a chamada do Game Loop

# ----------------------------------------------------------------------------------------------
# MOVE_LEFT: Movimentação para a Esquerda ('a')
# Gerencia a prioridade do movimento: primeiro altera o cenário (Scroll), depois o personagem.
# ----------------------------------------------------------------------------------------------
MOVE_LEFT:
    la  t0, FELIX_DIR
    li  t1, 1
    sw  t1, 0(t0)                 # Define a direção do Félix como 1 (Olhando para a Esquerda)

    la  t0, BG_POS                # Posição X da Câmera
    lh  t1, 0(t0)
    
    la  t2, BG_X_MIN              # Limite mínimo de scroll
    lh  t2, 0(t2)
    beq t1, t2, MOVE_LEFT_FELIX   # Se a tela já chegou no limite esquerdo (0), move o Félix diretamente

    la  t3, CHAR_POS              # Posição X do Félix
    lh  t4, 0(t3)
    li  t5, 30                    # Ponto de ativação do Scroll Esquerdo
    bgt t4, t5, MOVE_LEFT_FELIX   # Se o Félix ainda estiver à direita da linha 30, move o Félix em vez da tela

    # Efetua o Scroll: Desloca o fundo para a esquerda
    addi t1, t1, -2               # Move a câmera em -2 pixels
    bge t1, t2, ML_BG_OK          # Garante que não ultrapassará o limite mínimo estabelecido
    mv  t1, t2                    # Se ultrapassar, fixa no valor mínimo
ML_BG_OK:
    sh  t1, 0(t0)                 # Atualiza a nova posição do fundo na memória
    ret                           # Finaliza a execução do movimento

MOVE_LEFT_FELIX:
    la  t3, CHAR_POS              # Carrega e atualiza a posição do sprite do personagem
    lh  t4, 0(t3)
    addi t4, t4, -2               # Move o Félix em -2 pixels horizontais
    la  t2, FELIX_X_MIN           # Carrega a barreira física esquerda da janela
    lh  t2, 0(t2)
    bge t4, t2, ML_FX_OK          # Verifica colisão com os limites da janela de exibição
    mv  t4, t2                    # Fixa na borda se tentar sair da tela
ML_FX_OK:
    sh  t4, 0(t3)                 # Salva a nova posição X do Félix na memória
    ret

# ----------------------------------------------------------------------------------------------
# MOVE_RIGHT: Movimentação para a Direita ('d')
# Gerencia a prioridade de movimento: move o Félix até o ponto limite e depois ativa o Scroll.
# ----------------------------------------------------------------------------------------------
MOVE_RIGHT:
    la  t0, FELIX_DIR
    li  t1, 0
    sw  t1, 0(t0)                 # Define a direção do Félix como 0 (Olhando para a Direita)

    la  t3, CHAR_POS              # Posição X do Félix
    lh  t4, 0(t3)
    li  t5, 274                   # Ponto limite de ativação do Scroll Direito
    blt t4, t5, MOVE_RIGHT_FELIX  # Se o Félix estiver antes da coluna 274, move apenas o personagem

    la  t0, BG_POS                # Posição X da Câmera
    lh  t1, 0(t0)
    la  t2, BG_X_MAX              # Limite máximo de scroll permitido
    lh  t2, 0(t2)
    beq t1, t2, MOVE_RIGHT_FELIX  # Se o fundo já chegou no limite máximo, move o Félix até o canto absoluto

    # Efetua o Scroll: Desloca o fundo para a direita
    addi t1, t1, 2                # Desloca a leitura do cenário em +2 pixels
    ble t1, t2, MR_BG_OK          # Garante proteção contra estouro de limite máximo
    mv  t1, t2                    # Fixa no limite se houver estouro
MR_BG_OK:
    sh  t1, 0(t0)                 # Grava o novo ponto de scroll do background
    ret

MOVE_RIGHT_FELIX:
    la  t3, CHAR_POS              # Atualiza a posição X do Félix
    lh  t4, 0(t3)
    
    la  t0, BG_POS                # Valida se o cenário de fundo está completamente estático no limite
    lh  t1, 0(t0)
    la  t2, BG_X_MAX
    lh  t2, 0(t2)
    beq t1, t2, MR_FX_LIMIT       # Se o fundo estiver no limite, permite andar até a borda da janela (304)
    
    li  t5, 274                   # Mantém o travamento do Félix na linha 274 enquanto o cenário se move
    blt t4, t5, MR_FX_CONTINUE    # Caso esteja abaixo de 274, avança normalmente
    mv  t4, t5                    # Trava o Félix no ponto 274 para o efeito de câmera funcionar
    j MR_FX_OK

MR_FX_LIMIT:
    la  t2, FELIX_X_MAX           # Carrega a parede invisível da borda da tela
    lh  t2, 0(t2)
    blt t4, t2, MR_FX_CONTINUE    # Avança livremente até atingir a colisão absoluta com o fim da janela
    mv  t4, t2                    # Impede que o personagem saia do campo de visão do jogador
    j MR_FX_OK

MR_FX_CONTINUE:
    addi t4, t4, 2                # Aplica o deslocamento de +2 pixels no eixo horizontal

MR_FX_OK:
    sh  t4, 0(t3)                 # Consolida a nova coordenada na memória
    ret

# ----------------------------------------------------------------------------------------------
# MOVE_UP / MOVE_DOWN: Movimentação Vertical ('w' e 's')
# Altera as coordenadas do eixo Y limitando os movimentos com barreiras de colisão simples.
# ----------------------------------------------------------------------------------------------
MOVE_UP:
    addi sp, sp, -16
    sw   ra, 0(sp)
    sw   s2, 4(sp)
    sw   s3, 8(sp)

    li   s2, 0
PULO_SUBIDA:
    li   t0, 70
    beq  s2, t0, CONFIG_DESGIDA

    la   t0, CHAR_POS
    lh   t1, 2(t0)
    addi t1, t1, -1
    
    la   t2, FELIX_Y_MIN
    lh   t2, 0(t2)
    bge  t1, t2, MS_OK
    mv   t1, t2
MS_OK:
    sh   t1, 2(t0)

    call VERIFICA_AIR_CONTROL
    call REDESENHAR_FRAME_PULO

    addi s2, s2, 1
    j    PULO_SUBIDA

CONFIG_DESGIDA:
    li   s2, 0
PULO_DESCIDA:
    li   t0, 70
    beq  s2, t0, FIM_PULO

    la   t0, CHAR_POS
    lh   t1, 2(t0)
    addi t1, t1, 1
    
    la   t2, FELIX_Y_MAX
    lh   t2, 0(t2)
    ble  t1, t2, MD_OK_PULO
    mv   t1, t2
MD_OK_PULO:
    sh   t1, 2(t0)

    call VERIFICA_AIR_CONTROL
    call REDESENHAR_FRAME_PULO

    addi s2, s2, 1
    j    PULO_DESCIDA

FIM_PULO:
    lw   ra, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    addi sp, sp, 16
    ret

VERIFICA_AIR_CONTROL:
    addi sp, sp, -4
    sw   ra, 0(sp)

    li   t1, 0xFF200000
    lw   t0, 0(t1)
    andi t0, t0, 0x0001
    beq  t0, zero, FIM_AIR_CONTROL
    lw   t2, 4(t1)

    li   t0, 'a'
    beq  t2, t0, AIR_MOVE_LEFT

    li   t0, 'd'
    beq  t2, t0, AIR_MOVE_RIGHT
    j    FIM_AIR_CONTROL

AIR_MOVE_LEFT:
    la   t0, FELIX_DIR
    li   t1, 1
    sw   t1, 0(t0)

    la   t0, BG_POS
    lh   t1, 0(t0)
    la   t2, BG_X_MIN
    lh   t2, 0(t2)
    beq  t1, t2, AIR_LEFT_FELIX

    la   t3, CHAR_POS
    lh   t4, 0(t3)
    li   t5, 30
    bgt  t4, t5, AIR_LEFT_FELIX

    addi t1, t1, -2
    bge  t1, t2, AIR_ML_BG_OK
    mv   t1, t2
AIR_ML_BG_OK:
    sh   t1, 0(t0)
    j    FIM_AIR_CONTROL

AIR_LEFT_FELIX:
    la   t3, CHAR_POS
    lh   t4, 0(t3)
    addi t4, t4, -2
    la   t2, FELIX_X_MIN
    lh   t2, 0(t2)
    bge  t4, t2, AIR_ML_FX_OK
    mv   t4, t2
AIR_ML_FX_OK:
    sh   t4, 0(t3)
    j    FIM_AIR_CONTROL

AIR_MOVE_RIGHT:
    la   t0, FELIX_DIR
    li   t1, 0
    sw   t1, 0(t0)

    la   t3, CHAR_POS
    lh   t4, 0(t3)
    li   t5, 274
    blt  t4, t5, AIR_RIGHT_FELIX

    la   t0, BG_POS
    lh   t1, 0(t0)
    la   t2, BG_X_MAX
    lh   t2, 0(t2)
    beq  t1, t2, AIR_RIGHT_FELIX

    addi t1, t1, 2
    ble  t1, t2, AIR_MR_BG_OK
    mv   t1, t2
AIR_MR_BG_OK:
    sh   t1, 0(t0)
    j    FIM_AIR_CONTROL

AIR_RIGHT_FELIX:
    la   t3, CHAR_POS
    lh   t4, 0(t3)
    la   t0, BG_POS
    lh   t1, 0(t0)
    la   t2, BG_X_MAX
    lh   t2, 0(t2)
    beq  t1, t2, AIR_MR_FX_LIMIT
    li   t5, 274
    blt  t4, t5, AIR_MR_FX_CONTINUE
    mv   t4, t5
    j    AIR_MR_FX_OK
AIR_MR_FX_LIMIT:
    la   t2, FELIX_X_MAX
    lh   t2, 0(t2)
    blt  t4, t2, AIR_MR_FX_CONTINUE
    mv   t4, t2
    j    AIR_MR_FX_OK
AIR_MR_FX_CONTINUE:
    addi t4, t4, 2
AIR_MR_FX_OK:
    sh   t4, 0(t3)

FIM_AIR_CONTROL:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

REDESENHAR_FRAME_PULO:
    addi sp, sp, -4
    sw   ra, 0(sp)

    xori s0, s0, 1

    call SELECT_FELIX
    
    la   t0, CHAR_POS
    lh   a1, 0(t0)
    lh   a2, 2(t0)
    mv   a3, s0
    call PRINT

    li   t0, 0xFF200604
    sw   s0, 0(t0)

    la   t0, BG_POS
    la   a0, fundo
    lh   a1, 0(t0)
    lh   a2, 2(t0)
    mv   a3, s0
    xori a3, a3, 1
    call PRINT_BACKGROUND

    li   a0, 15
    li   a7, 32
    ecall

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

MOVE_DOWN:
    la  t0, CHAR_POS              # Carrega a estrutura de coordenadas
    lh  t1, 2(t0)                 # Carrega a coordenada Y (linha)
    addi t1, t1, 2                # Incrementa 2 pixels (move para baixo)

    la  t2, FELIX_Y_MAX           # Carrega o chão físico do jogo
    lh  t2, 0(t2)
    ble t1, t2, MD_OK             # Valida a colisão inferior
    mv  t1, t2                    # Fixa o personagem no chão
MD_OK:
    sh  t1, 2(t0)                 # Salva a nova coordenada Y
    ret

# ----------------------------------------------------------------------------------------------
# SELECT_FELIX: Máquina de Estados de Sprite / Animação Contínua
# Avalia a variável de direção (FELIX_DIR) e cria a alternância temporal dos frames.
# ----------------------------------------------------------------------------------------------
SELECT_FELIX:
    la  t0, FELIX_DIR             # Carrega a orientação atual do personagem
    lw  t0, 0(t0)
    beq t0, zero, FELIX_RIGHT     # Se 0, executa lógica de animação voltada para a direita
    li  t1, 1
    beq t0, t1, FELIX_LEFT        # Se 1, executa lógica de animação voltada para a esquerda

FELIX_RIGHT:
    la  t2, FELIX_FRAME           # Pega o contador de ticks
    lw  t0, 0(t2)
    srli t0, t0, 2                # Divisor de frequência de animação (reduz a velocidade dividindo por 4)
    andi t0, t0, 1                # Isola o bit para alternância binária pura (0 ou 1)
    bnez t0, NOT_REBAIXADO        # Se o resultado for 1, renderiza o sprite normal em pé
    la   a0, FelixRebaixado       # Se o resultado for 0, renderiza o sprite agachado ("passo")
    ret
NOT_REBAIXADO:
    la   a0, felix                # Retorna o sprite padrão ativo em a0
    ret

FELIX_LEFT:
    la  t2, FELIX_FRAME           # Lógica análoga à anterior, aplicada à orientação esquerda
    lw  t0, 0(t2)
    srli t0, t0, 2                # Desloca 2 bits para desacelerar a transição dos sprites
    andi t0, t0, 1                # Cria o padrão intermitente estável de oscilação
    bnez t0, NOT_REBAIXADO_LEFT
    la   a0, FelixOutroLadoRebaixado # Retorna o sprite agachado olhando para a esquerda
    ret
NOT_REBAIXADO_LEFT:
    la   a0, FelixOutroLado           # Retorna o sprite normal olhando para a esquerda
    ret

# ----------------------------------------------------------------------------------------------
# PRINT: Renderizador Gráfico Padrão (Bitmaps Gerais)
# Copia as matrizes de cores para a memória de vídeo do simulador usando coordenadas diretas.
# ----------------------------------------------------------------------------------------------
PRINT:
    li  t0, 0xFF0                 # Base do endereço do Frame Buffer do simulador Risc-V
    add t0, t0, a3                # Soma o indicador do frame selecionado (a3: 0 ou 1)
    slli t0, t0, 20               # Desloca 20 bits para alinhar com o endereço real de vídeo (0xFF000000 / 0xFF100000)
    add t0, t0, a1                # Soma a coordenada horizontal X (coluna inicial)
    li  t1, 320                   # Constante de largura total da janela VGA
    mul t1, t1, a2                # Multiplica a linha atual pela largura total da tela
    add t0, t0, t1                # Define o ponto exato da memória bitmap de destino
    addi t1, a0, 8                # Ignora os metadados (primeiros 8 bytes contendo largura e altura)
    mv  t2, zero                  # Zera o registrador do contador de linhas (Y interno)
    mv  t3, zero                  # Zera o registrador do contador de colunas (X interno)
    lw  t4, 0(a0)                 # Extrai a largura da imagem do arquivo .data
    lw  t5, 4(a0)                 # Extrai a altura da imagem do arquivo .data
PRINT_LINHA:
    lw  t6, 0(t1)                 # Lê uma palavra (4 pixels consecutivos embalados) da imagem
    sw  t6, 0(t0)                 # Copia os 4 pixels diretamente para a memória de vídeo (Bitmap Display)
    addi t0, t0, 4                # Avança 4 bytes no buffer de tela
    addi t1, t1, 4                # Avança 4 bytes na memória da imagem
    addi t3, t3, 4                # Incrementa o rastreador de colunas
    blt  t3, t4, PRINT_LINHA      # Repete até que toda a largura da linha atual seja preenchida
    addi t0, t0, 320              # Move o ponteiro de tela para o início da próxima linha física
    sub  t0, t0, t4               # Ajusta o recuo necessário subtraindo a largura recém impressa
    mv  t3, zero                  # Reinicia o contador horizontal para a nova linha
    addi t2, t2, 1                # Incrementa o contador de linhas verticais processadas
    blt  t2, t5, PRINT_LINHA      # Loop contínuo até que toda a altura do sprite termine de desenhar
    ret

# ----------------------------------------------------------------------------------------------
# PRINT_BACKGROUND: Renderizador Especial com Suporte a Câmera Horizonal (Scroll)
# Recorta uma janela fixa de 320x240 a partir de um cenário armazenado em tamanho maior.
# ----------------------------------------------------------------------------------------------
PRINT_BACKGROUND:
    li   t0, 0xFF0                # Configuração do endereço de memória de vídeo base
    add  t0, t0, a3                # Aplica o Double Buffering dinamicamente (0 ou 1)
    slli t0, t0, 20               # Desloca para formar o endereço canônico (0xFF000000 / 0xFF100000)
    addi t1, a0, 8                # Avança os metadados iniciais da imagem (largura/altura)
    lw   t4, 0(a0)                # t4 = Largura real total da imagem do cenário completo
    add  t1, t1, a1               # Soma o fator X de Scroll (a1), deslocando o ponteiro de leitura do mapa
    li   t2, 0                    # Contador de linhas do visor (começa na linha 0)
    li   t5, 240                  # Limita a exibição vertical estritamente à altura padrão da tela (240)
PRINT_BG_LINHA:
    li   t3, 0                    # Inicializa o rastreador de colunas do monitor para a nova linha
PRINT_BG_COLUNA:
    lw   t6, 0(t1)                # Captura 4 pixels sequenciais a partir do ponto de visualização da câmera
    sw   t6, 0(t0)                # Escreve os pixels capturados no monitor físico
    addi t0, t0, 4                # Move o cursor de escrita do monitor adiante
    addi t1, t1, 4                # Move o cursor de leitura do cenário adiante
    addi t3, t3, 4                # Incrementa o preenchimento horizontal atual
    li   t6, 320                  # Força a parada ao preencher a janela VGA visível completa (320)
    blt  t3, t6, PRINT_BG_COLUNA  # Continua preenchendo as colunas da linha se estiver abaixo de 320
    sub  t1, t1, t3               # Retrocede o ponteiro de dados ao início da janela visível da linha
    add  t1, t1, t4               # Salta o restante oculto da largura do mapa real para alinhar com a próxima linha
    addi t2, t2, 1                # Avança para a próxima linha do monitor
    blt  t2, t5, PRINT_BG_LINHA   # Finaliza ao preencher todas as 240 linhas verticais da tela do jogo
    ret