.data

# ===========================================================================
# ENEMY2 STATE
# ===========================================================================

.eqv ENEMY2_STATE_HIDED          0
.eqv ENEMY2_STATE_PATROLLING     1

# ===========================================================================
# ENEMY2 ATTRIBUTES
# ===========================================================================
# STATE
# POSITION X, Y
# VEL_X
#
# ===========================================================================


.eqv ENEMY2_X_OFF       0
.eqv ENEMY2_Y_OFF       2
.eqv ENEMY2_VEL_X_OFF   4
.eqv ENEMY2_STATE_OFF   8
.eqv ENEMY2_FRAME_OFF   12
.eqv ENEMY2_ALIVE_OFF   16
.eqv ENEMY2_SHOOT_TIMER_OFF 20
.eqv ENEMY2_SIZE        24

.eqv ENEMY2_HITBOX_OFFSET_X 8
.eqv ENEMY2_HITBOX_W    16
.eqv ENEMY2_HITBOX_H    24
.eqv ENEMY2_AGGRO_DISTANCE 80
.eqv ENEMY2_SPEED       1
.eqv ENEMY2_SHOT_SPEED  3
.eqv ENEMY2_SHOT_COOLDOWN 80
.eqv ENEMY2_SHOTS_MAX   12
.eqv ENEMY2_ANIM_SHIFT  4


  ENEMY2_TABLE:
      # x, y, vel_x, state, frame, alive, shoot_timer
      .half 0, 0
      .word 0, 0, 0, 0, 0
      .half 0, 0
      .word 0, 0, 0, 0, 0
      .half 0, 0
      .word 0, 0, 0, 0, 0
      .half 0, 0
      .word 0, 0, 0, 0, 0
      .half 0, 0
      .word 0, 0, 0, 0, 0
  

ENEMY2_SHOTS_ACTIVE: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ENEMY2_SHOTS_X:      .half 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ENEMY2_SHOTS_Y:      .half 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ENEMY2_SHOTS_VX:     .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ENEMY2_SHOTS_VY:     .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.text

ENEMY2_SETUP:
    addi sp, sp, -20
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    sw   s3, 16(sp)

    la t0, CURRENT_MAP_INIMIGO2_COUNT
    lw s0, 0(t0)
    li s1, 0
    la s2, ENEMY2_TABLE
    la t0, CURRENT_MAP_INIMIGO2
    lw s3, 0(t0)


_ENEMY2_SETUP_LOOP:

    beq s1, s0, _ENEMY2_SETUP_LOOP_END

    mv a0, s3
    mv a1, s2
    call LOAD_ENTITY_POSITION

    sw zero, ENEMY2_VEL_X_OFF(s2)

    sw zero, ENEMY2_STATE_OFF(s2)
    sw zero, ENEMY2_FRAME_OFF(s2)

    li t0, 1
    sw t0, ENEMY2_ALIVE_OFF(s2)

    sw zero, ENEMY2_SHOOT_TIMER_OFF(s2)

    addi s3, s3, MAPA_ENTITY_POSITION_SIZE_BYTES
    addi s2, s2, ENEMY2_SIZE
    addi s1, s1, 1

    j _ENEMY2_SETUP_LOOP

_ENEMY2_SETUP_LOOP_END:
    call ENEMY2_CLEAR_TRANSIENT

    lw   s3, 16(sp)
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 20
    ret

ENEMY2_CLEAR_TRANSIENT:
    la t0, ENEMY2_SHOTS_ACTIVE
    li t1, 0
    li t2, ENEMY2_SHOTS_MAX

_ENEMY2_CLEAR_SHOTS_LOOP:
    beq t1, t2, _ENEMY2_CLEAR_TRANSIENT_DONE
    sw zero, 0(t0)
    addi t0, t0, 4
    addi t1, t1, 1
    j _ENEMY2_CLEAR_SHOTS_LOOP

_ENEMY2_CLEAR_TRANSIENT_DONE:
    ret


ENEMY2_UPDATE:
    addi sp, sp, -20
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    sw   s3, 16(sp)

    li s0, 0
    la t0, CURRENT_MAP_INIMIGO2_COUNT
    lw s1, 0(t0)
    la s2, ENEMY2_TABLE

_ENEMY2_UPDATE_LOOP:
    beq s0, s1, _ENEMY2_UPDATE_DONE

    lw t0, ENEMY2_ALIVE_OFF(s2)
    beqz t0, _ENEMY2_UPDATE_NEXT

    mv a0, s2
    call ENEMY2_UPDATE_ONE

_ENEMY2_UPDATE_NEXT:
    addi s0, s0, 1
    addi s2, s2, ENEMY2_SIZE
    j _ENEMY2_UPDATE_LOOP

_ENEMY2_UPDATE_DONE:
    lw   s3, 16(sp)
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 20
    ret


# ENEMY2_UPDATE_ONE
# a0 = ponteiro para o enemy2 atual
ENEMY2_UPDATE_ONE:
    addi sp, sp, -16
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)

    mv s0, a0

    lh t0, ENEMY2_X_OFF(s0)
    la t1, PLAYER_POSITION
    lh t2, 0(t1)
    sub s1, t2, t0              # dx = player_x - enemy_x
    mv s2, s1
    bgez s2, _ENEMY2_UPDATE_ABS_OK
    sub s2, zero, s2
_ENEMY2_UPDATE_ABS_OK:
    li t3, ENEMY2_AGGRO_DISTANCE
    bgt s2, t3, _ENEMY2_UPDATE_HIDE

    lw t3, ENEMY2_STATE_OFF(s0)
    li t4, ENEMY2_STATE_HIDED
    bne t3, t4, _ENEMY2_UPDATE_PATROL

    li t3, ENEMY2_STATE_PATROLLING
    sw t3, ENEMY2_STATE_OFF(s0)

    sw zero, ENEMY2_VEL_X_OFF(s0)

_ENEMY2_UPDATE_PATROL:
    mv a0, s0
    call ENEMY2_CHASE_PLAYER

    lw t0, ENEMY2_FRAME_OFF(s0)
    addi t0, t0, 1
    sw t0, ENEMY2_FRAME_OFF(s0)
    j _ENEMY2_UPDATE_ONE_DONE

_ENEMY2_UPDATE_HIDE:
    sw zero, ENEMY2_STATE_OFF(s0)
    sw zero, ENEMY2_FRAME_OFF(s0)

_ENEMY2_UPDATE_ONE_DONE:
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret


# ENEMY2_CHASE_PLAYER
# a0 = ponteiro para enemy2 atual
ENEMY2_CHASE_PLAYER:
    addi sp, sp, -8
    sw   ra, 0(sp)
    sw   s0, 4(sp)

    mv s0, a0

    la t0, PLAYER_POSITION
    lh t1, 0(t0)                  # player x
    lh t2, ENEMY2_X_OFF(s0)       # enemy x
    beq t1, t2, _ENEMY2_CHASE_X_STOP
    blt t1, t2, _ENEMY2_CHASE_X_LEFT

_ENEMY2_CHASE_X_RIGHT:
    li t3, ENEMY2_SPEED
    sw t3, ENEMY2_VEL_X_OFF(s0)
    add t2, t2, t3
    sh t2, ENEMY2_X_OFF(s0)
    j _ENEMY2_CHASE_Y

_ENEMY2_CHASE_X_LEFT:
    li t3, ENEMY2_SPEED
    sub t3, zero, t3
    sw t3, ENEMY2_VEL_X_OFF(s0)
    add t2, t2, t3
    sh t2, ENEMY2_X_OFF(s0)
    j _ENEMY2_CHASE_Y

_ENEMY2_CHASE_X_STOP:
    sw zero, ENEMY2_VEL_X_OFF(s0)

_ENEMY2_CHASE_Y:
    la t0, PLAYER_POSITION
    lh t1, 2(t0)                  # player y
    lh t2, ENEMY2_Y_OFF(s0)       # enemy y
    beq t1, t2, _ENEMY2_CHASE_DONE
    blt t1, t2, _ENEMY2_CHASE_Y_UP

_ENEMY2_CHASE_Y_DOWN:
    addi t2, t2, ENEMY2_SPEED
    j _ENEMY2_CHASE_Y_CLAMP

_ENEMY2_CHASE_Y_UP:
    addi t2, t2, -1
    bltz t2, _ENEMY2_CHASE_Y_MIN
    j _ENEMY2_CHASE_Y_CLAMP

_ENEMY2_CHASE_Y_MIN:
    li t2, 0

_ENEMY2_CHASE_Y_CLAMP:
    li t3, MAPA_MAP_ROWS
    li t4, TILE_H
    mul t3, t3, t4
    addi t3, t3, -24
    ble t2, t3, _ENEMY2_CHASE_Y_SAVE
    mv t2, t3

_ENEMY2_CHASE_Y_SAVE:
    sh t2, ENEMY2_Y_OFF(s0)

_ENEMY2_CHASE_DONE:
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 8
    ret


# ENEMY2_SHOOT_TRIPLE
# a0 = ponteiro para enemy2 atual
ENEMY2_SHOOT_TRIPLE:
    addi sp, sp, -20
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    sw   s3, 16(sp)

    mv s0, a0
    lh s1, ENEMY2_X_OFF(s0)
    lh s2, ENEMY2_Y_OFF(s0)

    lw t0, ENEMY2_VEL_X_OFF(s0)
    li s3, ENEMY2_SHOT_SPEED
    bgez t0, _ENEMY2_SHOOT_RIGHT
    sub s3, zero, s3
_ENEMY2_SHOOT_RIGHT:
    addi s1, s1, ENEMY2_HITBOX_OFFSET_X
    addi s2, s2, -8

    mv a0, s1
    mv a1, s2
    mv a2, s3
    li a3, 0
    call ENEMY2_SPAWN_SHOT

    mv a0, s1
    mv a1, s2
    mv a2, s3
    li a3, ENEMY2_SHOT_SPEED
    sub a3, zero, a3
    call ENEMY2_SPAWN_SHOT

    mv a0, s1
    mv a1, s2
    mv a2, s3
    li a3, ENEMY2_SHOT_SPEED
    call ENEMY2_SPAWN_SHOT

    lw   s3, 16(sp)
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 20
    ret


# ENEMY2_SPAWN_SHOT
# a0 = x, a1 = y, a2 = vx, a3 = vy
ENEMY2_SPAWN_SHOT:
    la t0, ENEMY2_SHOTS_ACTIVE
    la t1, ENEMY2_SHOTS_X
    la t2, ENEMY2_SHOTS_Y
    la t3, ENEMY2_SHOTS_VX
    la t4, ENEMY2_SHOTS_VY
    li t5, 0

_ENEMY2_SPAWN_SHOT_LOOP:
    lw t6, 0(t0)
    beqz t6, _ENEMY2_SPAWN_SHOT_FOUND

    addi t0, t0, 4
    addi t1, t1, 2
    addi t2, t2, 2
    addi t3, t3, 4
    addi t4, t4, 4
    addi t5, t5, 1
    li t6, ENEMY2_SHOTS_MAX
    blt t5, t6, _ENEMY2_SPAWN_SHOT_LOOP
    ret

_ENEMY2_SPAWN_SHOT_FOUND:
    li t6, 1
    sw t6, 0(t0)
    sh a0, 0(t1)
    sh a1, 0(t2)
    sw a2, 0(t3)
    sw a3, 0(t4)
    ret


# ENEMY2_UPDATE_SHOTS
# Move os tiros ativos, verifica colisao com o player (aplica dano) e
# desativa por colisao ou saida de tela.
ENEMY2_UPDATE_SHOTS:
    addi sp, sp, -32
    sw   ra, 0(sp)
    sw   s1, 4(sp)
    sw   s2, 8(sp)
    sw   s3, 12(sp)
    sw   s4, 16(sp)
    sw   s5, 20(sp)
    sw   s6, 24(sp)
    sw   s7, 28(sp)

    li s1, 0
    la s2, ENEMY2_SHOTS_ACTIVE
    la s3, ENEMY2_SHOTS_X
    la s4, ENEMY2_SHOTS_Y
    la s5, ENEMY2_SHOTS_VX
    la s6, ENEMY2_SHOTS_VY
    li s7, ENEMY2_SHOTS_MAX

_ENEMY2_UPDATE_SHOTS_LOOP:
    lw t6, 0(s2)
    beqz t6, _ENEMY2_UPDATE_SHOTS_NEXT

    lh a0, 0(s3)
    lw a2, 0(s5)
    add a0, a0, a2
    sh a0, 0(s3)

    lh a1, 0(s4)
    lw a3, 0(s6)
    add a1, a1, a3
    sh a1, 0(s4)

    call PLAYER_HANDLE_ENEMY_SHOT_COLLISION
    bnez a0, _ENEMY2_UPDATE_SHOTS_DEACTIVATE

    lh a0, 0(s3)
    lh a1, 0(s4)

    la a2, BG_POS
    lh a3, 0(a2)
    sub a3, a0, a3
    li t6, PLAYER_SHOT_W
    sub t6, zero, t6
    blt a3, t6, _ENEMY2_UPDATE_SHOTS_DEACTIVATE
    li t6, SCREEN_W
    bge a3, t6, _ENEMY2_UPDATE_SHOTS_DEACTIVATE

    lh a3, 2(a2)
    sub a3, a1, a3
    li t6, PLAYER_SHOT_H
    sub t6, zero, t6
    blt a3, t6, _ENEMY2_UPDATE_SHOTS_DEACTIVATE
    li t6, SCREEN_H
    bge a3, t6, _ENEMY2_UPDATE_SHOTS_DEACTIVATE
    j _ENEMY2_UPDATE_SHOTS_NEXT

_ENEMY2_UPDATE_SHOTS_DEACTIVATE:
    sw zero, 0(s2)

_ENEMY2_UPDATE_SHOTS_NEXT:
    addi s1, s1, 1
    addi s2, s2, 4
    addi s3, s3, 2
    addi s4, s4, 2
    addi s5, s5, 4
    addi s6, s6, 4
    blt s1, s7, _ENEMY2_UPDATE_SHOTS_LOOP

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


# ENEMY2_HANDLE_SHOT_COLLISION
# a0 = x do tiro no mundo
# a1 = y do tiro no mundo
# retorna a0 = 0 sem colisao; 1 rebateu em enemy2 escondido; 2 matou enemy2 patrulhando
ENEMY2_HANDLE_SHOT_COLLISION:
    addi sp, sp, -28
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    sw   s3, 16(sp)
    sw   s4, 20(sp)
    sw   s5, 24(sp)

    mv s0, a0
    mv s1, a1
    addi s2, s0, PLAYER_SHOT_W
    addi s3, s1, PLAYER_SHOT_H

    li s4, 0
    la t0, CURRENT_MAP_INIMIGO2_COUNT
    lw s5, 0(t0)
    la t0, ENEMY2_TABLE

_ENEMY2_HANDLE_SHOT_COLLISION_LOOP:
    beq s4, s5, _ENEMY2_HANDLE_SHOT_COLLISION_FALSE

    lw t1, ENEMY2_ALIVE_OFF(t0)
    beqz t1, _ENEMY2_HANDLE_SHOT_COLLISION_NEXT

    lh t1, ENEMY2_X_OFF(t0)
    addi t1, t1, ENEMY2_HITBOX_OFFSET_X
    li t3, ENEMY2_HITBOX_W
    add t4, t1, t3              # enemy right

    bge s0, t4, _ENEMY2_HANDLE_SHOT_COLLISION_NEXT
    bge t1, s2, _ENEMY2_HANDLE_SHOT_COLLISION_NEXT

    lh t4, ENEMY2_Y_OFF(t0)     # enemy top
    li t3, ENEMY2_HITBOX_H
    add t5, t4, t3              # enemy bottom

    bge s1, t5, _ENEMY2_HANDLE_SHOT_COLLISION_NEXT
    bge t4, s3, _ENEMY2_HANDLE_SHOT_COLLISION_NEXT

    lw t1, ENEMY2_STATE_OFF(t0)
    li t2, ENEMY2_STATE_HIDED
    beq t1, t2, _ENEMY2_HANDLE_SHOT_COLLISION_BOUNCE

    li t2, ENEMY2_STATE_PATROLLING
    bne t1, t2, _ENEMY2_HANDLE_SHOT_COLLISION_NEXT

    sw zero, ENEMY2_ALIVE_OFF(t0)
    sw zero, ENEMY2_VEL_X_OFF(t0)
    lh s0, ENEMY2_X_OFF(t0)
    lh s1, ENEMY2_Y_OFF(t0)
    mv a0, s0
    mv a1, s1
    call ENEMY_DEAD_SPAWN
    mv a0, s0
    mv a1, s1
    call ITEMS_TRY_SPAWN
    li a0, 2
    j _ENEMY2_HANDLE_SHOT_COLLISION_DONE

_ENEMY2_HANDLE_SHOT_COLLISION_BOUNCE:
    li a0, 1
    j _ENEMY2_HANDLE_SHOT_COLLISION_DONE

_ENEMY2_HANDLE_SHOT_COLLISION_NEXT:
    addi t0, t0, ENEMY2_SIZE
    addi s4, s4, 1
    j _ENEMY2_HANDLE_SHOT_COLLISION_LOOP

_ENEMY2_HANDLE_SHOT_COLLISION_FALSE:
    li a0, 0

_ENEMY2_HANDLE_SHOT_COLLISION_DONE:
    lw   s5, 24(sp)
    lw   s4, 20(sp)
    lw   s3, 16(sp)
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 28
    ret


# ENEMY2_CHECK_PLAYER_COLLISION
# Retorna a0 = 1 se o player encostou em um enemy2 vivo, a1 = x do enemy.
ENEMY2_CHECK_PLAYER_COLLISION:
    la t0, PLAYER_POSITION
    lh t1, 0(t0)
    addi t1, t1, PLAYER_HITBOX_OFFSET_X
    li t2, PLAYER_HITBOX_LARGURA
    add t2, t1, t2

    lh t3, 2(t0)
    addi t3, t3, TILE_H
    li t4, PLAYER_ALTURA
    sub t3, t3, t4
    add t4, t3, t4

    li a3, 0
    la a2, CURRENT_MAP_INIMIGO2_COUNT
    lw a4, 0(a2)
    la a2, ENEMY2_TABLE

_ENEMY2_CHECK_PLAYER_COLLISION_LOOP:
    beq a3, a4, _ENEMY2_CHECK_PLAYER_COLLISION_FALSE

    lw a5, ENEMY2_ALIVE_OFF(a2)
    beqz a5, _ENEMY2_CHECK_PLAYER_COLLISION_NEXT

    lh a5, ENEMY2_X_OFF(a2)
    addi a5, a5, ENEMY2_HITBOX_OFFSET_X
    li a6, ENEMY2_HITBOX_W
    add a6, a5, a6

    bge t1, a6, _ENEMY2_CHECK_PLAYER_COLLISION_NEXT
    bge a5, t2, _ENEMY2_CHECK_PLAYER_COLLISION_NEXT

    lh a5, ENEMY2_Y_OFF(a2)
    li a6, ENEMY2_HITBOX_H
    add a6, a5, a6

    bge t3, a6, _ENEMY2_CHECK_PLAYER_COLLISION_NEXT
    bge a5, t4, _ENEMY2_CHECK_PLAYER_COLLISION_NEXT

    li a0, 1
    lh a1, ENEMY2_X_OFF(a2)
    ret

_ENEMY2_CHECK_PLAYER_COLLISION_NEXT:
    addi a3, a3, 1
    addi a2, a2, ENEMY2_SIZE
    j _ENEMY2_CHECK_PLAYER_COLLISION_LOOP

_ENEMY2_CHECK_PLAYER_COLLISION_FALSE:
    li a0, 0
    ret


ENEMY2_RENDER:
    addi sp, sp, -20
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    sw   a3, 16(sp)

    li s0, 0
    la t0, CURRENT_MAP_INIMIGO2_COUNT
    lw s1, 0(t0)
    la s2, ENEMY2_TABLE

_ENEMY2_RENDER_LOOP:

    beq s0, s1, _ENEMY2_RENDER_LOOP_END

    lw t0, ENEMY2_ALIVE_OFF(s2)
    beqz t0, _ENEMY2_RENDER_NEXT

    lh a0, ENEMY2_X_OFF(s2)
    lh a1, ENEMY2_Y_OFF(s2)
    call WORLD_TO_SCREEN_POSITION

    mv a2, a1
    mv a1, a0
    lw t0, ENEMY2_STATE_OFF(s2)
    li t1, ENEMY2_STATE_PATROLLING
    beq t0, t1, _ENEMY2_RENDER_PATROLLING_SPRITE

    lw t0, ENEMY2_FRAME_OFF(s2)
    srli t0, t0, ENEMY2_ANIM_SHIFT
    andi t0, t0, 1
    bnez t0, _ENEMY2_RENDER_HIDING_2
    la a0, ENEMY2_BAT_HIDING_1
    j _ENEMY2_RENDER_SPRITE_READY
_ENEMY2_RENDER_HIDING_2:
    la a0, ENEMY2_BAT_HIDING_2
    j _ENEMY2_RENDER_SPRITE_READY

_ENEMY2_RENDER_PATROLLING_SPRITE:
    lw t0, ENEMY2_FRAME_OFF(s2)
    srli t0, t0, ENEMY2_ANIM_SHIFT
    andi t0, t0, 3
    li t1, 1
    beq t0, t1, _ENEMY2_RENDER_FLYING_2
    li t1, 2
    beq t0, t1, _ENEMY2_RENDER_FLYING_3
    li t1, 3
    beq t0, t1, _ENEMY2_RENDER_FLYING_4
    la a0, ENEMY2_BAT_FLYING_2
    j _ENEMY2_RENDER_SPRITE_READY
_ENEMY2_RENDER_FLYING_2:
    la a0, ENEMY2_BAT_FLYING_3
    j _ENEMY2_RENDER_SPRITE_READY
_ENEMY2_RENDER_FLYING_3:
    la a0, ENEMY2_BAT_FLYING_6
    j _ENEMY2_RENDER_SPRITE_READY
_ENEMY2_RENDER_FLYING_4:
    la a0, ENEMY2_BAT_FLYING_CLOSING

_ENEMY2_RENDER_SPRITE_READY:
    li a4, 1
    lw t0, ENEMY2_VEL_X_OFF(s2)
    bgez t0, _ENEMY2_RENDER_NO_FLIP
    li a4, 0
_ENEMY2_RENDER_NO_FLIP:
    call RENDER_ENTITY

_ENEMY2_RENDER_NEXT:
    addi s0, s0, 1
    addi s2, s2, ENEMY2_SIZE
    j _ENEMY2_RENDER_LOOP

_ENEMY2_RENDER_LOOP_END:
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 20
    ret


# ENEMY2_RENDER_SHOTS
# a3 = endereco base do framebuffer
ENEMY2_RENDER_SHOTS:
    addi sp, sp, -28
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    sw   s3, 16(sp)
    sw   s4, 20(sp)
    sw   s5, 24(sp)

    mv s5, a3
    li s0, 0
    la s1, ENEMY2_SHOTS_ACTIVE
    la s2, ENEMY2_SHOTS_X
    la s3, ENEMY2_SHOTS_Y
    li s4, ENEMY2_SHOTS_MAX

_ENEMY2_RENDER_SHOTS_LOOP:
    lw t0, 0(s1)
    beqz t0, _ENEMY2_RENDER_SHOTS_NEXT

    lh a0, 0(s2)
    lh a1, 0(s3)
    call WORLD_TO_SCREEN_POSITION

    mv t1, a0
    mv t2, a1
    la a0, PLAYER_SPRITE_SHOOT_PROJECTILE
    mv a1, t1
    mv a2, t2
    mv a3, s5
    li a4, 0
    call PRINT_CLIPPED

_ENEMY2_RENDER_SHOTS_NEXT:
    addi s0, s0, 1
    addi s1, s1, 4
    addi s2, s2, 2
    addi s3, s3, 2
    blt s0, s4, _ENEMY2_RENDER_SHOTS_LOOP

    lw   s5, 24(sp)
    lw   s4, 20(sp)
    lw   s3, 16(sp)
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 28
    ret
