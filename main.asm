# ==============================================================================================
# SEÇÃO DE DADOS (.data)
# Configuração e mapeamento das imagens, variáveis de estado e arquivos de áudio do jogo.
# ==============================================================================================
.data

.include "imagens/felix.data"
.include "imagens/fundo.data"
.include "imagens/tile.data"
.include "imagens/telainicial.data"
.include "imagens/AndarPDireitaFelix.data"
.include "imagens/AndarPEsquerdaFelix.data"
.include "imagens/FelixOutroLado.data"
.include "imagens/FelixOutroLadoRebaixado.data"
.include "imagens/FelixRebaixado.data"

notas: .word 9, 0, 0, 67, 1000, 0, 74, 1000, 0, 70, 1500, 0, 69, 500, 0, 67, 500, 0, 70, 500, 0, 69, 500, 0, 67, 500, 0, 66, 500, 0,

CHAR_POS:     .half 30, 120
OLD_CHAR_POS: .half 0, 0

BG_POS:     .half 0, 0
OLD_BG_POS: .half 0, 0

BG_X_MIN:  .half 0
BG_X_MAX:  .half 80

FELIX_X_MIN: .half 0
FELIX_X_MAX: .half 304
FELIX_Y_MIN: .half 0
FELIX_Y_MAX: .half 224

FELIX_DIR:   .word 1
FELIX_FRAME: .word 0

VEL_Y:       .word 0
ESTA_NO_AR:  .word 1

# ==============================================================================================
# SEÇÃO DE CÓDIGO (.text)
# Rotinas de inicialização, loop principal, processamento de entrada e renderização gráfica.
# ==============================================================================================
.text

SETUP:
    la  a0, telainicial
    li  a1, 0
    li  a2, 0
    li  a3, 0
    call PRINT

KEY1:
    li  t1, 0xFF200000
WAIT_KEY:
    lw  t0, 0(t1)
    andi t0, t0, 0x0001
    beq t0, zero, WAIT_KEY
    lw  t2, 4(t1)
    sw  t2, 12(t1)

    la   a0, fundo
    lh   a1, 0(a0)
    li   a2, 0
    li   a3, 0
    call PRINT_BACKGROUND
    li   a3, 1
    call PRINT_BACKGROUND

GAME_LOOP:
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
    ecall
    li  a7, 30
    ecall
    sw  a0, 8(s1)
    addi s3, s3, 1
    sw  s3, 4(s1)

MF0:
    la  t0, FELIX_FRAME
    lw  t1, 0(t0)
    addi t1, t1, 1
    sw  t1, 0(t0)

    call SELECT_FELIX
    call KEY2
    
    call APLICAR_GRAVIDADE

    xori s0, s0, 1

    la  t0, CHAR_POS
    lh  a1, 0(t0)
    lh  a2, 2(t0)
    mv  a3, s0
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

    li a0, 30
    li a7, 32
    ecall

    j GAME_LOOP

KEY2:
    li  t1, 0xFF200000
    lw  t0, 0(t1)
    andi t0, t0, 0x0001
    beq  t0, zero, KEY2_CHECAR_AR
    lw   t2, 4(t1)
    j    KEY2_PROCESSA

KEY2_CHECAR_AR:
    la   t0, ESTA_NO_AR
    lw   t3, 0(t0)
    bnez t3, KEY2_CONTINUO
    j    KEY2_FIM

KEY2_CONTINUO:
    lw   t2, 4(t1)

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
    la  t0, FELIX_DIR
    li  t1, 1
    sw  t1, 0(t0)

    la  t0, BG_POS
    lh  t1, 0(t0)
    
    la  t2, BG_X_MIN
    lh  t2, 0(t2)
    beq t1, t2, MOVE_LEFT_FELIX

    la  t3, CHAR_POS
    lh  t4, 0(t3)
    li  t5, 30
    bgt t4, t5, MOVE_LEFT_FELIX

    addi t1, t1, -2
    bge t1, t2, ML_BG_OK
    mv  t1, t2
ML_BG_OK:
    sh  t1, 0(t0)
    ret

MOVE_LEFT_FELIX:
    la  t3, CHAR_POS
    lh  t4, 0(t3)
    addi t4, t4, -2
    la  t2, FELIX_X_MIN
    lh  t2, 0(t2)
    bge t4, t2, ML_FX_OK
    mv  t4, t2
ML_FX_OK:
    sh  t4, 0(t3)
    ret

MOVE_RIGHT:
    la  t0, FELIX_DIR
    li  t1, 0
    sw  t1, 0(t0)

    la  t3, CHAR_POS
    lh  t4, 0(t3)
    li  t5, 274
    blt t4, t5, MOVE_RIGHT_FELIX

    la  t0, BG_POS
    lh  t1, 0(t0)
    la  t2, BG_X_MAX
    lh  t2, 0(t2)
    beq t1, t2, MOVE_RIGHT_FELIX

    addi t1, t1, 2
    ble t1, t2, MR_BG_OK
    mv  t1, t2
MR_BG_OK:
    sh  t1, 0(t0)
    ret

MOVE_RIGHT_FELIX:
    la  t3, CHAR_POS
    lh  t4, 0(t3)
    
    la  t0, BG_POS
    lh  t1, 0(t0)
    la  t2, BG_X_MAX
    lh  t2, 0(t2)
    beq t1, t2, MR_FX_LIMIT
    
    li  t5, 274
    blt t4, t5, MR_FX_CONTINUE
    mv  t4, t5
    j MR_FX_OK

MR_FX_LIMIT:
    la  t2, FELIX_X_MAX
    lh  t2, 0(t2)
    blt t4, t2, MR_FX_CONTINUE
    mv  t4, t2
    j MR_FX_OK

MR_FX_CONTINUE:
    addi t4, t4, 2

MR_FX_OK:
    sh  t4, 0(t3)
    ret

MOVE_UP:
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
    la  t0, CHAR_POS
    lh  t1, 2(t0)
    addi t1, t1, 2

    la  t2, FELIX_Y_MAX
    lh  t2, 0(t2)
    ble t1, t2, MD_OK
    mv  t1, t2
MD_OK:
    sh  t1, 2(t0)
    ret

APLICAR_GRAVIDADE:
    la  t0, CHAR_POS
    lh  t1, 0(t0)
    lh  t2, 2(t0)

    la  t3, VEL_Y
    lw  t4, 0(t3)

    add t2, t2, t4
    
    addi t4, t4, 1
    li  t5, 6
    ble t4, t5, SALVA_VEL
    mv  t4, t5
SALVA_VEL:
    sw  t4, 0(t3)

    li  t5, 160
    bgt t1, t5, VERIFICA_FIM_TELA

    li  t6, 120
    bge t2, t6, COLISAO_BLOCO
    j   VALIDA_LIMITES_JANELA

COLISAO_BLOCO:
    mv  t2, t6
    li  t4, 0
    sw  t4, 0(t3)
    la  t4, ESTA_NO_AR
    sw  zero, 0(t4)
    j   VALIDA_LIMITES_JANELA

VERIFICA_FIM_TELA:
    la  t5, FELIX_Y_MAX
    lh  t5, 0(t5)
    blt t2, t5, MARCA_NO_AR
    mv  t2, t5
    li  t4, 0
    sw  t4, 0(t3)
    la  t4, ESTA_NO_AR
    sw  zero, 0(t4)
    j   VALIDA_LIMITES_JANELA

MARCA_NO_AR:
    li  t4, 1
    la  t5, ESTA_NO_AR
    sw  t4, 0(t5)

VALIDA_LIMITES_JANELA:
    la  t5, FELIX_Y_MIN
    lh  t5, 0(t5)
    bge t2, t5, Y_MIN_OK
    mv  t2, t5
    la  t4, VEL_Y
    sw  zero, 0(t4)
Y_MIN_OK:
    sh  t2, 2(t0)
    ret

SELECT_FELIX:
    la  t0, FELIX_DIR
    lw  t0, 0(t0)
    beq t0, zero, FELIX_RIGHT
    li  t1, 1
    beq t0, t1, FELIX_LEFT

FELIX_RIGHT:
    la  t2, FELIX_FRAME
    lw  t0, 0(t2)
    srli t0, t0, 2
    andi t0, t0, 1
    bnez t0, NOT_REBAIXADO
    la   a0, FelixRebaixado
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
    la   a0, FelixOutroLadoRebaixado
    ret
NOT_REBAIXADO_LEFT:
    la   a0, FelixOutroLado
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

PRINT_BACKGROUND:
    li   t0, 0xFF0
    add  t0, t0, a3
    slli t0, t0, 20
    addi t1, a0, 8
    lw   t4, 0(a0)
    add  t1, t1, a1
    li   t2, 0
    li   t5, 240
PRINT_BG_LINHA:
    li   t3, 0
PRINT_BG_COLUNA:
    lw   t6, 0(t1)
    sw   t6, 0(t0)
    addi t0, t0, 4
    addi t1, t1, 4
    addi t3, t3, 4
    li   t6, 320
    blt  t3, t6, PRINT_BG_COLUNA
    sub  t1, t1, t3
    add  t1, t1, t4
    addi t2, t2, 1
    blt  t2, t5, PRINT_BG_LINHA
    ret