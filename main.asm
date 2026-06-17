.data

.include "consts.s"


.include "imagens/MAPA1_defs.s"
.include "imagens/MAPA1_colisao.s"
.include "imagens/MAPA1_visual.s"
.include "imagens/MAPA1_entidades.s"
.include "imagens/megaman_direita.data"
.include "imagens/tileset.data"
.include "imagens/tela_inicial1.data"
.include "imagens/tela_inicial2.data"
.include "imagens/megaman_correndo_direita1.data"
.include "imagens/megaman_correndo_direita2.data"
.include "imagens/megaman_correndo_direita3.data"
.include "imagens/megaman_correndo_esquerda1.data"
.include "imagens/megaman_correndo_esquerda2.data"
.include "imagens/megaman_correndo_esquerda3.data"
.include "imagens/megaman_esquerda.data"
.include "imagens/megaman_piscando_esquerda.data"
.include "imagens/megaman_piscando_direita.data"
.include "imagens/megaman_pulando_direita.data"
.include "imagens/megaman_pulando_esquerda.data"
.include "imagens/megaman_subindo_escada_1.data"
.include "imagens/megaman_subindo_escada_2.data"

notas: .word 9, 0, 0, 67, 1000, 0, 74, 1000, 0, 70, 1500, 0, 69, 500, 0, 67, 500, 0, 70, 500, 0, 69, 500, 0, 67, 500, 0, 66, 500, 0,

CHAR_POS:     .half 16, 168
OLD_CHAR_POS: .half 16, 168

BG_POS:     .half 0, 0
OLD_BG_POS: .half 0, 0

PLAYER_DIR:    .word 1
PLAYER_FRAME:  .word 0
ESTA_MOVENDO: .word 0

VEL_Y:          .word 0
ESTA_NO_AR:     .word 0
ESTA_NA_ESCADA: .word 0

ULTIMA_TECLA:        .word 0
ULTIMA_TECLA_TEMPO:   .word 0
TECLA_TIMEOUT:        .word 150   # ms: se nenhuma tecla nova chegar nesse intervalo, considera solta


.text

SETUP:
    la  a0, tela_inicial1
    li  a1, 0
    li  a2, 0
    li  a3, 0
    call PRINT

    li  s11, 0

KEY1:
    li  s10, 0xFF200000
WAIT_KEY:
    li  a0, 5
    li  a7, 32
    ecall

    li  a7, 30
    ecall
    srli t2, a0, 9
    andi t2, t2, 1
    beq t2, s11, CHECK_KEY_INPUT

    mv  s11, t2
    bnez t2, MOSTRA_TELA2

MOSTRA_TELA1:
    la  a0, tela_inicial1
    li  a1, 0
    li  a2, 0
    li  a3, 0
    call PRINT
    j CHECK_KEY_INPUT

MOSTRA_TELA2:
    la  a0, tela_inicial2
    li  a1, 0
    li  a2, 0
    li  a3, 0
    call PRINT

CHECK_KEY_INPUT:
    lw  t0, 0(s10)
    andi t0, t0, 0x0001
    beq t0, zero, WAIT_KEY
    lw  t2, 4(s10)
    sw  t2, 12(s10)

    li  a3, 0
    call PRINT_MAPA
    li  a3, 1
    call PRINT_MAPA

GAME_LOOP:
    li  a7, 30
    ecall
    mv  s9, a0          # s9 = tempo de inicio desta iteracao (fixed timestep ~60fps)

    la  t0, CHAR_POS
    la  t1, OLD_CHAR_POS
    lh  t2, 0(t0)
    sh  t2, 0(t1)
    lh  t2, 2(t0)
    sh  t2, 2(t1)

    la  t0, BG_POS
    la  t1, OLD_BG_POS
    lh  t2, 0(t0)
    sh  t2, 0(t1)
    lh  t2, 2(t0)
    sh  t2, 2(t1)

    la  t0, ESTA_MOVENDO
    sw  zero, 0(t0)

    la  s1, notas
    lw  s2, 0(s1)
    lw  s3, 4(s1)
    lw  s4, 8(s1)
    li  t0, 12
    mul s5, t0, s3
    add s5, s5, s1
    li  a7, 30
    ecall
    sub s6, a0, s4
    lw  t1, 4(s5)
    bgtu t1, s6, MF0
    bne s3, s2, MF1
    li  s3, 0
    mv  s5, s1
MF1:
    addi s5, s5, 12
    li  a7, 31
    lw  a0, 0(s5)
    lw  a1, 4(s5)
    li  a2, 0
    li  a3, 60
    # ecall
    li  a7, 30
    ecall
    sw  a0, 8(s1)
    addi s3, s3, 1
    sw  s3, 4(s1)

MF0:
    la  t0, PLAYER_FRAME
    lw  t1, 0(t0)
    addi t1, t1, 1
    sw  t1, 0(t0)

    call CHECAR_ESCADA
    call KEY2
    call APLICAR_GRAVIDADE
    call PROCESSAR_COLISOES_LATERAIS
    call SELECT_PLAYER

    xori s0, s0, 1
    la  t0, CHAR_POS
    lh  a1, 0(t0)
    lh  a2, 2(t0)
    mv  a3, s0
    call PRINT

    li   t0, 0xFF200604
    sw   s0, 0(t0)

    mv   a3, s0
    xori a3, a3, 1
    call PRINT_MAPA

    li  a7, 30
    ecall
    sub  t0, a0, s9      # t0 = duracao real desta iteracao em ms
    li  t1, 16            # alvo: ~60 FPS (16ms por frame)
    sub  t1, t1, t0
    bltz t1, GL_NO_SLEEP  # se a iteracao ja levou 16ms ou mais, nao dorme

    mv  a0, t1
    li  a7, 32
    ecall
GL_NO_SLEEP:
    j GAME_LOOP

CHECAR_ESCADA:
    la  t0, ESTA_NA_ESCADA
    sw  zero, 0(t0)
    ret

KEY2:
    li  t1, 0xFF200000
    lw  t0, 0(t1)
    andi t0, t0, 0x0001
    beq  t0, zero, KEY2_SEM_TECLA_NOVA

    lw  t2, 4(t1)
    la  t3, ULTIMA_TECLA
    sw  t2, 0(t3)
    li  a7, 30
    ecall
    la  t3, ULTIMA_TECLA_TEMPO
    sw  a0, 0(t3)
    j   KEY2_PROCESSA

KEY2_SEM_TECLA_NOVA:
    li  a7, 30
    ecall
    la  t3, ULTIMA_TECLA_TEMPO
    lw  t4, 0(t3)
    sub t5, a0, t4
    la  t6, TECLA_TIMEOUT
    lw  t6, 0(t6)
    bge t5, t6, KEY2_FIM   # passou do timeout: considera tecla solta, nao move

    la  t3, ULTIMA_TECLA
    lw  t2, 0(t3)
KEY2_PROCESSA:
    li  t0, 'a'
    beq t2, t0, MOVE_LEFT
    li  t0, 'd'
    beq t2, t0, MOVE_RIGHT
    li  t0, 'w'
    beq t2, t0, MOVE_UP
    li  t0, 's'
    beq t2, t0, MOVE_DOWN
KEY2_FIM:
    ret

MOVE_LEFT:
    li  t4, 1
    la  t3, ESTA_MOVENDO
    sw  t4, 0(t3)
    la  t0, PLAYER_DIR
    li  t1, 1
    sw  t1, 0(t0)
    la  t0, BG_POS
    lh  t1, 0(t0)
    li  t2, BG_X_MIN
    beq t1, t2, MOVE_LEFT_PLAYER
    la  t3, CHAR_POS
    lh  t4, 0(t3)
    li  t5, 30
    bgt t4, t5, MOVE_LEFT_PLAYER
    addi t1, t1, -2
    bge t1, t2, ML_BG_OK
    mv  t1, t2
ML_BG_OK:
    sh  t1, 0(t0)
    ret
MOVE_LEFT_PLAYER:
    la  t3, CHAR_POS
    lh  t4, 0(t3)
    addi t4, t4, -2
    li  t2, PLAYER_X_MIN
    bge t4, t2, ML_FX_OK
    mv  t4, t2
ML_FX_OK:
    sh  t4, 0(t3)
    ret

MOVE_RIGHT:
    li  t4, 1
    la  t3, ESTA_MOVENDO
    sw  t4, 0(t3)
    la  t0, PLAYER_DIR
    li  t1, 0
    sw  t1, 0(t0)
    la  t3, CHAR_POS
    lh  t4, 0(t3)
    li  t5, 274
    blt t4, t5, MOVE_RIGHT_PLAYER
    la  t0, BG_POS
    lh  t1, 0(t0)
    li  t2, BG_X_MAX
    beq t1, t2, MOVE_RIGHT_PLAYER
    addi t1, t1, 2
    ble t1, t2, MR_BG_OK
    mv  t1, t2
MR_BG_OK:
    sh  t1, 0(t0)
    ret
MOVE_RIGHT_PLAYER:
    la  t3, CHAR_POS
    lh  t4, 0(t3)
    la  t0, BG_POS
    lh  t1, 0(t0)
    li  t2, BG_X_MAX
    beq t1, t2, MR_FX_LIMIT
    li  t5, 274
    blt t4, t5, MR_FX_CONTINUE
    mv  t4, t5
    j MR_FX_OK
MR_FX_LIMIT:
    li  t2, PLAYER_X_MAX
    blt t4, t2, MR_FX_CONTINUE
    mv  t4, t2
    j MR_FX_OK
MR_FX_CONTINUE:
    addi t4, t4, 2
MR_FX_OK:
    sh  t4, 0(t3)
    ret

MOVE_UP:
    li  t4, 1
    la  t3, ESTA_MOVENDO
    sw  t4, 0(t3)
    la  t0, ESTA_NA_ESCADA
    lw  t1, 0(t0)
    beqz t1, JUMP_LOGIC
    la  t0, CHAR_POS
    lh  t1, 2(t0)
    li  t5, 40
    bgt t1, t5, MOVE_UP_PLAYER_ESCADA
    la  t2, BG_POS
    lh  t3, 2(t2)
    li  t4, BG_Y_MIN
    beq t3, t4, MOVE_UP_PLAYER_ESCADA
    addi t3, t3, -2
    bge t3, t4, MU_BG_OK
    mv  t3, t4
MU_BG_OK:
    sh  t3, 2(t2)
    ret
MOVE_UP_PLAYER_ESCADA:
    addi t1, t1, -2
    li  t2, PLAYER_Y_MIN
    bge t1, t2, MU_FX_OK
    mv  t1, t2
MU_FX_OK:
    sh  t1, 2(t0)
    ret
JUMP_LOGIC:
    la  t0, ESTA_NO_AR
    lw  t1, 0(t0)
    bnez t1, FIM_MOVE_UP
    li  t1, -8
    la  t2, VEL_Y
    sw  t1, 0(t2)
    li  t1, 1
    sw  t1, 0(t0)
FIM_MOVE_UP:
    ret

MOVE_DOWN:
    li  t4, 1
    la  t3, ESTA_MOVENDO
    sw  t4, 0(t3)
    la  t0, ESTA_NA_ESCADA
    lw  t1, 0(t0)
    beqz t1, NORMAL_DOWN
    la  t0, CHAR_POS
    lh  t1, 2(t0)
    li  t5, 180
    blt t1, t5, MOVE_DOWN_PLAYER_ESCADA
    la  t2, BG_POS
    lh  t3, 2(t2)
    li  t4, BG_Y_MAX
    beq t3, t4, MOVE_DOWN_PLAYER_ESCADA
    addi t3, t3, 2
    ble t3, t4, MD_ESCADA_BG_OK
    mv  t3, t4
MD_ESCADA_BG_OK:
    sh  t3, 2(t2)
    ret
MOVE_DOWN_PLAYER_ESCADA:
    addi t1, t1, 2
    li  t2, PLAYER_Y_MAX
    ble t1, t2, MD_ESCADA_FX_OK
    mv  t1, t2
MD_ESCADA_FX_OK:
    sh  t1, 2(t0)
    ret
NORMAL_DOWN:
    la  t0, CHAR_POS
    lh  t1, 2(t0)
    li  t5, 180
    blt t1, t5, MOVE_DOWN_PLAYER
    la  t2, BG_POS
    lh  t3, 2(t2)
    li  t4, BG_Y_MAX
    beq t3, t4, MOVE_DOWN_PLAYER
    addi t3, t3, 2
    ble t3, t4, MD_BG_OK
    mv  t3, t4
MD_BG_OK:
    sh  t3, 2(t2)
    ret
MOVE_DOWN_PLAYER:
    addi t1, t1, 2
    li  t2, PLAYER_Y_MAX
    ble t1, t2, MD_OK
    mv  t1, t2
MD_OK:
    sh  t1, 2(t0)
    ret

APLICAR_GRAVIDADE:
    la  t0, ESTA_NA_ESCADA
    lw  t1, 0(t0)
    beqz t1, GRAVIDADE_NORMAL
    la  t0, VEL_Y
    sw  zero, 0(t0)
    ret

GRAVIDADE_NORMAL:
    addi sp, sp, -4
    sw   ra, 0(sp)
    la  t0, CHAR_POS
    lh  s1, 0(t0)       # s1 = char_x (tela)
    lh  s2, 2(t0)       # s2 = char_y (tela)

    li  s3, PLAYER_LARGURA
    li  s4, PLAYER_ALTURA

    la  t3, VEL_Y
    lw  s5, 0(t3)

    add s2, s2, s5

    bltz s2, GRAV_ZERO_TOP
    j    GRAV_YMAX_CHK
GRAV_ZERO_TOP:
    li  s2, 0
    la  t0, VEL_Y
    sw  zero, 0(t0)
GRAV_YMAX_CHK:
    li  t0, PLAYER_Y_MAX
    ble s2, t0, GRAV_YMAX_OK
    mv  s2, t0
    la  t0, VEL_Y
    sw  zero, 0(t0)
GRAV_YMAX_OK:
    add s6, s2, s4
    addi s6, s6, -1     # s6 = pixel mais baixo do sprite

    bltz s5, GRAV_CHECK_CIMA

GRAV_CHECK_BAIXO:
    # checa um pixel ABAIXO dos pés para detectar chão sem oscilação
    addi a0, s1, 1
    addi a1, s6, 1
    call CHECA_TILE
    bnez a0, GRAV_POUSA
    add  a0, s1, s3
    addi a0, a0, -1
    addi a1, s6, 1
    call CHECA_TILE
    bnez a0, GRAV_POUSA
    li   t0, 1
    la   t1, ESTA_NO_AR
    sw   t0, 0(t1)
    j    GRAV_ACCEL

GRAV_POUSA:
    addi s7, s6, 1
    srli s7, s7, 4
    slli s7, s7, 4      # topo do tile sólido
    sub  s2, s7, s4     # char_y = topo_tile - altura
    la   t0, VEL_Y
    sw   zero, 0(t0)
    la   t0, ESTA_NO_AR
    sw   zero, 0(t0)
    j    GRAV_FIM

GRAV_CHECK_CIMA:
    addi a0, s1, 1
    mv   a1, s2
    call CHECA_TILE
    bnez a0, GRAV_BATE_TETO
    add  a0, s1, s3
    addi a0, a0, -1
    mv   a1, s2
    call CHECA_TILE
    bnez a0, GRAV_BATE_TETO
    li   t0, 1
    la   t1, ESTA_NO_AR
    sw   t0, 0(t1)
    j    GRAV_ACCEL

GRAV_BATE_TETO:
    srli s7, s2, 4
    addi s7, s7, 1
    slli s2, s7, 4      # char_y = linha abaixo do tile de teto
    la   t0, VEL_Y
    sw   zero, 0(t0)
    li   t0, 1
    la   t1, ESTA_NO_AR
    sw   t0, 0(t1)
    j    GRAV_FIM

GRAV_ACCEL:
    addi s5, s5, 1
    li   t0, 6
    ble  s5, t0, GRAV_SALVA
    mv   s5, t0
GRAV_SALVA:
    la   t0, VEL_Y
    sw   s5, 0(t0)

GRAV_FIM:
    la  t0, CHAR_POS
    sh  s2, 2(t0)
    lw  ra, 0(sp)
    addi sp, sp, 4
    ret

PROCESSAR_COLISOES_LATERAIS:
    addi sp, sp, -4
    sw   ra, 0(sp)
    la  t0, CHAR_POS
    lh  s1, 0(t0)       # s1 = char_x
    lh  s2, 2(t0)       # s2 = char_y

    li  s3, PLAYER_LARGURA
    li  s4, PLAYER_ALTURA

    mv   a0, s1
    srli s7, s4, 1
    add  a1, s2, s7
    call CHECA_TILE
    bnez a0, COL_ESQ

    mv   a0, s1
    add  a1, s2, s4
    addi a1, a1, -2
    call CHECA_TILE
    bnez a0, COL_ESQ
    j    COL_CHECK_DIR

COL_ESQ:
    srli s5, s1, 4
    addi s5, s5, 1
    slli s1, s5, 4

COL_CHECK_DIR:
    add  s6, s1, s3
    addi s6, s6, -1

    mv   a0, s6
    srli s7, s4, 1
    add  a1, s2, s7
    call CHECA_TILE
    bnez a0, COL_DIR

    mv   a0, s6
    add  a1, s2, s4
    addi a1, a1, -2
    call CHECA_TILE
    bnez a0, COL_DIR
    j    COL_CLAMP

COL_DIR:
    srli s5, s6, 4
    slli s5, s5, 4
    sub  s1, s5, s3

COL_CLAMP:
    li  t0, PLAYER_X_MIN
    bge s1, t0, COL_XMAX
    mv  s1, t0
COL_XMAX:
    li  t0, PLAYER_X_MAX
    ble s1, t0, COL_SAVE
    mv  s1, t0
COL_SAVE:
    la  t0, CHAR_POS
    sh  s1, 0(t0)
    lw  ra, 0(sp)
    addi sp, sp, 4
    ret

SELECT_PLAYER:
    la  t0, ESTA_NA_ESCADA
    lw  t1, 0(t0)
    bnez t1, ANIMAR_ESCADA

    la  t0, ESTA_NO_AR
    lw  t1, 0(t0)
    bnez t1, ANIMAR_PULO

    la  t0, ESTA_MOVENDO
    lw  t1, 0(t0)
    bnez t1, ANIMAR_ANDANDO

    la  t0, PLAYER_DIR
    lw  t0, 0(t0)
    beq t0, zero, PARADO_RIGHT

PARADO_LEFT:
    la  t2, PLAYER_FRAME
    lw  t0, 0(t2)
    srli t0, t0, 3
    andi t0, t0, 1
    bnez t0, NOT_REBAIXADO_LEFT
    la   a0, megaman_piscando_esquerda
    ret
NOT_REBAIXADO_LEFT:
    la   a0, megaman_esquerda
    ret

PARADO_RIGHT:
    la  t2, PLAYER_FRAME
    lw  t0, 0(t2)
    srli t0, t0, 3
    andi t0, t0, 1
    bnez t0, NOT_REBAIXADO
    la   a0, megaman_piscando_direita
    ret
NOT_REBAIXADO:
    la   a0, megaman_direita
    ret

ANIMAR_ANDANDO:
    la  t0, PLAYER_DIR
    lw  t0, 0(t0)
    beq t0, zero, ANDANDO_RIGHT

ANDANDO_LEFT:
    la  t2, PLAYER_FRAME
    lw  t0, 0(t2)
    srli t0, t0, 2
    li  t1, 3
    rem t0, t0, t1

    li  t1, 1
    beq t0, t1, RUN_L2
    li  t1, 2
    beq t0, t1, RUN_L3
RUN_L1:
    la  a0, megaman_correndo_esquerda1
    ret
RUN_L2:
    la  a0, megaman_correndo_esquerda2
    ret
RUN_L3:
    la  a0, megaman_correndo_esquerda3
    ret

ANDANDO_RIGHT:
    la  t2, PLAYER_FRAME
    lw  t0, 0(t2)
    srli t0, t0, 2
    li  t1, 3
    rem t0, t0, t1

    li  t1, 1
    beq t0, t1, RUN_R2
    li  t1, 2
    beq t0, t1, RUN_R3
RUN_R1:
    la  a0, megaman_correndo_direita1
    ret
RUN_R2:
    la  a0, megaman_correndo_direita2
    ret
RUN_R3:
    la  a0, megaman_correndo_direita3
    ret

ANIMAR_PULO:
    la  t0, PLAYER_DIR
    lw  t0, 0(t0)
    beq t0, zero, PULO_RIGHT
PULO_LEFT:
    la  a0, megaman_pulando_esquerda
    ret
PULO_RIGHT:
    la  a0, megaman_pulando_direita
    ret

ANIMAR_ESCADA:
    la  t0, ESTA_MOVENDO
    lw  t1, 0(t0)
    beqz t1, ESCADA_PARADO
    la  t2, PLAYER_FRAME
    lw  t0, 0(t2)
    srli t0, t0, 3
    andi t0, t0, 1
    bnez t0, ESCADA_LADO2
ESCADA_LADO1:
    la  a0, megaman_subindo_escada_1
    ret
ESCADA_LADO2:
    la  a0, megaman_subindo_escada_2
    ret
ESCADA_PARADO:
    la  a0, megaman_subindo_escada_1
    ret

PRINT:
    li  t0, 0xFF0
    add t0, t0, a3
    slli t0, t0, 20
    add t0, t0, a1
    li  t1, 320
    mul t1, t1, a2
    add t0, t0, t1
    addi t1, a0, 8
    mv  t2, zero
    mv  t3, zero
    lw  t4, 0(a0)
    lw  t5, 4(a0)
PRINT_LINHA:
    lw  t6, 0(t1)
    sw  t6, 0(t0)
    addi t0, t0, 4
    addi t1, t1, 4
    addi t3, t3, 4
    blt  t3, t4, PRINT_LINHA
    addi t0, t0, 320
    sub  t0, t0, t4
    mv  t3, zero
    addi t2, t2, 1
    blt  t2, t5, PRINT_LINHA
    ret

CHECA_TILE:
    la  t0, BG_POS
    lh  t1, 0(t0)
    lh  t2, 2(t0)
    add a0, a0, t1
    add a1, a1, t2
    bltz a0, TILE_VAZIO
    bltz a1, TILE_VAZIO
    srli t0, a0, 4
    srli t1, a1, 4
    li   t2, MAPA1_MAP_COLS
    bge  t0, t2, TILE_VAZIO
    li   t3, MAPA1_MAP_ROWS
    bge  t1, t3, TILE_VAZIO
    mul  t2, t1, t2
    add  t2, t2, t0
    la   t3, MAPA1_COLISAO
    add  t3, t3, t2
    lbu  a0, 0(t3)
    ret
TILE_VAZIO:
    li  a0, 0
    ret

PRINT_TILE:
    li   t0, 12
    rem  t1, a0, t0
    div  t2, a0, t0

    li   t3, 0
    bgez a1, PT_CL_OK
    sub  t3, zero, a1
PT_CL_OK:
    li   t4, 0
    addi t5, a1, 16
    li   t6, 320
    ble  t5, t6, PT_CR_OK
    sub  t4, t5, t6
PT_CR_OK:
    li   t5, 16
    sub  t5, t5, t3
    sub  t5, t5, t4
    blez t5, PT_RET

    la   t6, tileset
    addi t6, t6, 8
    li   t0, 3072
    mul  t0, t2, t0
    add  t6, t6, t0
    slli t0, t1, 4
    add  t6, t6, t0
    add  t6, t6, t3

    li   t0, 0xFF0
    add  t0, t0, a3
    slli t0, t0, 20
    add  t1, a1, t3
    li   t2, 320
    mul  t2, a2, t2
    add  t1, t1, t2
    add  t1, t0, t1

    li   t4, 0
PT_ROW:
    mv   t2, t6
    mv   t3, t1
    mv   t0, t5
PT_PIX:
    lbu  a0, 0(t2)
    sb   a0, 0(t3)
    addi t2, t2, 1
    addi t3, t3, 1
    addi t0, t0, -1
    bnez t0, PT_PIX
    li   t0, 192
    add  t6, t6, t0
    li   t0, 320
    add  t1, t1, t0
    addi t4, t4, 1
    li   t0, 16
    blt  t4, t0, PT_ROW
PT_RET:
    ret

PRINT_MAPA:
    addi sp, sp, -28
    sw   ra,  0(sp)
    sw   s1,  4(sp)
    sw   s2,  8(sp)
    sw   s3, 12(sp)
    sw   s4, 16(sp)
    sw   s5, 20(sp)
    sw   s6, 24(sp)

    la   t0, BG_POS
    lh   s1, 0(t0)
    srli s2, s1, 4
    andi s3, s1, 15
    mv   s4, a3

    li   s5, 0
RM_ROW:
    li   s6, 0
RM_COL:
    add  t0, s2, s6
    li   t1, MAPA1_MAP_COLS
    bge  t0, t1, RM_NEXT_ROW

    slli t2, s6, 4
    sub  t2, t2, s3
    li   t3, 320
    bge  t2, t3, RM_NEXT_ROW

    slli t4, s5, 4

    li   t5, MAPA1_MAP_COLS
    mul  t5, s5, t5
    add  t5, t5, t0
    la   t6, MAPA1_VISUAL
    add  t6, t6, t5
    lbu  t5, 0(t6)

    mv   a0, t5
    mv   a1, t2
    mv   a2, t4
    mv   a3, s4
    call PRINT_TILE

    addi s6, s6, 1
    li   t0, 21
    blt  s6, t0, RM_COL

RM_NEXT_ROW:
    addi s5, s5, 1
    li   t0, MAPA1_MAP_ROWS
    blt  s5, t0, RM_ROW

    lw   ra,  0(sp)
    lw   s1,  4(sp)
    lw   s2,  8(sp)
    lw   s3, 12(sp)
    lw   s4, 16(sp)
    lw   s5, 20(sp)
    lw   s6, 24(sp)
    addi sp, sp, 28
    ret