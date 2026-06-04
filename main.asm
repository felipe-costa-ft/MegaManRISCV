# ==============================================================================================
# SEÇÃO DE DADOS (.data)
# ==============================================================================================
.data

# Inclusão dos arquivos binários das imagens (matrizes de pixels e dimensões)
.include "imagens/felix.data"
.include "imagens/fundo.data"
.include "imagens/tile.data"
.include "imagens/telainicial.data"
.include "imagens/AndarPDireitaFelix.data"
.include "imagens/AndarPEsquerdaFelix.data"
.include "imagens/FelixOutroLado.data"
.include "imagens/FelixOutroLadoRebaixado.data"
.include "imagens/FelixRebaixado.data"

# Trilha sonora organizada em blocos de 3 words: [Pitch/Nota, Duração em ms, Canal/Instrumento]
notas: .word 9, 0, 0, 67, 1000, 0, 74, 1000, 0, 70, 1500, 0, 69, 500, 0, 67, 500, 0, 70, 500, 0, 69, 500, 0, 67, 500, 0, 66, 500, 0,

# Posição atual e anterior do Felix na tela (armazenados como Half-Word, 16 bits cada: X, Y)
CHAR_POS:     .half 30, 50
OLD_CHAR_POS: .half 30, 50       

# --- DIMENSÕES DO PERSONAGEM (CORPO) ---
FELIX_LARGURA: .half 24            
FELIX_ALTURA:  .half 36            

# Posição de rolagem (Scroll) do cenário de fundo
BG_POS:     .half 0, 0
OLD_BG_POS: .half 0, 0

# Limites máximos e mínimos para o movimento da câmera (X)
BG_X_MIN:  .half 0
BG_X_MAX:  .half 80

# Limites máximos e mínimos para o Felix andar dentro da tela
FELIX_X_MIN: .half 0
FELIX_X_MAX: .half 304
FELIX_Y_MIN: .half 0
FELIX_Y_MAX: .half 224

FELIX_DIR:   .word 1# Direção do olhar: 0 = Direita, 1 = Esquerda
FELIX_FRAME: .word 0# Contador global de frames para controle de animação

# Variáveis do motor de física vertical
VEL_Y:       .word 0# Velocidade vertical (valores positivos descem, negativos sobem)
ESTA_NO_AR:  .word 1# Booleano: 1 se estiver caindo/pulando, 0 se estiver firme no chão

# --- SISTEMA DE BLOCOS (MUNDO ABSOLUTO) ---
# Define as plataformas do mapa. Formato: (X mínimo, X máximo, Y do topo, Y da base)
NUM_BLOCOS:   .word 4
LISTA_BLOCOS:
    .half 0, 500, 155, 180   
    .half 215, 250, 142, 160
    .half 328, 370, 142, 160  
    .half 390, 400, 130, 145     

# ==============================================================================================
# SEÇÃO DE CÓDIGO (.text)
# ==============================================================================================
.text

SETUP:
    la  a0, telainicial# Carrega o endereço da imagem de abertura
    li  a1, 0          # Posição X = 0
    li  a2, 0          # Posição Y = 0
    li  a3, 0          # Frame buffer inicial = 0
    call PRINT         # Desenha a tela inicial

KEY1:
    li  t1, 0xFF200000 # Endereço de controle do teclado (MMIO)
WAIT_KEY:
    lw  t0, 0(t1)      # Lê o status do teclado
    andi t0, t0, 0x0001# Isola o bit de "tecla pressionada"
    beq t0, zero, WAIT_KEY # Se for 0 (nenhuma tecla), continua esperando
    lw  t2, 4(t1)      # Lê o caractere digitado para limpar o buffer
    sw  t2, 12(t1)     # Confirma a leitura para o teclado do simulador

    la   a0, fundo     # Endereço da imagem do cenário principal
    lh   a1, 0(a0)     # Carrega a largura do fundo
    li   a2, 0         # Coordenada Y inicial do desenho
    li   a3, 0         # Desenha no Buffer 0
    call PRINT_BACKGROUND
    li   a3, 1         # Desenha no Buffer 1 (evita tela piscando no início)
    call PRINT_BACKGROUND

GAME_LOOP:
    la  t0, CHAR_POS   # Endereço da posição atual
    la  t1, OLD_CHAR_POS# Endereço da posição antiga
    lw  t2, 0(t0)      # Lê o par (X, Y) atual de uma vez só (32 bits)
    sw  t2, 0(t1)      # Copia e salva na posição antiga

    la  t0, BG_POS     # Endereço do scroll do fundo atual
    la  t1, OLD_BG_POS # Endereço do scroll antigo
    lh  t2, 0(t0)      # Lê o offset X do cenário
    sh  t2, 0(t1)      # Salva no registro antigo

    # --- ATUALIZAÇÃO DAMÚSICA (MIDI SYSTEM CALLS) ---
    la  s1, notas      # Ponteiro para o array de notas musicais
    lw  s2, 0(s1)      # s2 = Número total de notas na música (9)
    lw  s3, 4(s1)      # s3 = Índice da nota tocando atualmente
    lw  s4, 8(s1)      # s4 = Timestamp de quando a nota atual começou
    li  t0, 12         # Cada nota ocupa 12 bytes (3 words)
    mul s5, t0, s3     # Multiplica índice pelo tamanho da nota
    add s5, s5, s1     # s5 aponta diretamente para os dados da nota atual
    li  a7, 30         # Syscall 30: Retorna o tempo do sistema em milissegundos
    ecall              
    sub s6, a0, s4     # s6 = Tempo decorrido desde o início da nota (TempoAtual - TempoInicio)
    lw  t1, 4(s5)      # t1 = Duração padrão da nota atual
    bgtu t1, s6, MF0   # Se a duração for maior que o tempo decorrido, continua tocando a mesma nota
    bne s3, s2, MF1    # Se o índice atual não chegou ao fim da música, vai para a próxima nota
    li  s3, 0          # Se chegou ao fim, reseta o índice para 0 (Loop da música)
    mv  s5, s1         # Reseta o ponteiro da nota para o início
MF1:
    addi s5, s5, 12    # Avança o ponteiro s5 para os bytes da próxima nota
    li  a7, 31         # Syscall 31: Toca som MIDI síncrono/assíncrono
    lw  a0, 0(s5)      # a0 = Altura do som (Pitch)
    lw  a1, 4(s5)      # a1 = Duração em milissegundos
    li  a2, 0          # a2 = Instrumento (0 = Piano)
    li  a3, 60         # a3 = Volume do som
    ecall              
    li  a7, 30         # Pede o tempo do sistema novamente
    ecall              
    sw  a0, 8(s1)      # Atualiza o timestamp de início da nova nota
    addi s3, s3, 1     # Incrementa o índice da nota atual
    sw  s3, 4(s1)      # Salva o novo índice na memória

MF0:
    la  t0, FELIX_FRAME# Endereço do contador de animação
    lw  t1, 0(t0)      # Carrega o valor atual do frame
    addi t1, t1, 1     # Incrementa em 1
    sw  t1, 0(t0)      # Salva de volta na memória

    call SELECT_FELIX                 # Escolhe a sprite correta (andando/olhando pra esquerda/direita)
    call KEY2                         # Captura e processa comandos de movimentação do jogador
    call APLICAR_GRAVIDADE            # Processa queda livre e colisões verticais (teto/chão)
    call PROCESSAR_COLISOES_LATERAIS  # Processa barreiras físicas nas laterais das plataformas

    xori s0, s0, 1     # Inverte o registrador s0 (Alterna entre 0 e 1 para Double Buffering)
    la  t0, CHAR_POS   # Pega a coordenada definitiva calculada para este frame
    lh  a1, 0(t0)      # a1 = Posição X da tela
    lh  a2, 2(t0)      # a2 = Posição Y da tela
    mv  a3, s0         # a3 = Determina qual tela vai receber o desenho do personagem
    call PRINT         # Renderiza o Felix na tela de background

    li   t0, 0xFF200604# Endereço de controle do Frame Buffer ativo na tela
    sw   s0, 0(t0)     # Aplica a inversão de tela (mostra o que desenhamos e esconde o antigo)

    la   t0, BG_POS    # Endereço do deslocamento da câmera do cenário
    la   a0, fundo     # Ponteiro da imagem de fundo
    lh   a1, 0(t0)     # a1 = Posição X onde inicia o recorte do cenário
    lh   a2, 2(t0)     # a2 = Posição Y do cenário
    mv   a3, s0         # s0 é o buffer que está oculto agora
    xori a3, a3, 1     # Inverte para limpar e redesenhar o fundo na outra tela
    call PRINT_BACKGROUND

    li a0, 30          # Define o tempo de espera em milissegundos
    li a7, 32          # Syscall 32: Sleep (pausa a execução para travar o FPS)
    ecall              
    j GAME_LOOP        # Reinicia o ciclo do jogo

KEY2:
    li  t1, 0xFF200000 # Endereço do teclado
    lw  t0, 0(t1)      # Lê se há nova entrada pendente
    andi t0, t0, 0x0001
    beq  t0, zero, KEY2_CHECAR_AR # Se não há tecla pressionada agora, trata o estado contínuo
    lw   t2, 4(t1)      # Se há tecla, lê o caractere ASCII correspondente
    j    KEY2_PROCESSA
KEY2_CHECAR_AR:
    la   t0, ESTA_NO_AR
    lw   t3, 0(t0)      # Carrega o estado de pulo do personagem
    bnez t3, KEY2_CONTINUO # Se ele está no ar, processa a última tecla para não travar o movimento
    j    KEY2_FIM
KEY2_CONTINUO:
    lw   t2, 4(t1)      # Recupera a última tecla registrada
KEY2_PROCESSA:
    li  t0, 'a'
    beq t2, t0, MOVE_LEFT # Se pressionou 'a', vai para rotina da esquerda
    li  t0, 'd'
    beq t2, t0, MOVE_RIGHT# Se pressionou 'd', vai para rotina da direita
    li  t0, 'w'
    beq t2, t0, MOVE_UP   # Se pressionou 'w', pula
    li  t0, 's'
    beq t2, t0, MOVE_DOWN # Se pressionou 's', agacha/desce
KEY2_FIM:
    ret

MOVE_LEFT:
    la  t0, FELIX_DIR  
    li  t1, 1          
    sw  t1, 0(t0)      # Atualiza FELIX_DIR = 1 (Olhando para a Esquerda)
    la  t0, BG_POS     
    lh  t1, 0(t0)      # t1 = Posição X atual da câmera do cenário
    la  t2, BG_X_MIN   
    lh  t2, 0(t2)      # t2 = Limite mínimo da câmera (0)
    beq t1, t2, MOVE_LEFT_FELIX # Se o cenário já bateu no limite esquerdo, move o boneco em vez do cenário
    la  t3, CHAR_POS   
    lh  t4, 0(t3)      # t4 = Posição X na tela do boneco
    li  t5, 30         
    bgt t4, t5, MOVE_LEFT_FELIX # Se o boneco não estiver centralizado na margem (30), move o boneco
    addi t1, t1, -2    # Move o cenário 2 pixels para trás (Scroll da câmera)
    bge t1, t2, ML_BG_OK # Proteção para não passar do mínimo absoluto
    mv  t1, t2
ML_BG_OK:
    sh  t1, 0(t0)      # Grava a nova posição da câmera
    ret
MOVE_LEFT_FELIX:
    la  t3, CHAR_POS   
    lh  t4, 0(t3)      # t4 = X na tela do boneco
    addi t4, t4, -2    # Desloca o boneco 2 pixels para a esquerda
    la  t2, FELIX_X_MIN
    lh  t2, 0(t2)      # Limite esquerdo da tela física
    bge t4, t2, ML_FX_OK # Se for maior ou igual ao limite, o movimento é válido
    mv  t4, t2         # Caso contrário, trava o boneco na borda zero
ML_FX_OK:
    sh  t4, 0(t3)      # Salva a nova coordenada X do personagem
    ret

MOVE_RIGHT:
    la  t0, FELIX_DIR  
    li  t1, 0          
    sw  t1, 0(t0)      # Atualiza FELIX_DIR = 0 (Olhando para a Direita)
    la  t3, CHAR_POS   
    lh  t4, 0(t3)      # t4 = X do boneco
    li  t5, 274        # Limite de barreira para começar o scroll do cenário
    blt t4, t5, MOVE_RIGHT_FELIX # Se o boneco está antes do ponto limite da tela, move só o boneco
    la  t0, BG_POS     
    lh  t1, 0(t0)      # t1 = X da câmera do cenário
    la  t2, BG_X_MAX   
    lh  t2, 0(t2)      # t2 = Limite máximo de scroll do cenário
    beq t1, t2, MOVE_RIGHT_FELIX # Se o cenário já chegou no fim, move o boneco até a borda direita
    addi t1, t1, 2     # Avança a câmera 2 pixels para a direita
    ble t1, t2, MR_BG_OK # Impede a câmera de estourar o limite máximo do mapa
    mv  t1, t2
MR_BG_OK:
    sh  t1, 0(t0)      # Atualiza a posição X da câmera
    ret
MOVE_RIGHT_FELIX:
    la  t3, CHAR_POS   
    lh  t4, 0(t3)      # t4 = X do boneco
    la  t0, BG_POS     
    lh  t1, 0(t0)      # t1 = X da câmera
    la  t2, BG_X_MAX   
    lh  t2, 0(t2)      
    beq t1, t2, MR_FX_LIMIT # Se a câmera está no limite máximo, aplica barreira do fim da fase
    li  t5, 274        
    blt t4, t5, MR_FX_CONTINUE # Se está abaixo da linha de scroll, incrementa normalmente
    mv  t4, t5         # Se tocou a linha, trava nele para forçar o cenário a mover no próximo frame
    j MR_FX_OK
MR_FX_LIMIT:
    la  t2, FELIX_X_MAX
    lh  t2, 0(t2)      # Limite final da tela (borda direita extrema)
    blt t4, t2, MR_FX_CONTINUE
    mv  t4, t2         # Trava na parede invisível direita
    j MR_FX_OK
MR_FX_CONTINUE:
    addi t4, t4, 2     # Incrementa 2 pixels para a direita
MR_FX_OK:
    sh  t4, 0(t3)      # Salva a nova coordenada X
    ret

MOVE_UP:
    la  t0, ESTA_NO_AR 
    lw  t1, 0(t0)      # Carrega flag de pulo
    bnez t1, FIM_MOVE_UP # Se já estiver no ar, ignora o comando (impede pulo infinito)
    li  t1, -10        # Define velocidade vertical negativa inicial (impulso para cima)
    la  t2, VEL_Y      
    sw  t1, 0(t2)      # Aplica a força de subida no vetor de velocidade
    li  t1, 1          
    sw  t1, 0(t0)      # Seta ESTA_NO_AR = 1 (Entrou no estado de pulo)
FIM_MOVE_UP:
    ret

MOVE_DOWN:
    la  t0, CHAR_POS   
    lh  t1, 2(t0)      # Carrega coordenada Y atual
    addi t1, t1, 2     # Desloca 2 pixels para baixo manualmente
    la  t2, FELIX_Y_MAX
    lh  t2, 0(t2)      # Y máximo da tela
    ble t1, t2, MD_OK  
    mv  t1, t2         # Limita o movimento no chão absoluto
MD_OK:
    sh  t1, 2(t0)      # Atualiza o Y na memória
    ret

APLICAR_GRAVIDADE:
    la  t0, CHAR_POS   
    lh  t1, 0(t0)      # t1 = X (Borda Esquerda) do Felix
    lh  t2, 2(t0)      # t2 = Y (Topo da Cabeça) do Felix
    
    la  s10, FELIX_LARGURA
    lh  s10, 0(s10)    
    add s11, t1, s10   # s11 = X + Largura (Borda Direita do Felix)
    
    la  s9, FELIX_ALTURA
    lh  s9, 0(s9)      
    add s10, t2, s9    # s10 = Y + Altura (Base dos Pés do Felix)

    la  t3, VEL_Y      
    lw  t4, 0(t3)      # t4 = Velocidade vertical atual

    add t2, t2, t4     # Modifica a posição da cabeça com base na velocidade
    add s10, s10, t4   # Modifica a posição dos pés com base na velocidade
    
    addi t4, t4, 1     # GRAVIDADE: Aumenta a velocidade de queda em +1 pixel por frame
    li  t5, 6          # Limite de velocidade de queda (Velocidade Terminal)
    ble t4, t5, SALVA_VEL 
    mv  t4, t5         # Se a aceleração passar de 6, fixa em 6 (evita atravessar plataformas)
SALVA_VEL:
    sw  t4, 0(t3)      # Armazena a velocidade atualizada

    la  t5, BG_POS     
    lh  s2, 0(t5)      # s2 = Posição atual de rolagem da câmera (Scroll X)

    la  t6, NUM_BLOCOS 
    lw  t6, 0(t6)      # t6 = Contador para o loop de plataformas (4 blocos)
    la  t3, LISTA_BLOCOS# t3 aponta para o início da lista de dados das plataformas

LOOP_GRAV:
    beq t6, zero, CHAO_ABS # Se testou todos os blocos e nenhum colidiu, cai no chão do mundo
    lh  a4, 0(t3)      # a4 = X mínimo real do bloco no mundo
    lh  a5, 2(t3)      # a5 = X máximo real do bloco no mundo
    lh  a6, 4(t3)      # a6 = Y do topo do bloco
    lh  a7, 6(t3)      # a7 = Y da base do bloco

    sub a4, a4, s2     # Converte o Xmin real do bloco para a coordenada da tela com base no Scroll
    sub a5, a5, s2     # Converte o Xmax real do bloco para a coordenada da tela com base no Scroll

    blt s11, a4, PROX_GRAV # Se a direita do Felix é menor que o início do bloco, não há colisão
    bgt t1, a5, PROX_GRAV  # Se a esquerda do Felix é maior que o fim do bloco, não há colisão

    lw  s7, VEL_Y      
    bge s7, zero, CHECK_CHAO_BLOCO # Se a velocidade for positiva ou zero (caindo), pula para testar pisada

    # --- COLISÃO COM O TETO DO BLOCO (Subindo no Pulo) ---
    blt t2, a7, PROX_GRAV  # Se o topo do Felix passou direto para cima da base do bloco, ignora
    bgt t2, a6, CHECK_CHAO_BLOCO # Se o topo está abaixo do topo do bloco, testa pisada
    
    mv  t2, a7         # Bateu a cabeça! Força a posição Y do topo a ficar rente à base do bloco
    li  s7, 0          
    la  s8, VEL_Y      
    sw  s7, 0(s8)      # Zera a velocidade vertical imediatamente (cancela a subida)
    j   FIM_GRAV

CHECK_CHAO_BLOCO:
    # --- COLISÃO COM O TOPO DO BLOCO (Aterrissagem) ---
    blt s10, a6, PROX_GRAV # Se a base dos pés não atingiu a linha do topo da plataforma, ignora
    addi s7, a6, 8         # Tolerância de profundidade de 8 pixels para detectar pisada firme
    bgt s10, s7, PROX_GRAV # Se afundou mais que 8 pixels, ignora (pode ser colisão lateral)
    
    sub t2, a6, s9     # Ajusta o Y do Felix: Posição do Topo = Linha da Plataforma - Altura do Boneco
    li  s7, 0          
    la  s8, VEL_Y      
    sw  s7, 0(s8)      # Para a queda (Velocidade Y = 0)
    la  s8, ESTA_NO_AR 
    sw  zero, 0(s8)    # Avisa o motor que o Felix agora ESTÁ NO CHÃO (pode pular novamente)
    j   FIM_GRAV       # Sai do loop de gravidade pois já achou o chão

PROX_GRAV:
    addi t3, t3, 8     # Avança o ponteiro da lista para a próxima plataforma (cada bloco = 4 halfs = 8 bytes)
    addi t6, t6, -1    # Decrementa o contador de blocos restantes
    j LOOP_GRAV

CHAO_ABS:
    # --- SISTEMA DE CHÃO DO MUNDO ---
    la  t5, FELIX_Y_MAX
    lh  t5, 0(t5)      # Carrega o limite inferior da tela física
    blt t2, t5, MARCA_AR # Se a posição calculada for menor que o chão, o boneco está caindo no ar vazio
    mv  t2, t5         # Se passou do limite, força a coordenada a travar na linha do chão definitivo
    la  t4, VEL_Y      
    sw  zero, 0(t4)    # Zera velocidade vertical
    la  t4, ESTA_NO_AR 
    sw  zero, 0(t4)    # Define que está pisando no chão seguro
    j   FIM_GRAV
MARCA_AR:
    li  t4, 1          
    la  t5, ESTA_NO_AR 
    sw  t4, 0(t5)      # Se não colidiu com nada acima, marca que ele continua flutuando no ar

FIM_GRAV:
    sh  t2, 2(t0)      # Atualiza em definitivo a coordenada Y ajustada no objeto CHAR_POS
    ret

PROCESSAR_COLISOES_LATERAIS:
    la  t0, CHAR_POS   
    lh  t1, 0(t0)      # t1 = X atual (Borda esquerda)
    lh  t2, 2(t0)      # t2 = Y atual (Topo da cabeça)
    
    la  s9, FELIX_ALTURA
    lh  s9, 0(s9)      
    add s10, t2, s9    # s10 = Y base (Pés do Felix)

    la  s11, FELIX_LARGURA
    lh  s11, 0(s11)    
    
    la  t3, OLD_CHAR_POS
    lh  t4, 0(t3)      # t4 = Posição X da tela no frame passado (Referência histórica)

    la  t5, BG_POS     
    lh  s2, 0(t5)      # s2 = Scroll X da câmera atual

    la  s5, OLD_BG_POS 
    lh  s3, 0(s5)      # s3 = Scroll X da câmera no frame passado

    la  t6, NUM_BLOCOS 
    lw  t6, 0(t6)      # t6 = Número de blocos a checar (4)
    la  t3, LISTA_BLOCOS
LOOP_LAT:
    beq t6, zero, FIM_LAT # Se varreu todas as estruturas, encerra
    lh  a4, 0(t3)      # Xmin absoluto do bloco
    lh  a5, 2(t3)      # Xmax absoluto do bloco
    lh  a6, 4(t3)      # Ytop absoluto do bloco
    lh  a7, 6(t3)      # Ybottom absoluto do bloco

    # --- AJUSTE RETROATIVO (FRAME ANTERIOR) ---
    sub s4, a4, s3     # s4 = Xmin do bloco na tela no frame passado
    sub s6, a5, s3     # s6 = Xmax do bloco na tela no frame passado

    # --- AJUSTE ATUAL ---
    sub a4, a4, s2     # a4 = Xmin do bloco na tela agora
    sub a5, a5, s2     # a5 = Xmax do bloco na tela agora

    # Checa se o Felix está verticalmente alinhado com o bloco. Se não estiver, ignora a colisão
    blt s10, a6, PROX_LAT # Pés acima do bloco -> Sem colisão lateral
    bgt t2, a7, PROX_LAT  # Cabeça abaixo do bloco -> Sem colisão lateral

    # LÓGICA DA ORIGEM: Descobre de onde o Felix veio para saber para onde empurrá-lo
    add s7, t4, s11    # s7 = Lado direito do Felix no frame anterior
    ble s7, s4, CHECA_PAREDE_ESQ # Se ele estava totalmente à esquerda da barreira, colidiu vindo da esquerda

    bge t4, s6, CHECA_PAREDE_DIR # Se ele estava totalmente à direita da barreira, colidiu vindo da direita
    j   PROX_LAT       # Se já estava dentro ou cruzado de outra forma, pula

CHECA_PAREDE_ESQ:
    add s8, t1, s11    # s8 = Posição direita atual do Felix
    blt s8, a4, PROX_LAT # Se ainda não tocou no Xmin atual do bloco, não bateu
    sub t1, a4, s11    # COLISÃO DETECTADA: Empurra o X do boneco de volta para a esquerda do bloco
    j   PROX_LAT

CHECA_PAREDE_DIR:
    blt t1, a5, AJUSTA_PAREDE_DIR # Se o X esquerdo atual invadiu o Xmax do bloco, colidiu vindo da direita
    j   PROX_LAT
AJUSTA_PAREDE_DIR:
    mv  t1, a5         # COLISÃO DETECTADA: Força o X do boneco a ficar travado na parede direita do bloco

PROX_LAT:
    addi t3, t3, 8     # Vai para o próximo bloco de dados de plataforma
    addi t6, t6, -1    # Decrementa contador
    j   LOOP_LAT
FIM_LAT:
    sh  t1, 0(t0)      # Grava a coordenada X final (corrigida contra as paredes) na memória
    ret

SELECT_FELIX:
    # Alterna entre os ponteiros das sprites para fazer a animação do boneco se mexer
    la  t0, FELIX_DIR  
    lw  t0, 0(t0)      # Carrega sentido do olhar
    beq t0, zero, FELIX_RIGHT
    li  t1, 1          
    beq t0, t1, FELIX_LEFT
FELIX_RIGHT:
    la  t2, FELIX_FRAME
    lw  t0, 0(t2)      # Pega o frame atual
    srli t0, t0, 2     # Divide o contador por 4 (faz a troca de animação acontecer mais devagar)
    andi t0, t0, 1     # Isola o bit 0 (Fica alternando estritamente entre 0 e 1)
    bnez t0, NOT_REBAIXADO # Se for 1, renderiza sprite normal
    la   a0, FelixRebaixado # Se for 0, usa a sprite rebaixada de corrida
    ret
NOT_REBAIXADO:
    la   a0, felix     
    ret
FELIX_LEFT:
    la  t2, FELIX_FRAME
    lw  t0, 0(t2)      
    srli t0, t0, 2     
    andi t0, t0, 1     
    bnez t0, NOT_REBAIXADO_LEFT
    la   a0, FelixOutroLadoRebaixado # Sprite rebaixada olhando para a esquerda
    ret
NOT_REBAIXADO_LEFT:
    la   a0, FelixOutroLado # Sprite normal olhando para a esquerda
    ret

PRINT:
    # Desenha imagens normais com dimensões variáveis no bitmap display
    li  t0, 0xFF0      # Base do endereço de vídeo (0xFF000000)
    add t0, t0, a3     # Adiciona o buffer ativo (0 ou 1) gerando 0xFF000000 ou 0xFF100000
    slli t0, t0, 20    # Desloca para formar o endereço base correto de vídeo
    add t0, t0, a1     # Adiciona o deslocamento X de destino
    li  t1, 320        # Largura total da tela em pixels
    mul t1, t1, a2     # Multiplica a linha Y por 320
    add t0, t0, t1     # Soma tudo: t0 agora guarda o endereço exato do pixel inicial na memória de vídeo
    addi t1, a0, 8     # Pula os metadados da imagem (.data guarda largura/altura nos 8 primeiros bytes)
    mv  t2, zero       # Inicializa contador de linhas processadas
    mv  t3, zero       # Inicializa contador de colunas processadas
    lw  t4, 0(a0)      # Lê o valor da largura da sprite em bytes
    lw  t5, 4(a0)      # Lê o valor da altura da sprite em pixels
PRINT_LINHA:
    lw  t6, 0(t1)      # Copia um bloco de 4 pixels (1 word) da imagem
    sw  t6, 0(t0)      # Descarrega esses 4 pixels diretamente na tela de vídeo
    addi t0, t0, 4     # Avança 4 bytes na tela de vídeo
    addi t1, t1, 4     # Avança 4 bytes na memória da imagem
    addi t3, t3, 4     # Incrementa contador de colunas da linha em +4
    blt  t3, t4, PRINT_LINHA # Se não terminou de desenhar a largura da linha, continua nela
    addi t0, t0, 320   # Salto de linha na tela: vai para a próxima linha vertical
    sub  t0, t0, t4     # Subtrai a largura desenhada para alinhar no X inicial correto
    mv  t3, zero       # Reseta contador de colunas da linha
    addi t2, t2, 1     # Incrementa contador de linhas verticais concluídas
    blt  t2, t5, PRINT_LINHA # Se ainda não desenhou toda a altura da sprite, continua o fluxo
    ret

PRINT_BACKGROUND:
    # Função otimizada para renderizar o cenário cobrindo a tela inteira (320x240)
    li   t0, 0xFF0     
    add  t0, t0, a3    # Seleciona o buffer correto
    slli t0, t0, 20    # Gera base 0xFF000000 ou 0xFF100000
    addi t1, a0, 8     # Pula os metadados da estrutura de imagem do fundo
    lw   t4, 0(a0)     # Carrega a largura interna total da imagem de fundo
    add  t1, t1, a1    # Aplica o offset X do corte da câmera na origem da imagem
    li   t2, 0         # Contador de linhas da tela
    li   t5, 240       # Altura máxima da tela de vídeo
PRINT_BG_LINHA:
    li   t3, 0         # Contador de colunas da linha atual
PRINT_BG_COLUNA:
    lw   t6, 0(t1)     # Copia os pixels da imagem
    sw   t6, 0(t0)     # Grava direto na tela
    addi t0, t0, 4     
    addi t1, t1, 4     
    addi t3, t3, 4     
    li   t6, 320       # Verifica se preencheu toda a largura física da tela (320 pixels)
    blt  t3, t6, PRINT_BG_COLUNA # Enquanto não encher a linha da tela, continua copiando
    sub  t1, t1, t3    # Retorna o ponteiro do fundo ao X inicial do corte
    add  t1, t1, t4    # Pula a linha inteira da matriz da imagem de origem usando sua largura nativa
    addi t2, t2, 1     # Próxima linha da tela
    blt  t2, t5, PRINT_BG_LINHA # Continua até cobrir as 240 linhas verticais da tela
    ret