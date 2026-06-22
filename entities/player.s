.data

PLAYER_POSITION:     .half 0, 0
PLAYER_OLD_POSITION: .half 16, 168
PLAYER_DIRECTION:    .word 0
PLAYER_ANIMATION_FRAME: .word 0
PLAYER_IS_MOVING:    .word 0
PLAYER_VEL_Y:        .word 0
PLAYER_IS_IN_AIR:    .word 0
PLAYER_IS_ON_LADDER: .word 0
PLAYER_STATE:        .word PLAYER_STATE_IDLE

.text

# PLAYER_SETUP
# Inicializa estado e posicao inicial do player.
PLAYER_SETUP:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la t0, PLAYER_STATE
    li t1, PLAYER_STATE_IDLE
    sw t1, 0(t0)

    la t0, PLAYER_DIRECTION
    sw zero, 0(t0)

    la t0, PLAYER_ANIMATION_FRAME
    sw zero, 0(t0)

    la t0, PLAYER_IS_MOVING
    sw zero, 0(t0)

    la t0, PLAYER_VEL_Y
    sw zero, 0(t0)

    la t0, PLAYER_IS_IN_AIR
    sw zero, 0(t0)

    la t0, PLAYER_IS_ON_LADDER
    sw zero, 0(t0)

    la a0, MAPA1_PLAYER
    la a1, PLAYER_POSITION
    call LOAD_ENTITY_POSITION

    la a0, MAPA1_PLAYER
    la a1, PLAYER_OLD_POSITION
    call LOAD_ENTITY_POSITION

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# PLAYER_UPDATE
# Atualiza flags e input do player.
PLAYER_UPDATE:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la t0, PLAYER_IS_MOVING
    sw zero, 0(t0)

    call PLAYER_READ_INPUT
    call PLAYER_APPLY_VERTICAL_PHYSICS

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# PLAYER_RENDER
# a3 = endereco base do framebuffer
PLAYER_RENDER:
    addi sp, sp, -8
    sw   ra, 0(sp)
    sw   a3, 4(sp)

    la t0, PLAYER_POSITION
    lh a0, 0(t0)
    lh a1, 2(t0)
    call WORLD_TO_SCREEN_POSITION

    mv t0, a0
    mv t1, a1
    la a0, megaman_direita
    mv a1, t0
    mv a2, t1
    lw a3, 4(sp)
    li a4, 0
    call RENDER_ENTITY

    lw   ra, 0(sp)
    addi sp, sp, 8
    ret

# PLAYER_READ_INPUT
# Le INPUT_CURRENT/INPUT_PRESSED e chama a acao do player.
PLAYER_READ_INPUT:

    la   t0, INPUT_CURRENT
    lw   t1, 0(t0)

    andi t2, t1, 0x03    # INPUT_LEFT | INPUT_RIGHT
    
    la  t0, INPUT_PRESSED
    lw  t4, 0(t0)

    andi t5, t4, INPUT_JUMP
    bnez t5, PLAYER_JUMP

_PLAYER_READ_INPUT_CONTINUE:

    li   t3, INPUT_LEFT
    ori  t3, t3, INPUT_RIGHT
    beq  t2, t3, _PLAYER_READ_INPUT_DONE

    li   t3, INPUT_LEFT
    beq  t2, t3, PLAYER_MOVE_LEFT

    li   t3, INPUT_RIGHT
    beq  t2, t3, PLAYER_MOVE_RIGHT

_PLAYER_READ_INPUT_DONE:
    ret

# PLAYER_JUMP
# Processa input de pulo pressionado neste frame.
PLAYER_JUMP:
    addi sp, sp, -4
    sw   ra, 0(sp)
    call PLAYER_START_JUMP
    lw   ra, 0(sp)
    addi sp, sp, 4
    j _PLAYER_READ_INPUT_CONTINUE

# PLAYER_START_JUMP
# Inicia pulo se o player nao estiver no ar.
PLAYER_START_JUMP:
    la t0, PLAYER_IS_IN_AIR
    lw t1, 0(t0)
    bnez t1, _PLAYER_START_JUMP_DONE

    li t1, 1
    sw t1, 0(t0)

    li t1, -8
    la t0, PLAYER_VEL_Y
    sw t1, 0(t0)

_PLAYER_START_JUMP_DONE:
    ret

# PLAYER_APPLY_VERTICAL_PHYSICS
# Aplica velocidade vertical, gravidade e limite inferior.
PLAYER_APPLY_VERTICAL_PHYSICS:
    la t0, PLAYER_POSITION
    lh t1, 2(t0)

    la t2, PLAYER_VEL_Y
    lw t3, 0(t2)
    add t1, t1, t3

    bltz t1, _PLAYER_APPLY_VERTICAL_PHYSICS_TOP
    j _PLAYER_APPLY_VERTICAL_PHYSICS_BOTTOM

_PLAYER_APPLY_VERTICAL_PHYSICS_TOP:
    li t1, PLAYER_Y_MIN
    sw zero, 0(t2)
    j _PLAYER_APPLY_VERTICAL_PHYSICS_SAVE

_PLAYER_APPLY_VERTICAL_PHYSICS_BOTTOM:
    li t4, PLAYER_Y_MAX
    ble t1, t4, _PLAYER_APPLY_VERTICAL_PHYSICS_GRAVITY

    mv t1, t4
    sw zero, 0(t2)
    la t5, PLAYER_IS_IN_AIR
    sw zero, 0(t5)
    j _PLAYER_APPLY_VERTICAL_PHYSICS_SAVE

_PLAYER_APPLY_VERTICAL_PHYSICS_GRAVITY:
    addi t3, t3, 1
    li t4, 6
    ble t3, t4, _PLAYER_APPLY_VERTICAL_PHYSICS_STORE_VEL
    mv t3, t4

_PLAYER_APPLY_VERTICAL_PHYSICS_STORE_VEL:
    sw t3, 0(t2)
    bnez t3, _PLAYER_APPLY_VERTICAL_PHYSICS_SET_AIR
    j _PLAYER_APPLY_VERTICAL_PHYSICS_SAVE

_PLAYER_APPLY_VERTICAL_PHYSICS_SET_AIR:
    la t5, PLAYER_IS_IN_AIR
    li t6, 1
    sw t6, 0(t5)

_PLAYER_APPLY_VERTICAL_PHYSICS_SAVE:
    sh t1, 2(t0)
    ret


# PLAYER_MOVE_RIGHT
# Move player para direita e atualiza direcao.
PLAYER_MOVE_RIGHT:
    addi sp, sp, -4
    sw   ra, 0(sp)

    li t1, 1
    la t0, PLAYER_IS_MOVING
    sw t1, 0(t0)

    li t1, 0
    la t0, PLAYER_DIRECTION
    sw t1, 0(t0)

    la t0, PLAYER_POSITION
    lhu t1, 0(t0)
    addi t1, t1, 4
    lhu t2, 2(t0)

    mv a0, t1
    mv a1, t2
    li a2, PLAYER_LARGURA
    li a3, PLAYER_ALTURA
    li a4, 1
    call PHYSICS_RESOLVE_HORIZONTAL_MAP_COLLISION

    la t0, PLAYER_POSITION
    sh a0, 0(t0)

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# PLAYER_MOVE_LEFT
# Move player para esquerda e atualiza direcao.
PLAYER_MOVE_LEFT:
    addi sp, sp, -4
    sw   ra, 0(sp)

    li t1, 1
    la t0, PLAYER_IS_MOVING
    sw t1, 0(t0)

    li t1, 1
    la t0, PLAYER_DIRECTION
    sw t1, 0(t0)

    la t0, PLAYER_POSITION
    lhu t1, 0(t0)
    addi t1, t1, -4
    lhu t2, 2(t0)

    mv a0, t1
    mv a1, t2
    li a2, PLAYER_LARGURA
    li a3, PLAYER_ALTURA
    li a4, -1
    call PHYSICS_RESOLVE_HORIZONTAL_MAP_COLLISION

    la t0, PLAYER_POSITION
    sh a0, 0(t0)

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
