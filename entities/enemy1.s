.data

# ===========================================================================
# ENEMY1 STATE
# ===========================================================================

.eqv ENEMY1_STATE_HIDED          0
.eqv ENEMY1_STATE_PATROLLING     1

# ===========================================================================
# ENEMY1 ATTRIBUTES
# ===========================================================================
# STATE
# POSITION X, Y
# VEL_X
#
# ===========================================================================


.eqv ENEMY1_X_OFF       0
.eqv ENEMY1_Y_OFF       2
.eqv ENEMY1_VEL_X_OFF   4
.eqv ENEMY1_STATE_OFF   8
.eqv ENEMY1_FRAME_OFF   12
.eqv ENEMY1_ALIVE_OFF   16
.eqv ENEMY1_SHOOT_TIMER_OFF 20
.eqv ENEMY1_SIZE        24

.eqv ENEMY1_HITBOX_OFFSET_X 2
.eqv ENEMY1_HITBOX_W    14
.eqv ENEMY1_HITBOX_H    20
.eqv ENEMY1_AGGRO_DISTANCE 80
.eqv ENEMY1_SPEED       1
.eqv ENEMY1_SHOT_SPEED  3
.eqv ENEMY1_SHOT_COOLDOWN 80
.eqv ENEMY1_SHOTS_MAX   12
.eqv ENEMY1_ANIM_SHIFT  4
.eqv ENEMY_DEAD_EFFECTS_MAX 8
.eqv ENEMY_DEAD_ANIM_SHIFT 1
.eqv ENEMY_DEAD_ANIM_DURATION 8


  ENEMY1_TABLE:
      # x, y, vel_x, state, frame, alive, shoot_timer
      .half 0, 0
      .word 0, 0, 0, 0, 0
      .half 0, 0
      .word 0, 0, 0, 0, 0

ENEMY1_SHOTS_ACTIVE: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ENEMY1_SHOTS_X:      .half 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ENEMY1_SHOTS_Y:      .half 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ENEMY1_SHOTS_VX:     .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ENEMY1_SHOTS_VY:     .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

ENEMY_DEAD_ACTIVE: .word 0, 0, 0, 0, 0, 0, 0, 0
ENEMY_DEAD_X:      .half 0, 0, 0, 0, 0, 0, 0, 0
ENEMY_DEAD_Y:      .half 0, 0, 0, 0, 0, 0, 0, 0
ENEMY_DEAD_TIMER:  .word 0, 0, 0, 0, 0, 0, 0, 0


.text

ENEMY1_SETUP:
    addi sp, sp, -20
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    sw   s3, 16(sp)

    li s0, MAPA1_INIMIGO1_COUNT
    li s1, 0
    la s2, ENEMY1_TABLE
    la s3, MAPA1_INIMIGO1


_ENEMY1_SETUP_LOOP:

    beq s1, s0, _ENEMY1_SETUP_LOOP_END

    mv a0, s3
    mv a1, s2
    call LOAD_ENTITY_POSITION

    sw zero, ENEMY1_VEL_X_OFF(s2)


    sw zero, ENEMY1_FRAME_OFF(s2)

    li t0, 1
    sw t0, ENEMY1_ALIVE_OFF(s2)

    sw zero, ENEMY1_SHOOT_TIMER_OFF(s2)

    addi s3, s3, MAPA1_ENTITY_POSITION_SIZE_BYTES
    addi s2, s2, ENEMY1_SIZE
    addi s1, s1, 1

    j _ENEMY1_SETUP_LOOP

_ENEMY1_SETUP_LOOP_END:

    lw   s3, 16(sp)
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 20
    ret


ENEMY1_UPDATE:
    addi sp, sp, -20
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    sw   s3, 16(sp)

    call ENEMY1_UPDATE_SHOTS
    call ENEMY_DEAD_UPDATE

    li s0, 0
    li s1, MAPA1_INIMIGO1_COUNT
    la s2, ENEMY1_TABLE

_ENEMY1_UPDATE_LOOP:
    beq s0, s1, _ENEMY1_UPDATE_DONE

    lw t0, ENEMY1_ALIVE_OFF(s2)
    beqz t0, _ENEMY1_UPDATE_NEXT

    mv a0, s2
    call ENEMY1_UPDATE_ONE

_ENEMY1_UPDATE_NEXT:
    addi s0, s0, 1
    addi s2, s2, ENEMY1_SIZE
    j _ENEMY1_UPDATE_LOOP

_ENEMY1_UPDATE_DONE:
    lw   s3, 16(sp)
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 20
    ret


# ENEMY1_UPDATE_ONE
# a0 = ponteiro para o enemy1 atual
ENEMY1_UPDATE_ONE:
    addi sp, sp, -16
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)

    mv s0, a0

    lh t0, ENEMY1_X_OFF(s0)
    la t1, PLAYER_POSITION
    lh t2, 0(t1)
    sub s1, t2, t0              # dx = player_x - enemy_x
    mv s2, s1
    bgez s2, _ENEMY1_UPDATE_ABS_OK
    sub s2, zero, s2
_ENEMY1_UPDATE_ABS_OK:
    li t3, ENEMY1_AGGRO_DISTANCE
    bgt s2, t3, _ENEMY1_UPDATE_HIDE

    lw t3, ENEMY1_STATE_OFF(s0)
    li t4, ENEMY1_STATE_HIDED
    bne t3, t4, _ENEMY1_UPDATE_PATROL

    li t3, ENEMY1_STATE_PATROLLING
    sw t3, ENEMY1_STATE_OFF(s0)

    li t3, ENEMY1_SPEED
    bgez s1, _ENEMY1_UPDATE_ENTER_RIGHT
    sub t3, zero, t3
_ENEMY1_UPDATE_ENTER_RIGHT:
    sw t3, ENEMY1_VEL_X_OFF(s0)

    mv a0, s0
    call ENEMY1_SHOOT_TRIPLE

    li t3, ENEMY1_SHOT_COOLDOWN
    sw t3, ENEMY1_SHOOT_TIMER_OFF(s0)

_ENEMY1_UPDATE_PATROL:
    lw t0, ENEMY1_SHOOT_TIMER_OFF(s0)
    beqz t0, _ENEMY1_UPDATE_PATROL_SHOOT
    addi t0, t0, -1
    sw t0, ENEMY1_SHOOT_TIMER_OFF(s0)
    j _ENEMY1_UPDATE_PATROL_MOVE

_ENEMY1_UPDATE_PATROL_SHOOT:
    mv a0, s0
    call ENEMY1_SHOOT_TRIPLE
    li t0, ENEMY1_SHOT_COOLDOWN
    sw t0, ENEMY1_SHOOT_TIMER_OFF(s0)

_ENEMY1_UPDATE_PATROL_MOVE:
    mv a0, s0
    call ENEMY1_MOVE_PATROL
    lw t0, ENEMY1_FRAME_OFF(s0)
    addi t0, t0, 1
    sw t0, ENEMY1_FRAME_OFF(s0)
    j _ENEMY1_UPDATE_ONE_DONE

_ENEMY1_UPDATE_HIDE:
    sw zero, ENEMY1_STATE_OFF(s0)
    sw zero, ENEMY1_FRAME_OFF(s0)

_ENEMY1_UPDATE_ONE_DONE:
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret


# ENEMY1_MOVE_PATROL
# a0 = ponteiro para enemy1 atual
ENEMY1_MOVE_PATROL:
    addi sp, sp, -16
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)

    mv s0, a0
    lh s1, ENEMY1_X_OFF(s0)
    lw t0, ENEMY1_VEL_X_OFF(s0)
    beqz t0, _ENEMY1_MOVE_PATROL_DONE

    add t1, s1, t0
    mv s2, t1
    sh t1, ENEMY1_X_OFF(s0)

    addi a0, t1, ENEMY1_HITBOX_OFFSET_X
    lh t2, ENEMY1_Y_OFF(s0)
    addi t2, t2, TILE_H
    li t3, ENEMY1_HITBOX_H
    sub a1, t2, t3
    li a2, ENEMY1_HITBOX_W
    li a3, ENEMY1_HITBOX_H
    mv a4, t0
    call PHYSICS_RESOLVE_HORIZONTAL_MAP_COLLISION

    li t2, ENEMY1_HITBOX_OFFSET_X
    sub t1, a0, t2
    sh t1, ENEMY1_X_OFF(s0)

    bne t1, s2, _ENEMY1_MOVE_PATROL_TURN
    j _ENEMY1_MOVE_PATROL_DONE

_ENEMY1_MOVE_PATROL_TURN:
    lw t0, ENEMY1_VEL_X_OFF(s0)
    sub t0, zero, t0
    sw t0, ENEMY1_VEL_X_OFF(s0)

_ENEMY1_MOVE_PATROL_DONE:
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret


# ENEMY1_SHOOT_TRIPLE
# a0 = ponteiro para enemy1 atual
ENEMY1_SHOOT_TRIPLE:
    addi sp, sp, -20
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    sw   s3, 16(sp)

    mv s0, a0
    lh s1, ENEMY1_X_OFF(s0)
    lh s2, ENEMY1_Y_OFF(s0)

    lw t0, ENEMY1_VEL_X_OFF(s0)
    li s3, ENEMY1_SHOT_SPEED
    bgez t0, _ENEMY1_SHOOT_RIGHT
    sub s3, zero, s3
_ENEMY1_SHOOT_RIGHT:
    addi s1, s1, ENEMY1_HITBOX_OFFSET_X
    addi s2, s2, -8

    mv a0, s1
    mv a1, s2
    mv a2, s3
    li a3, 0
    call ENEMY1_SPAWN_SHOT

    mv a0, s1
    mv a1, s2
    mv a2, s3
    li a3, ENEMY1_SHOT_SPEED
    sub a3, zero, a3
    call ENEMY1_SPAWN_SHOT

    mv a0, s1
    mv a1, s2
    mv a2, s3
    li a3, ENEMY1_SHOT_SPEED
    call ENEMY1_SPAWN_SHOT

    lw   s3, 16(sp)
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 20
    ret


# ENEMY1_SPAWN_SHOT
# a0 = x, a1 = y, a2 = vx, a3 = vy
ENEMY1_SPAWN_SHOT:
    la t0, ENEMY1_SHOTS_ACTIVE
    la t1, ENEMY1_SHOTS_X
    la t2, ENEMY1_SHOTS_Y
    la t3, ENEMY1_SHOTS_VX
    la t4, ENEMY1_SHOTS_VY
    li t5, 0

_ENEMY1_SPAWN_SHOT_LOOP:
    lw t6, 0(t0)
    beqz t6, _ENEMY1_SPAWN_SHOT_FOUND

    addi t0, t0, 4
    addi t1, t1, 2
    addi t2, t2, 2
    addi t3, t3, 4
    addi t4, t4, 4
    addi t5, t5, 1
    li t6, ENEMY1_SHOTS_MAX
    blt t5, t6, _ENEMY1_SPAWN_SHOT_LOOP
    ret

_ENEMY1_SPAWN_SHOT_FOUND:
    li t6, 1
    sw t6, 0(t0)
    sh a0, 0(t1)
    sh a1, 0(t2)
    sw a2, 0(t3)
    sw a3, 0(t4)
    ret


ENEMY1_UPDATE_SHOTS:
    la t0, ENEMY1_SHOTS_ACTIVE
    la t1, ENEMY1_SHOTS_X
    la t2, ENEMY1_SHOTS_Y
    la t3, ENEMY1_SHOTS_VX
    la t4, ENEMY1_SHOTS_VY
    li t5, 0

_ENEMY1_UPDATE_SHOTS_LOOP:
    lw t6, 0(t0)
    beqz t6, _ENEMY1_UPDATE_SHOTS_NEXT

    lh a0, 0(t1)
    lw a2, 0(t3)
    add a0, a0, a2
    sh a0, 0(t1)

    lh a1, 0(t2)
    lw a3, 0(t4)
    add a1, a1, a3
    sh a1, 0(t2)

    la a2, BG_POS
    lh a3, 0(a2)
    sub a3, a0, a3
    li t6, PLAYER_SHOT_W
    sub t6, zero, t6
    blt a3, t6, _ENEMY1_UPDATE_SHOTS_DEACTIVATE
    li t6, SCREEN_W
    bge a3, t6, _ENEMY1_UPDATE_SHOTS_DEACTIVATE

    lh a3, 2(a2)
    sub a3, a1, a3
    li t6, PLAYER_SHOT_H
    sub t6, zero, t6
    blt a3, t6, _ENEMY1_UPDATE_SHOTS_DEACTIVATE
    li t6, SCREEN_H
    bge a3, t6, _ENEMY1_UPDATE_SHOTS_DEACTIVATE
    j _ENEMY1_UPDATE_SHOTS_NEXT

_ENEMY1_UPDATE_SHOTS_DEACTIVATE:
    sw zero, 0(t0)

_ENEMY1_UPDATE_SHOTS_NEXT:
    addi t0, t0, 4
    addi t1, t1, 2
    addi t2, t2, 2
    addi t3, t3, 4
    addi t4, t4, 4
    addi t5, t5, 1
    li t6, ENEMY1_SHOTS_MAX
    blt t5, t6, _ENEMY1_UPDATE_SHOTS_LOOP
    ret


# ENEMY1_HANDLE_SHOT_COLLISION
# a0 = x do tiro no mundo
# a1 = y do tiro no mundo
# retorna a0 = 0 sem colisao; 1 rebateu em enemy1 escondido; 2 matou enemy1 patrulhando
ENEMY1_HANDLE_SHOT_COLLISION:
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
    li s5, MAPA1_INIMIGO1_COUNT
    la t0, ENEMY1_TABLE

_ENEMY1_HANDLE_SHOT_COLLISION_LOOP:
    beq s4, s5, _ENEMY1_HANDLE_SHOT_COLLISION_FALSE

    lw t1, ENEMY1_ALIVE_OFF(t0)
    beqz t1, _ENEMY1_HANDLE_SHOT_COLLISION_NEXT

    lh t1, ENEMY1_X_OFF(t0)
    addi t1, t1, ENEMY1_HITBOX_OFFSET_X
    li t3, ENEMY1_HITBOX_W
    add t4, t1, t3              # enemy right

    bge s0, t4, _ENEMY1_HANDLE_SHOT_COLLISION_NEXT
    bge t1, s2, _ENEMY1_HANDLE_SHOT_COLLISION_NEXT

    lh t1, ENEMY1_Y_OFF(t0)
    li t3, ENEMY1_HITBOX_H
    addi t4, t1, TILE_H
    sub t4, t4, t3              # enemy top
    add t5, t4, t3              # enemy bottom

    bge s1, t5, _ENEMY1_HANDLE_SHOT_COLLISION_NEXT
    bge t4, s3, _ENEMY1_HANDLE_SHOT_COLLISION_NEXT

    lw t1, ENEMY1_STATE_OFF(t0)
    li t2, ENEMY1_STATE_HIDED
    beq t1, t2, _ENEMY1_HANDLE_SHOT_COLLISION_BOUNCE

    li t2, ENEMY1_STATE_PATROLLING
    bne t1, t2, _ENEMY1_HANDLE_SHOT_COLLISION_NEXT

    sw zero, ENEMY1_ALIVE_OFF(t0)
    sw zero, ENEMY1_VEL_X_OFF(t0)
    lh a0, ENEMY1_X_OFF(t0)
    lh a1, ENEMY1_Y_OFF(t0)
    call ENEMY_DEAD_SPAWN
    li a0, 2
    j _ENEMY1_HANDLE_SHOT_COLLISION_DONE

_ENEMY1_HANDLE_SHOT_COLLISION_BOUNCE:
    li a0, 1
    j _ENEMY1_HANDLE_SHOT_COLLISION_DONE

_ENEMY1_HANDLE_SHOT_COLLISION_NEXT:
    addi t0, t0, ENEMY1_SIZE
    addi s4, s4, 1
    j _ENEMY1_HANDLE_SHOT_COLLISION_LOOP

_ENEMY1_HANDLE_SHOT_COLLISION_FALSE:
    li a0, 0

_ENEMY1_HANDLE_SHOT_COLLISION_DONE:
    lw   s5, 24(sp)
    lw   s4, 20(sp)
    lw   s3, 16(sp)
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 28
    ret


# ENEMY_DEAD_SPAWN
# a0 = x no mundo, a1 = y da entidade no mundo
ENEMY_DEAD_SPAWN:
    la t0, ENEMY_DEAD_ACTIVE
    la t1, ENEMY_DEAD_X
    la t2, ENEMY_DEAD_Y
    la t3, ENEMY_DEAD_TIMER
    li t4, 0

_ENEMY_DEAD_SPAWN_LOOP:
    lw t5, 0(t0)
    beqz t5, _ENEMY_DEAD_SPAWN_FOUND
    addi t0, t0, 4
    addi t1, t1, 2
    addi t2, t2, 2
    addi t3, t3, 4
    addi t4, t4, 1
    li t5, ENEMY_DEAD_EFFECTS_MAX
    blt t4, t5, _ENEMY_DEAD_SPAWN_LOOP
    ret

_ENEMY_DEAD_SPAWN_FOUND:
    li t5, 1
    sw t5, 0(t0)
    sh a0, 0(t1)
    sh a1, 0(t2)
    sw zero, 0(t3)
    ret


ENEMY_DEAD_UPDATE:
    la t0, ENEMY_DEAD_ACTIVE
    la t1, ENEMY_DEAD_TIMER
    li t2, 0

_ENEMY_DEAD_UPDATE_LOOP:
    lw t3, 0(t0)
    beqz t3, _ENEMY_DEAD_UPDATE_NEXT

    lw t3, 0(t1)
    addi t3, t3, 1
    li t4, ENEMY_DEAD_ANIM_DURATION
    bge t3, t4, _ENEMY_DEAD_UPDATE_DEACTIVATE
    sw t3, 0(t1)
    j _ENEMY_DEAD_UPDATE_NEXT

_ENEMY_DEAD_UPDATE_DEACTIVATE:
    sw zero, 0(t0)

_ENEMY_DEAD_UPDATE_NEXT:
    addi t0, t0, 4
    addi t1, t1, 4
    addi t2, t2, 1
    li t3, ENEMY_DEAD_EFFECTS_MAX
    blt t2, t3, _ENEMY_DEAD_UPDATE_LOOP
    ret


# ENEMY_DEAD_RENDER
# a3 = endereco base do framebuffer
ENEMY_DEAD_RENDER:
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
    la s1, ENEMY_DEAD_ACTIVE
    la s2, ENEMY_DEAD_X
    la s3, ENEMY_DEAD_Y
    la s4, ENEMY_DEAD_TIMER

_ENEMY_DEAD_RENDER_LOOP:
    lw t0, 0(s1)
    beqz t0, _ENEMY_DEAD_RENDER_NEXT

    lh a0, 0(s2)
    lh a1, 0(s3)
    call WORLD_TO_SCREEN_POSITION

    lw t0, 0(s4)
    srli t0, t0, ENEMY_DEAD_ANIM_SHIFT
    li t1, 1
    beq t0, t1, _ENEMY_DEAD_RENDER_FRAME_2
    li t1, 2
    beq t0, t1, _ENEMY_DEAD_RENDER_FRAME_3
    li t1, 3
    beq t0, t1, _ENEMY_DEAD_RENDER_FRAME_4
    la t2, ENEMY_DEAD_FRAME_1
    j _ENEMY_DEAD_RENDER_FRAME_READY
_ENEMY_DEAD_RENDER_FRAME_2:
    la t2, ENEMY_DEAD_FRAME_2
    j _ENEMY_DEAD_RENDER_FRAME_READY
_ENEMY_DEAD_RENDER_FRAME_3:
    la t2, ENEMY_DEAD_FRAME_3
    j _ENEMY_DEAD_RENDER_FRAME_READY
_ENEMY_DEAD_RENDER_FRAME_4:
    la t2, ENEMY_DEAD_FRAME_4

_ENEMY_DEAD_RENDER_FRAME_READY:
    mv a2, a1
    mv a1, a0
    mv a0, t2
    mv a3, s5
    li a4, 0
    call RENDER_ENTITY

_ENEMY_DEAD_RENDER_NEXT:
    addi s0, s0, 1
    addi s1, s1, 4
    addi s2, s2, 2
    addi s3, s3, 2
    addi s4, s4, 4
    li t0, ENEMY_DEAD_EFFECTS_MAX
    blt s0, t0, _ENEMY_DEAD_RENDER_LOOP

    lw   s5, 24(sp)
    lw   s4, 20(sp)
    lw   s3, 16(sp)
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 28
    ret

ENEMY1_RENDER:
    addi sp, sp, -20
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    sw   a3, 16(sp)

    li s0, 0
    li s1, MAPA1_INIMIGO1_COUNT
    la s2, ENEMY1_TABLE

_ENEMY1_RENDER_LOOP:

    beq s0, s1, _ENEMY1_RENDER_LOOP_END

    lw t0, ENEMY1_ALIVE_OFF(s2)
    beqz t0, _ENEMY1_RENDER_NEXT

    lh a0, ENEMY1_X_OFF(s2)
    lh a1, ENEMY1_Y_OFF(s2)
    call WORLD_TO_SCREEN_POSITION

    mv a2, a1
    mv a1, a0
    lw t0, ENEMY1_STATE_OFF(s2)
    li t1, ENEMY1_STATE_PATROLLING
    beq t0, t1, _ENEMY1_RENDER_PATROLLING_SPRITE

    lw t0, ENEMY1_FRAME_OFF(s2)
    srli t0, t0, ENEMY1_ANIM_SHIFT
    andi t0, t0, 1
    bnez t0, _ENEMY1_RENDER_HIDING_2
    la a0, ENEMY1_SPRITE_HIDING_1
    j _ENEMY1_RENDER_SPRITE_READY
_ENEMY1_RENDER_HIDING_2:
    la a0, ENEMY1_SPRITE_HIDING_2
    j _ENEMY1_RENDER_SPRITE_READY

_ENEMY1_RENDER_PATROLLING_SPRITE:
    lw t0, ENEMY1_FRAME_OFF(s2)
    srli t0, t0, ENEMY1_ANIM_SHIFT
    andi t0, t0, 1
    bnez t0, _ENEMY1_RENDER_WALKING_2
    la a0, ENEMY1_SPRITE_WALKING_1
    j _ENEMY1_RENDER_SPRITE_READY
_ENEMY1_RENDER_WALKING_2:
    la a0, ENEMY1_SPRITE_WALKING_2

_ENEMY1_RENDER_SPRITE_READY:
    li a4, 1
    lw t0, ENEMY1_VEL_X_OFF(s2)
    bgez t0, _ENEMY1_RENDER_NO_FLIP
    li a4, 0
_ENEMY1_RENDER_NO_FLIP:
    call RENDER_ENTITY

_ENEMY1_RENDER_NEXT:
    addi s0, s0, 1
    addi s2, s2, ENEMY1_SIZE
    j _ENEMY1_RENDER_LOOP

_ENEMY1_RENDER_LOOP_END:
    lw a3, 16(sp)
    call ENEMY1_RENDER_SHOTS
    lw a3, 16(sp)
    call ENEMY_DEAD_RENDER

    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 20
    ret


# ENEMY1_RENDER_SHOTS
# a3 = endereco base do framebuffer
ENEMY1_RENDER_SHOTS:
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
    la s1, ENEMY1_SHOTS_ACTIVE
    la s2, ENEMY1_SHOTS_X
    la s3, ENEMY1_SHOTS_Y
    li s4, ENEMY1_SHOTS_MAX

_ENEMY1_RENDER_SHOTS_LOOP:
    lw t0, 0(s1)
    beqz t0, _ENEMY1_RENDER_SHOTS_NEXT

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

_ENEMY1_RENDER_SHOTS_NEXT:
    addi s0, s0, 1
    addi s1, s1, 4
    addi s2, s2, 2
    addi s3, s3, 2
    blt s0, s4, _ENEMY1_RENDER_SHOTS_LOOP

    lw   s5, 24(sp)
    lw   s4, 20(sp)
    lw   s3, 16(sp)
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 28
    ret
