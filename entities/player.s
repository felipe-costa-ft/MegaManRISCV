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
PLAYER_SHOOT_TIMER:  .word 0
PLAYER_SHOTS_ACTIVE: .word 0, 0, 0
PLAYER_SHOTS_DIRECTION: .word 0, 0, 0
PLAYER_SHOTS_X:      .half 0, 0, 0
PLAYER_SHOTS_Y:      .half 0, 0, 0

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

    la t0, PLAYER_SHOOT_TIMER
    sw zero, 0(t0)

    la t0, PLAYER_SHOTS_ACTIVE
    sw zero, 0(t0)
    sw zero, 4(t0)
    sw zero, 8(t0)

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
# Atualiza input, fisica e estado do player.
PLAYER_UPDATE:
    addi sp, sp, -4
    sw   ra, 0(sp)

    call PLAYER_SAVE_OLD_POSITION

    la t0, PLAYER_IS_MOVING
    sw zero, 0(t0)

    call PLAYER_READ_INPUT
    call PLAYER_APPLY_VERTICAL_PHYSICS
    call PLAYER_UPDATE_SHOTS
    call PLAYER_UPDATE_STATE
    call PLAYER_UPDATE_ANIMATION

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# PLAYER_SAVE_OLD_POSITION
# Copia PLAYER_POSITION para PLAYER_OLD_POSITION.
PLAYER_SAVE_OLD_POSITION:
    la t0, PLAYER_POSITION
    la t1, PLAYER_OLD_POSITION
    lh t2, 0(t0)
    sh t2, 0(t1)
    lh t2, 2(t0)
    sh t2, 2(t1)
    ret

# PLAYER_RENDER
# a3 = endereco base do framebuffer
PLAYER_RENDER:
    addi sp, sp, -20
    sw   ra, 0(sp)
    sw   a3, 4(sp)

    la t0, PLAYER_POSITION
    lh a0, 0(t0)
    lh a1, 2(t0)
    call WORLD_TO_SCREEN_POSITION

    sw a0, 8(sp)
    sw a1, 12(sp)

    call PLAYER_GET_CURRENT_SPRITE
    sw a0, 16(sp)
    call PLAYER_GET_RENDER_FLAGS

    mv a4, a0
    lw a0, 16(sp)
    lw a1, 8(sp)
    lw a2, 12(sp)
    lw a3, 4(sp)
    call RENDER_ENTITY

    lw a3, 4(sp)
    call PLAYER_RENDER_SHOTS

    lw   ra, 0(sp)
    addi sp, sp, 20
    ret

# PLAYER_READ_INPUT
# Le INPUT_CURRENT/INPUT_PRESSED e chama a acao do player.
PLAYER_READ_INPUT:

    la   t0, INPUT_CURRENT
    lw   t1, 0(t0)

    andi t2, t1, 0x03    # INPUT_LEFT | INPUT_RIGHT
    
    la  t0, INPUT_PRESSED
    lw  t4, 0(t0)

    andi t5, t4, INPUT_SHOOT
    bnez t5, PLAYER_SHOOT

_PLAYER_READ_INPUT_CHECK_JUMP:
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

# PLAYER_SHOOT
# Processa input de tiro pressionado neste frame.
PLAYER_SHOOT:
    addi sp, sp, -8
    sw   ra, 0(sp)
    sw   t4, 4(sp)
    call PLAYER_START_SHOOT
    lw   t4, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 8
    j _PLAYER_READ_INPUT_CHECK_JUMP

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

# PLAYER_START_SHOOT
# Cria um projetil no primeiro slot livre; maximo de PLAYER_SHOTS_MAX ativos.
PLAYER_START_SHOOT:
    la t0, PLAYER_SHOTS_ACTIVE
    la t1, PLAYER_SHOTS_X
    la t2, PLAYER_SHOTS_Y
    la t3, PLAYER_SHOTS_DIRECTION
    li t4, 0
    li t5, PLAYER_SHOTS_MAX

_PLAYER_START_SHOOT_FIND_SLOT:
    lw t6, 0(t0)
    beqz t6, _PLAYER_START_SHOOT_FOUND_SLOT
    addi t0, t0, 4
    addi t1, t1, 2
    addi t2, t2, 2
    addi t3, t3, 4
    addi t4, t4, 1
    blt t4, t5, _PLAYER_START_SHOOT_FIND_SLOT
    ret

_PLAYER_START_SHOOT_FOUND_SLOT:
    li t6, 1
    sw t6, 0(t0)

    la t4, PLAYER_DIRECTION
    lw t5, 0(t4)
    sw t5, 0(t3)

    la t4, PLAYER_POSITION
    lh t6, 0(t4)
    beqz t5, _PLAYER_START_SHOOT_RIGHT

    li t5, PLAYER_SHOT_W
    sub t6, t6, t5
    j _PLAYER_START_SHOOT_SAVE_X

_PLAYER_START_SHOOT_RIGHT:
    addi t6, t6, PLAYER_LARGURA

_PLAYER_START_SHOOT_SAVE_X:
    sh t6, 0(t1)

    lh t6, 2(t4)
    sh t6, 0(t2)

    la t0, PLAYER_SHOOT_TIMER
    li t1, PLAYER_SHOOT_DURATION
    sw t1, 0(t0)
    ret

# PLAYER_UPDATE_SHOTS
# Atualiza timer de tiro e move/desativa projeteis ativos.
PLAYER_UPDATE_SHOTS:
    addi sp, sp, -28
    sw   ra, 0(sp)
    sw   s1, 4(sp)
    sw   s2, 8(sp)
    sw   s3, 12(sp)
    sw   s4, 16(sp)
    sw   s5, 20(sp)
    sw   s6, 24(sp)

    la t0, PLAYER_SHOOT_TIMER
    lw t1, 0(t0)
    beqz t1, _PLAYER_UPDATE_SHOTS_LOOP_SETUP
    addi t1, t1, -1
    sw t1, 0(t0)

_PLAYER_UPDATE_SHOTS_LOOP_SETUP:
    li s1, 0
    la s2, PLAYER_SHOTS_ACTIVE
    la s3, PLAYER_SHOTS_X
    la s4, PLAYER_SHOTS_Y
    la s5, PLAYER_SHOTS_DIRECTION
    li s6, PLAYER_SHOTS_MAX

_PLAYER_UPDATE_SHOTS_LOOP:
    lw t0, 0(s2)
    beqz t0, _PLAYER_UPDATE_SHOTS_NEXT

    lh t1, 0(s3)
    lh t2, 0(s4)
    lw t3, 0(s5)
    beqz t3, _PLAYER_UPDATE_SHOTS_RIGHT

    li t4, PLAYER_SHOT_SPEED
    sub t1, t1, t4
    j _PLAYER_UPDATE_SHOTS_SAVE_X

_PLAYER_UPDATE_SHOTS_RIGHT:
    addi t1, t1, PLAYER_SHOT_SPEED

_PLAYER_UPDATE_SHOTS_SAVE_X:
    sh t1, 0(s3)

    la t4, BG_POS
    lh t5, 0(t4)
    sub t5, t1, t5

    bltz t5, _PLAYER_UPDATE_SHOTS_DEACTIVATE

    li t4, SCREEN_W
    bge t5, t4, _PLAYER_UPDATE_SHOTS_DEACTIVATE

    la t4, BG_POS
    lh t5, 2(t4)
    sub t5, t2, t5

    li t4, PLAYER_SHOT_H
    sub t4, zero, t4
    blt t5, t4, _PLAYER_UPDATE_SHOTS_DEACTIVATE

    li t4, SCREEN_H
    blt t5, t4, _PLAYER_UPDATE_SHOTS_NEXT

_PLAYER_UPDATE_SHOTS_DEACTIVATE:
    sw zero, 0(s2)

_PLAYER_UPDATE_SHOTS_NEXT:
    addi s1, s1, 1
    addi s2, s2, 4
    addi s3, s3, 2
    addi s4, s4, 2
    addi s5, s5, 4
    blt s1, s6, _PLAYER_UPDATE_SHOTS_LOOP

    lw   s6, 24(sp)
    lw   s5, 20(sp)
    lw   s4, 16(sp)
    lw   s3, 12(sp)
    lw   s2, 8(sp)
    lw   s1, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 28
    ret

# PLAYER_SET_STATE
# a0 = novo estado do player.
PLAYER_SET_STATE:
    la t0, PLAYER_STATE
    lw t1, 0(t0)
    beq t1, a0, _PLAYER_SET_STATE_DONE

    sw a0, 0(t0)

    li t2, PLAYER_STATE_ATIRANDO
    bne a0, t2, _PLAYER_SET_STATE_CHECK_LEAVING_RUN_SHOOT
    li t2, PLAYER_STATE_ANDANDO
    beq t1, t2, _PLAYER_SET_STATE_DONE

_PLAYER_SET_STATE_CHECK_LEAVING_RUN_SHOOT:
    li t2, PLAYER_STATE_ANDANDO
    bne a0, t2, _PLAYER_SET_STATE_RESET_ANIMATION
    li t2, PLAYER_STATE_ATIRANDO
    beq t1, t2, _PLAYER_SET_STATE_DONE

_PLAYER_SET_STATE_RESET_ANIMATION:
    la t0, PLAYER_ANIMATION_FRAME
    sw zero, 0(t0)

_PLAYER_SET_STATE_DONE:
    ret

# PLAYER_UPDATE_STATE
# Define estado usando flags finais do frame.
PLAYER_UPDATE_STATE:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la t0, PLAYER_STATE
    lw t1, 0(t0)
    li t2, PLAYER_STATE_KNOCKBACK
    beq t1, t2, _PLAYER_UPDATE_STATE_DONE

    la t0, PLAYER_IS_ON_LADDER
    lw t1, 0(t0)
    bnez t1, _PLAYER_UPDATE_STATE_LADDER

    la t0, PLAYER_IS_IN_AIR
    lw t1, 0(t0)
    bnez t1, _PLAYER_UPDATE_STATE_AIR

    la t0, PLAYER_SHOOT_TIMER
    lw t1, 0(t0)
    bnez t1, _PLAYER_UPDATE_STATE_SHOOTING

    call PLAYER_HAS_ACTIVE_SHOT
    bnez a0, _PLAYER_UPDATE_STATE_SHOOTING

    la t0, PLAYER_IS_MOVING
    lw t1, 0(t0)
    bnez t1, _PLAYER_UPDATE_STATE_MOVING

    li a0, PLAYER_STATE_IDLE
    call PLAYER_SET_STATE
    j _PLAYER_UPDATE_STATE_DONE

_PLAYER_UPDATE_STATE_LADDER:
    li a0, PLAYER_STATE_NA_ESCADA
    call PLAYER_SET_STATE
    j _PLAYER_UPDATE_STATE_DONE

_PLAYER_UPDATE_STATE_AIR:
    la t0, PLAYER_SHOOT_TIMER
    lw t1, 0(t0)
    bnez t1, _PLAYER_UPDATE_STATE_AIR_SHOOTING

    call PLAYER_HAS_ACTIVE_SHOT
    bnez a0, _PLAYER_UPDATE_STATE_AIR_SHOOTING

    li a0, PLAYER_STATE_NO_AR
    call PLAYER_SET_STATE
    j _PLAYER_UPDATE_STATE_DONE

_PLAYER_UPDATE_STATE_SHOOTING:
    li a0, PLAYER_STATE_ATIRANDO
    call PLAYER_SET_STATE
    j _PLAYER_UPDATE_STATE_DONE

_PLAYER_UPDATE_STATE_AIR_SHOOTING:
    li a0, PLAYER_STATE_ATIRA_PULANDO
    call PLAYER_SET_STATE
    j _PLAYER_UPDATE_STATE_DONE

_PLAYER_UPDATE_STATE_MOVING:
    li a0, PLAYER_STATE_ANDANDO
    call PLAYER_SET_STATE

_PLAYER_UPDATE_STATE_DONE:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# PLAYER_HAS_ACTIVE_SHOT
# Retorna a0 = 1 se existe algum projetil do player ativo.
PLAYER_HAS_ACTIVE_SHOT:
    la t0, PLAYER_SHOTS_ACTIVE
    li t1, 0
    li t2, PLAYER_SHOTS_MAX

_PLAYER_HAS_ACTIVE_SHOT_LOOP:
    lw t3, 0(t0)
    bnez t3, _PLAYER_HAS_ACTIVE_SHOT_TRUE
    addi t0, t0, 4
    addi t1, t1, 1
    blt t1, t2, _PLAYER_HAS_ACTIVE_SHOT_LOOP

    li a0, 0
    ret

_PLAYER_HAS_ACTIVE_SHOT_TRUE:
    li a0, 1
    ret

# PLAYER_UPDATE_ANIMATION
# Atualiza contador de animacao do player.
PLAYER_UPDATE_ANIMATION:
    la a0, PLAYER_ANIMATION_FRAME
    j ANIMATION_UPDATE

# PLAYER_GET_CURRENT_SPRITE
# retorna a0 = sprite base atual do player.
PLAYER_GET_CURRENT_SPRITE:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la t0, PLAYER_STATE
    lw t1, 0(t0)

    li t2, PLAYER_STATE_NA_ESCADA
    beq t1, t2, _PLAYER_GET_CURRENT_SPRITE_LADDER

    li t2, PLAYER_STATE_NO_AR
    beq t1, t2, _PLAYER_GET_CURRENT_SPRITE_JUMP

    li t2, PLAYER_STATE_ATIRA_PULANDO
    beq t1, t2, _PLAYER_GET_CURRENT_SPRITE_SHOOT_JUMP

    li t2, PLAYER_STATE_ATIRANDO
    beq t1, t2, _PLAYER_GET_CURRENT_SPRITE_SHOOTING

    li t2, PLAYER_STATE_ANDANDO
    beq t1, t2, _PLAYER_GET_CURRENT_SPRITE_RUNNING

    j _PLAYER_GET_CURRENT_SPRITE_IDLE

_PLAYER_GET_CURRENT_SPRITE_IDLE:
    la t0, PLAYER_ANIMATION_FRAME
    lw t2, 0(t0)
    li t3, 96
    rem t2, t2, t3

    li t3, 4
    blt t2, t3, _PLAYER_GET_CURRENT_SPRITE_IDLE_BLINK
    la a0, PLAYER_SPRITE_IDLE
    j _PLAYER_GET_CURRENT_SPRITE_DONE

_PLAYER_GET_CURRENT_SPRITE_IDLE_BLINK:
    la a0, PLAYER_SPRITE_IDLE_BLINK
    j _PLAYER_GET_CURRENT_SPRITE_DONE

_PLAYER_GET_CURRENT_SPRITE_RUNNING:
    la t0, PLAYER_ANIMATION_FRAME
    lw a0, 0(t0)
    li a1, 2
    li a2, 3
    call ANIMATION_GET_FRAME_INDEX

    li t2, 1
    beq a0, t2, _PLAYER_GET_CURRENT_SPRITE_RUN_RIGHT_2
    li t2, 2
    beq a0, t2, _PLAYER_GET_CURRENT_SPRITE_RUN_RIGHT_3
    la a0, PLAYER_SPRITE_RUN_1
    j _PLAYER_GET_CURRENT_SPRITE_DONE

_PLAYER_GET_CURRENT_SPRITE_RUN_RIGHT_2:
    la a0, PLAYER_SPRITE_RUN_2
    j _PLAYER_GET_CURRENT_SPRITE_DONE

_PLAYER_GET_CURRENT_SPRITE_RUN_RIGHT_3:
    la a0, PLAYER_SPRITE_RUN_3
    j _PLAYER_GET_CURRENT_SPRITE_DONE

_PLAYER_GET_CURRENT_SPRITE_JUMP:
    la a0, PLAYER_SPRITE_JUMP
    j _PLAYER_GET_CURRENT_SPRITE_DONE

_PLAYER_GET_CURRENT_SPRITE_SHOOT_JUMP:
    la a0, PLAYER_SPRITE_SHOOT_JUMP
    j _PLAYER_GET_CURRENT_SPRITE_DONE

_PLAYER_GET_CURRENT_SPRITE_SHOOTING:
    la t0, PLAYER_IS_MOVING
    lw t1, 0(t0)
    bnez t1, _PLAYER_GET_CURRENT_SPRITE_SHOOT_RUNNING

    la a0, PLAYER_SPRITE_SHOOT
    j _PLAYER_GET_CURRENT_SPRITE_DONE

_PLAYER_GET_CURRENT_SPRITE_SHOOT_RUNNING:
    la t0, PLAYER_ANIMATION_FRAME
    lw a0, 0(t0)
    li a1, 2
    li a2, 3
    call ANIMATION_GET_FRAME_INDEX

    li t2, 1
    beq a0, t2, _PLAYER_GET_CURRENT_SPRITE_SHOOT_RUN_2
    li t2, 2
    beq a0, t2, _PLAYER_GET_CURRENT_SPRITE_SHOOT_RUN_1
    la a0, PLAYER_SPRITE_SHOOT_RUN_3
    j _PLAYER_GET_CURRENT_SPRITE_DONE

_PLAYER_GET_CURRENT_SPRITE_SHOOT_RUN_1:
    la a0, PLAYER_SPRITE_SHOOT_RUN_1
    j _PLAYER_GET_CURRENT_SPRITE_DONE

_PLAYER_GET_CURRENT_SPRITE_SHOOT_RUN_2:
    la a0, PLAYER_SPRITE_SHOOT_RUN_2
    j _PLAYER_GET_CURRENT_SPRITE_DONE

_PLAYER_GET_CURRENT_SPRITE_LADDER:
    la t0, PLAYER_IS_MOVING
    lw t1, 0(t0)
    beqz t1, _PLAYER_GET_CURRENT_SPRITE_LADDER_1

    la t0, PLAYER_ANIMATION_FRAME
    lw t2, 0(t0)
    srli t2, t2, 3
    andi t2, t2, 1
    bnez t2, _PLAYER_GET_CURRENT_SPRITE_LADDER_2

_PLAYER_GET_CURRENT_SPRITE_LADDER_1:
    la a0, PLAYER_SPRITE_LADDER_1
    j _PLAYER_GET_CURRENT_SPRITE_DONE

_PLAYER_GET_CURRENT_SPRITE_LADDER_2:
    la a0, PLAYER_SPRITE_LADDER_2
    j _PLAYER_GET_CURRENT_SPRITE_DONE

_PLAYER_GET_CURRENT_SPRITE_RIGHT:
    la a0, PLAYER_SPRITE_IDLE

_PLAYER_GET_CURRENT_SPRITE_DONE:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# PLAYER_RENDER_SHOTS
# a3 = endereco base do framebuffer; renderiza ate 3 projeteis ativos.
PLAYER_RENDER_SHOTS:
    addi sp, sp, -32
    sw   ra, 0(sp)
    sw   s1, 4(sp)
    sw   s2, 8(sp)
    sw   s3, 12(sp)
    sw   s4, 16(sp)
    sw   s5, 20(sp)
    sw   s6, 24(sp)
    sw   s7, 28(sp)

    mv s7, a3
    li s1, 0
    la s2, PLAYER_SHOTS_ACTIVE
    la s3, PLAYER_SHOTS_X
    la s4, PLAYER_SHOTS_Y
    li s5, PLAYER_SHOTS_MAX

_PLAYER_RENDER_SHOTS_LOOP:
    lw t0, 0(s2)
    beqz t0, _PLAYER_RENDER_SHOTS_NEXT

    lh a0, 0(s3)
    lh a1, 0(s4)
    call WORLD_TO_SCREEN_POSITION

    mv s6, a0
    mv t1, a1

    bltz s6, _PLAYER_RENDER_SHOTS_NEXT
    li t2, SCREEN_W
    li t3, PLAYER_SHOT_W
    sub t2, t2, t3
    bge s6, t2, _PLAYER_RENDER_SHOTS_NEXT

    li t2, PLAYER_SHOT_H
    sub t2, zero, t2
    blt t1, t2, _PLAYER_RENDER_SHOTS_NEXT
    li t2, SCREEN_H
    li t3, PLAYER_SHOT_H
    sub t2, t2, t3
    bge t1, t2, _PLAYER_RENDER_SHOTS_NEXT

    la a0, PLAYER_SPRITE_SHOOT_PROJECTILE
    mv a1, s6
    mv a2, t1
    mv a3, s7
    li a4, 0
    call PRINT

_PLAYER_RENDER_SHOTS_NEXT:
    addi s1, s1, 1
    addi s2, s2, 4
    addi s3, s3, 2
    addi s4, s4, 2
    blt s1, s5, _PLAYER_RENDER_SHOTS_LOOP

    lw   s7, 28(sp)
    lw   s6, 24(sp)
    lw   s5, 20(sp)
    lw   s4, 16(sp)
    lw   s3, 12(sp)
    lw   s2, 8(sp)
    lw   s1, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 32
    ret

# PLAYER_GET_RENDER_FLAGS
# retorna a0 = 1 se deve espelhar horizontalmente.
PLAYER_GET_RENDER_FLAGS:
    la t0, PLAYER_DIRECTION
    lw t1, 0(t0)
    snez a0, t1
    ret

# PLAYER_APPLY_VERTICAL_PHYSICS
# Aplica velocidade vertical e colisao vertical no mapa.
PLAYER_APPLY_VERTICAL_PHYSICS:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la t0, PLAYER_POSITION
    lh a0, 0(t0)
    lh a1, 2(t0)
    addi a0, a0, PLAYER_HITBOX_OFFSET_X

    la t2, PLAYER_VEL_Y
    lw a4, 0(t2)

    li t3, TILE_H
    add a1, a1, t3
    li t3, PLAYER_ALTURA
    sub a1, a1, t3
    add a1, a1, a4

    li a2, PLAYER_HITBOX_LARGURA
    li a3, PLAYER_ALTURA
    call PHYSICS_RESOLVE_VERTICAL_MAP_COLLISION

    la t0, PLAYER_VEL_Y
    sw a1, 0(t0)

    la t0, PLAYER_IS_IN_AIR
    sw a2, 0(t0)

    li t1, PLAYER_ALTURA
    add t1, a0, t1
    li t2, TILE_H
    sub t1, t1, t2

    la t0, PLAYER_POSITION
    sh t1, 2(t0)

    lw   ra, 0(sp)
    addi sp, sp, 4
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
    addi t1, t1, PLAYER_HITBOX_OFFSET_X
    lhu t2, 2(t0)
    li t3, TILE_H
    add t2, t2, t3
    li t3, PLAYER_ALTURA
    sub t2, t2, t3

    mv a0, t1
    mv a1, t2
    li a2, PLAYER_HITBOX_LARGURA
    li a3, PLAYER_ALTURA
    li a4, 1
    call PHYSICS_RESOLVE_HORIZONTAL_MAP_COLLISION

    li t1, PLAYER_HITBOX_OFFSET_X
    sub a0, a0, t1
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
    addi t1, t1, PLAYER_HITBOX_OFFSET_X
    lhu t2, 2(t0)
    li t3, TILE_H
    add t2, t2, t3
    li t3, PLAYER_ALTURA
    sub t2, t2, t3

    mv a0, t1
    mv a1, t2
    li a2, PLAYER_HITBOX_LARGURA
    li a3, PLAYER_ALTURA
    li a4, -1
    call PHYSICS_RESOLVE_HORIZONTAL_MAP_COLLISION

    li t1, PLAYER_HITBOX_OFFSET_X
    sub a0, a0, t1
    la t0, PLAYER_POSITION
    sh a0, 0(t0)

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
