.data

# ===========================================================================
# BOSS STATE
# ===========================================================================

.eqv BOSS_STATE_INACTIVE 0
.eqv BOSS_STATE_INTRO    1
.eqv BOSS_STATE_IDLE     2
.eqv BOSS_STATE_THROW    3
.eqv BOSS_STATE_DASH     4
.eqv BOSS_STATE_JUMP     5
.eqv BOSS_STATE_DEAD     6

# ===========================================================================
# BOSS ATTRIBUTES
# ===========================================================================

.eqv BOSS_X_OFF             0
.eqv BOSS_Y_OFF             2
.eqv BOSS_VEL_X_OFF         4
.eqv BOSS_VEL_Y_OFF         8
.eqv BOSS_STATE_OFF         12
.eqv BOSS_FRAME_OFF         16
.eqv BOSS_HP_OFF            20
.eqv BOSS_ALIVE_OFF         24
.eqv BOSS_ACTION_TIMER_OFF  28
.eqv BOSS_DIRECTION_OFF     32
.eqv BOSS_SIZE              36

.eqv BOSS_HITBOX_OFFSET_X   6
.eqv BOSS_HITBOX_OFFSET_Y  -16
.eqv BOSS_HITBOX_W          20
.eqv BOSS_HITBOX_H          32
.eqv BOSS_INTRO_TIME        60
.eqv BOSS_TRIGGER_DISTANCE_X 112
.eqv BOSS_TRIGGER_DISTANCE_Y 64
.eqv BOSS_IDLE_TIME         48
.eqv BOSS_THROW_TIME        48
.eqv BOSS_DASH_TIME         22
.eqv BOSS_DASH_SPEED        3
.eqv BOSS_JUMP_TIME         72
.eqv BOSS_JUMP_SPEED        1
.eqv BOSS_JUMP_VEL         -7
.eqv BOSS_SHOTS_MAX         12
.eqv BOSS_SHOT_SPEED        3
.eqv BOSS_SHOT_W            8
.eqv BOSS_SHOT_H            8
.eqv BOSS_ANIM_SHIFT        3

BOSS_TABLE:
    .half 0, 0
    .word 0, 0, 0, 0, 0, 0, 0, 0

BOSS_SHOTS_ACTIVE: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
BOSS_SHOTS_X:      .half 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
BOSS_SHOTS_Y:      .half 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
BOSS_SHOTS_VX:     .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
BOSS_SHOTS_VY:     .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

BOSS_NEXT_ACTION:    .word 0
BOSS_RESTART_TIMER:  .word 0

.text

BOSS_SETUP:
    addi sp, sp, -4
    sw   ra, 0(sp)

    call BOSS_CLEAR_SHOTS

    la t0, BOSS_RESTART_TIMER
    sw zero, 0(t0)
    la t0, BOSS_NEXT_ACTION
    sw zero, 0(t0)

    la t0, CURRENT_MAP_BOSS_COUNT
    lw t1, 0(t0)
    beqz t1, _BOSS_SETUP_DISABLED

    la t0, CURRENT_MAP_BOSS
    lw a0, 0(t0)
    la a1, BOSS_TABLE
    call LOAD_ENTITY_POSITION

    la t0, BOSS_TABLE
    sw zero, BOSS_VEL_X_OFF(t0)
    sw zero, BOSS_VEL_Y_OFF(t0)
    li t1, BOSS_STATE_INACTIVE
    sw t1, BOSS_STATE_OFF(t0)
    sw zero, BOSS_FRAME_OFF(t0)
    li t1, BOSS_HP_MAX
    sw t1, BOSS_HP_OFF(t0)
    li t1, 1
    sw t1, BOSS_ALIVE_OFF(t0)
    sw zero, BOSS_ACTION_TIMER_OFF(t0)
    sw zero, BOSS_DIRECTION_OFF(t0)
    j _BOSS_SETUP_DONE

_BOSS_SETUP_DISABLED:
    la t0, BOSS_TABLE
    sw zero, BOSS_ALIVE_OFF(t0)
    li t1, BOSS_STATE_DEAD
    sw t1, BOSS_STATE_OFF(t0)

_BOSS_SETUP_DONE:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

BOSS_CLEAR_SHOTS:
    la t0, BOSS_SHOTS_ACTIVE
    li t1, 0
_BOSS_CLEAR_SHOTS_LOOP:
    li t2, BOSS_SHOTS_MAX
    beq t1, t2, _BOSS_CLEAR_SHOTS_DONE
    sw zero, 0(t0)
    addi t0, t0, 4
    addi t1, t1, 1
    j _BOSS_CLEAR_SHOTS_LOOP
_BOSS_CLEAR_SHOTS_DONE:
    ret

# BOSS_CHECK_RESTART
# retorna a0 = 1 quando termina a espera apos a morte do boss.
BOSS_CHECK_RESTART:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la t0, BOSS_RESTART_TIMER
    lw t1, 0(t0)
    beqz t1, _BOSS_CHECK_RESTART_FALSE

    addi t1, t1, -1
    sw t1, 0(t0)
    bnez t1, _BOSS_CHECK_RESTART_FALSE

    li a0, 1
    j _BOSS_CHECK_RESTART_DONE

_BOSS_CHECK_RESTART_FALSE:
    li a0, 0

_BOSS_CHECK_RESTART_DONE:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

BOSS_UPDATE:
    addi sp, sp, -8
    sw   ra, 0(sp)
    sw   s0, 4(sp)

    call BOSS_UPDATE_SHOTS

    la t0, CURRENT_MAP_BOSS_COUNT
    lw t1, 0(t0)
    beqz t1, _BOSS_UPDATE_DONE

    la s0, BOSS_TABLE
    lw t0, BOSS_ALIVE_OFF(s0)
    beqz t0, _BOSS_UPDATE_DONE

    lw t0, BOSS_STATE_OFF(s0)
    li t1, BOSS_STATE_INACTIVE
    bne t0, t1, _BOSS_UPDATE_ACTIVE

    call BOSS_IS_PLAYER_NEAR
    beqz a0, _BOSS_UPDATE_DONE
    li a0, BOSS_STATE_INTRO
    li a1, BOSS_INTRO_TIME
    call BOSS_SET_STATE
    j _BOSS_UPDATE_DONE

_BOSS_UPDATE_ACTIVE:
    call BOSS_FACE_PLAYER

    lw t0, BOSS_FRAME_OFF(s0)
    addi t0, t0, 1
    sw t0, BOSS_FRAME_OFF(s0)

    lw t0, BOSS_STATE_OFF(s0)
    li t1, BOSS_STATE_INTRO
    beq t0, t1, _BOSS_UPDATE_INTRO
    li t1, BOSS_STATE_IDLE
    beq t0, t1, _BOSS_UPDATE_IDLE
    li t1, BOSS_STATE_THROW
    beq t0, t1, _BOSS_UPDATE_THROW
    li t1, BOSS_STATE_DASH
    beq t0, t1, _BOSS_UPDATE_DASH
    li t1, BOSS_STATE_JUMP
    beq t0, t1, _BOSS_UPDATE_JUMP
    j _BOSS_UPDATE_DONE

_BOSS_UPDATE_INTRO:
    call BOSS_TICK_ACTION_TIMER
    bnez a0, _BOSS_UPDATE_DONE
    li a0, BOSS_STATE_IDLE
    li a1, BOSS_IDLE_TIME
    call BOSS_SET_STATE
    j _BOSS_UPDATE_DONE

_BOSS_UPDATE_IDLE:
    call BOSS_TICK_ACTION_TIMER
    bnez a0, _BOSS_UPDATE_DONE
    call BOSS_START_NEXT_ACTION
    j _BOSS_UPDATE_DONE

_BOSS_UPDATE_THROW:
    lw t0, BOSS_ACTION_TIMER_OFF(s0)
    li t1, 36
    beq t0, t1, _BOSS_UPDATE_THROW_SHOOT
    li t1, 24
    beq t0, t1, _BOSS_UPDATE_THROW_SHOOT
    li t1, 12
    bne t0, t1, _BOSS_UPDATE_THROW_TICK
_BOSS_UPDATE_THROW_SHOOT:
    call BOSS_SHOOT_TRIPLE
_BOSS_UPDATE_THROW_TICK:
    call BOSS_TICK_ACTION_TIMER
    bnez a0, _BOSS_UPDATE_DONE
    li a0, BOSS_STATE_IDLE
    li a1, BOSS_IDLE_TIME
    call BOSS_SET_STATE
    j _BOSS_UPDATE_DONE

_BOSS_UPDATE_DASH:
    call BOSS_MOVE_DASH
    call BOSS_TICK_ACTION_TIMER
    bnez a0, _BOSS_UPDATE_DONE
    sw zero, BOSS_VEL_X_OFF(s0)
    li a0, BOSS_STATE_IDLE
    li a1, BOSS_IDLE_TIME
    call BOSS_SET_STATE
    j _BOSS_UPDATE_DONE

_BOSS_UPDATE_JUMP:
    call BOSS_MOVE_JUMP
    beqz a0, _BOSS_UPDATE_JUMP_LANDED
    call BOSS_TICK_ACTION_TIMER
    bnez a0, _BOSS_UPDATE_DONE

_BOSS_UPDATE_JUMP_LANDED:
    sw zero, BOSS_VEL_X_OFF(s0)
    sw zero, BOSS_VEL_Y_OFF(s0)
    li a0, BOSS_STATE_IDLE
    li a1, BOSS_IDLE_TIME
    call BOSS_SET_STATE

_BOSS_UPDATE_DONE:
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 8
    ret

BOSS_TICK_ACTION_TIMER:
    lw t0, BOSS_ACTION_TIMER_OFF(s0)
    beqz t0, _BOSS_TICK_ACTION_TIMER_ZERO
    addi t0, t0, -1
    sw t0, BOSS_ACTION_TIMER_OFF(s0)
_BOSS_TICK_ACTION_TIMER_ZERO:
    mv a0, t0
    ret

# a0 = novo estado, a1 = timer
BOSS_SET_STATE:
    sw a0, BOSS_STATE_OFF(s0)
    sw a1, BOSS_ACTION_TIMER_OFF(s0)
    sw zero, BOSS_FRAME_OFF(s0)
    ret

BOSS_IS_PLAYER_NEAR:
    la t0, PLAYER_POSITION
    lh t1, 0(t0)
    lh t2, BOSS_X_OFF(s0)
    sub t3, t1, t2
    bgez t3, _BOSS_IS_PLAYER_NEAR_X_ABS_OK
    sub t3, zero, t3
_BOSS_IS_PLAYER_NEAR_X_ABS_OK:
    li t4, BOSS_TRIGGER_DISTANCE_X
    bgt t3, t4, _BOSS_IS_PLAYER_NEAR_FALSE

    lh t1, 2(t0)
    lh t2, BOSS_Y_OFF(s0)
    sub t3, t1, t2
    bgez t3, _BOSS_IS_PLAYER_NEAR_Y_ABS_OK
    sub t3, zero, t3
_BOSS_IS_PLAYER_NEAR_Y_ABS_OK:
    li t4, BOSS_TRIGGER_DISTANCE_Y
    bgt t3, t4, _BOSS_IS_PLAYER_NEAR_FALSE

    li a0, 1
    ret

_BOSS_IS_PLAYER_NEAR_FALSE:
    li a0, 0
    ret

BOSS_START_NEXT_ACTION:
    la t0, BOSS_NEXT_ACTION
    lw t1, 0(t0)
    addi t2, t1, 1
    li t3, 3
    blt t2, t3, _BOSS_START_NEXT_ACTION_SAVE
    li t2, 0
_BOSS_START_NEXT_ACTION_SAVE:
    sw t2, 0(t0)

    li t2, 1
    beq t1, t2, _BOSS_START_DASH
    li t2, 2
    beq t1, t2, _BOSS_START_JUMP

_BOSS_START_THROW:
    li a0, BOSS_STATE_THROW
    li a1, BOSS_THROW_TIME
    j BOSS_SET_STATE

_BOSS_START_DASH:
    lw t0, BOSS_DIRECTION_OFF(s0)
    li t1, BOSS_DASH_SPEED
    beqz t0, _BOSS_START_DASH_RIGHT
    sub t1, zero, t1
_BOSS_START_DASH_RIGHT:
    sw t1, BOSS_VEL_X_OFF(s0)
    li a0, BOSS_STATE_DASH
    li a1, BOSS_DASH_TIME
    j BOSS_SET_STATE

_BOSS_START_JUMP:
    lw t0, BOSS_DIRECTION_OFF(s0)
    li t1, BOSS_JUMP_SPEED
    beqz t0, _BOSS_START_JUMP_RIGHT
    sub t1, zero, t1
_BOSS_START_JUMP_RIGHT:
    sw t1, BOSS_VEL_X_OFF(s0)
    li t1, BOSS_JUMP_VEL
    sw t1, BOSS_VEL_Y_OFF(s0)
    li a0, BOSS_STATE_JUMP
    li a1, BOSS_JUMP_TIME
    j BOSS_SET_STATE

BOSS_FACE_PLAYER:
    la t0, PLAYER_POSITION
    lh t1, 0(t0)
    lh t2, BOSS_X_OFF(s0)
    li t3, 0
    bge t1, t2, _BOSS_FACE_PLAYER_SAVE
    li t3, 1
_BOSS_FACE_PLAYER_SAVE:
    sw t3, BOSS_DIRECTION_OFF(s0)
    ret

BOSS_MOVE_DASH:
    addi sp, sp, -8
    sw   ra, 0(sp)
    sw   s1, 4(sp)

    lw t0, BOSS_VEL_X_OFF(s0)
    beqz t0, _BOSS_MOVE_DASH_DONE

    lh t1, BOSS_X_OFF(s0)
    add t1, t1, t0
    mv s1, t1
    sh t1, BOSS_X_OFF(s0)

    addi a0, t1, BOSS_HITBOX_OFFSET_X
    lh a1, BOSS_Y_OFF(s0)
    addi a1, a1, BOSS_HITBOX_OFFSET_Y
    li a2, BOSS_HITBOX_W
    li a3, BOSS_HITBOX_H
    mv a4, t0
    call PHYSICS_RESOLVE_HORIZONTAL_MAP_COLLISION

    li t2, BOSS_HITBOX_OFFSET_X
    sub t1, a0, t2
    sh t1, BOSS_X_OFF(s0)
    beq t1, s1, _BOSS_MOVE_DASH_DONE
    sw zero, BOSS_ACTION_TIMER_OFF(s0)
    sw zero, BOSS_VEL_X_OFF(s0)

_BOSS_MOVE_DASH_DONE:
    lw   s1, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 8
    ret

BOSS_MOVE_JUMP:
    addi sp, sp, -4
    sw   ra, 0(sp)

    lh t1, BOSS_X_OFF(s0)
    lw t0, BOSS_VEL_X_OFF(s0)
    add t1, t1, t0
    sh t1, BOSS_X_OFF(s0)

    addi a0, t1, BOSS_HITBOX_OFFSET_X
    lh a1, BOSS_Y_OFF(s0)
    addi a1, a1, BOSS_HITBOX_OFFSET_Y
    li a2, BOSS_HITBOX_W
    li a3, BOSS_HITBOX_H
    mv a4, t0
    call PHYSICS_RESOLVE_HORIZONTAL_MAP_COLLISION
    li t2, BOSS_HITBOX_OFFSET_X
    sub t1, a0, t2
    sh t1, BOSS_X_OFF(s0)

    lh t1, BOSS_Y_OFF(s0)
    lw t0, BOSS_VEL_Y_OFF(s0)
    add t1, t1, t0
    sh t1, BOSS_Y_OFF(s0)

    lh a0, BOSS_X_OFF(s0)
    addi a0, a0, BOSS_HITBOX_OFFSET_X
    lh a1, BOSS_Y_OFF(s0)
    addi a1, a1, BOSS_HITBOX_OFFSET_Y
    li a2, BOSS_HITBOX_W
    li a3, BOSS_HITBOX_H
    lw a4, BOSS_VEL_Y_OFF(s0)
    call PHYSICS_RESOLVE_VERTICAL_MAP_COLLISION
    li t2, BOSS_HITBOX_OFFSET_Y
    sub t1, a0, t2
    sh t1, BOSS_Y_OFF(s0)
    sw a1, BOSS_VEL_Y_OFF(s0)
    mv a0, a2

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

BOSS_SHOOT_TRIPLE:
    addi sp, sp, -16
    sw   ra, 0(sp)
    sw   s1, 4(sp)
    sw   s2, 8(sp)
    sw   s3, 12(sp)

    lh s1, BOSS_X_OFF(s0)
    addi s1, s1, 12
    lh s2, BOSS_Y_OFF(s0)
    addi s2, s2, -8
    lw t2, BOSS_DIRECTION_OFF(s0)
    li s3, BOSS_SHOT_SPEED
    beqz t2, _BOSS_SHOOT_RIGHT
    sub s3, zero, s3
_BOSS_SHOOT_RIGHT:
    mv a0, s1
    mv a1, s2
    mv a2, s3
    li a3, 0
    call BOSS_SPAWN_SHOT

    mv a0, s1
    mv a1, s2
    mv a2, s3
    li a3, -2
    call BOSS_SPAWN_SHOT

    mv a0, s1
    mv a1, s2
    mv a2, s3
    li a3, 2
    call BOSS_SPAWN_SHOT

    la a0, SFX_ENEMY_SHOOT
    call SFX_PLAY

    lw   s3, 12(sp)
    lw   s2, 8(sp)
    lw   s1, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret

# a0=x, a1=y, a2=vx, a3=vy
BOSS_SPAWN_SHOT:
    la t0, BOSS_SHOTS_ACTIVE
    la t1, BOSS_SHOTS_X
    la t2, BOSS_SHOTS_Y
    la t3, BOSS_SHOTS_VX
    la t4, BOSS_SHOTS_VY
    li t5, 0
_BOSS_SPAWN_SHOT_LOOP:
    lw t6, 0(t0)
    beqz t6, _BOSS_SPAWN_SHOT_FOUND
    addi t0, t0, 4
    addi t1, t1, 2
    addi t2, t2, 2
    addi t3, t3, 4
    addi t4, t4, 4
    addi t5, t5, 1
    li t6, BOSS_SHOTS_MAX
    blt t5, t6, _BOSS_SPAWN_SHOT_LOOP
    ret
_BOSS_SPAWN_SHOT_FOUND:
    li t6, 1
    sw t6, 0(t0)
    sh a0, 0(t1)
    sh a1, 0(t2)
    sw a2, 0(t3)
    sw a3, 0(t4)
    ret

BOSS_UPDATE_SHOTS:
    la t0, BOSS_SHOTS_ACTIVE
    la t1, BOSS_SHOTS_X
    la t2, BOSS_SHOTS_Y
    la t3, BOSS_SHOTS_VX
    la t4, BOSS_SHOTS_VY
    li t5, 0
_BOSS_UPDATE_SHOTS_LOOP:
    li t6, BOSS_SHOTS_MAX
    beq t5, t6, _BOSS_UPDATE_SHOTS_DONE
    lw t6, 0(t0)
    beqz t6, _BOSS_UPDATE_SHOTS_NEXT

    lh a0, 0(t1)
    lw a1, 0(t3)
    add a0, a0, a1
    sh a0, 0(t1)

    lh a1, 0(t2)
    lw a2, 0(t4)
    add a1, a1, a2
    sh a1, 0(t2)

    la a2, BG_POS
    lh a3, 0(a2)
    sub a3, a0, a3
    li a4, -16
    blt a3, a4, _BOSS_UPDATE_SHOTS_DEACTIVATE
    li a4, SCREEN_W
    addi a4, a4, 16
    bge a3, a4, _BOSS_UPDATE_SHOTS_DEACTIVATE
    lh a3, 2(a2)
    sub a3, a1, a3
    li a4, -16
    blt a3, a4, _BOSS_UPDATE_SHOTS_DEACTIVATE
    li a4, SCREEN_H
    addi a4, a4, 16
    blt a3, a4, _BOSS_UPDATE_SHOTS_NEXT

_BOSS_UPDATE_SHOTS_DEACTIVATE:
    sw zero, 0(t0)

_BOSS_UPDATE_SHOTS_NEXT:
    addi t0, t0, 4
    addi t1, t1, 2
    addi t2, t2, 2
    addi t3, t3, 4
    addi t4, t4, 4
    addi t5, t5, 1
    j _BOSS_UPDATE_SHOTS_LOOP

_BOSS_UPDATE_SHOTS_DONE:
    ret

# a0 = x do tiro do player, a1 = y do tiro do player
# retorna a0 = 0 sem colisao, 2 acertou o boss e deve desativar o tiro.
BOSS_HANDLE_SHOT_COLLISION:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la t0, CURRENT_MAP_BOSS_COUNT
    lw t1, 0(t0)
    beqz t1, _BOSS_HANDLE_SHOT_COLLISION_FALSE

    la t0, BOSS_TABLE
    lw t1, BOSS_ALIVE_OFF(t0)
    beqz t1, _BOSS_HANDLE_SHOT_COLLISION_FALSE
    lw t1, BOSS_STATE_OFF(t0)
    li t2, BOSS_STATE_INACTIVE
    beq t1, t2, _BOSS_HANDLE_SHOT_COLLISION_FALSE

    lh t1, BOSS_X_OFF(t0)
    addi t1, t1, BOSS_HITBOX_OFFSET_X
    li t2, BOSS_HITBOX_W
    add t2, t1, t2
    li t3, PLAYER_SHOT_W
    add t3, a0, t3
    bge a0, t2, _BOSS_HANDLE_SHOT_COLLISION_FALSE
    bge t1, t3, _BOSS_HANDLE_SHOT_COLLISION_FALSE

    lh t1, BOSS_Y_OFF(t0)
    addi t1, t1, BOSS_HITBOX_OFFSET_Y
    li t2, BOSS_HITBOX_H
    add t2, t1, t2
    li t3, PLAYER_SHOT_H
    add t3, a1, t3
    bge a1, t2, _BOSS_HANDLE_SHOT_COLLISION_FALSE
    bge t1, t3, _BOSS_HANDLE_SHOT_COLLISION_FALSE

    lw t1, BOSS_HP_OFF(t0)
    addi t1, t1, -1
    sw t1, BOSS_HP_OFF(t0)
    bgtz t1, _BOSS_HANDLE_SHOT_COLLISION_HIT

    sw zero, BOSS_ALIVE_OFF(t0)
    li t1, BOSS_STATE_DEAD
    sw t1, BOSS_STATE_OFF(t0)
    sw zero, BOSS_VEL_X_OFF(t0)
    sw zero, BOSS_VEL_Y_OFF(t0)
    lh a0, BOSS_X_OFF(t0)
    lh a1, BOSS_Y_OFF(t0)
    call ENEMY_DEAD_SPAWN
    la t0, BOSS_RESTART_TIMER
    li t1, BOSS_DEATH_RESTART_DELAY
    sw t1, 0(t0)

_BOSS_HANDLE_SHOT_COLLISION_HIT:
    la a0, SFX_ENEMY_HIT
    call SFX_PLAY
    li a0, 2
    j _BOSS_HANDLE_SHOT_COLLISION_DONE

_BOSS_HANDLE_SHOT_COLLISION_FALSE:
    li a0, 0

_BOSS_HANDLE_SHOT_COLLISION_DONE:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# Retorna a0 = 1 se o player encostou no boss vivo, a1 = x do boss.
BOSS_CHECK_PLAYER_COLLISION:
    la t0, CURRENT_MAP_BOSS_COUNT
    lw t1, 0(t0)
    beqz t1, _BOSS_CHECK_PLAYER_COLLISION_FALSE

    la a2, BOSS_TABLE
    lw t1, BOSS_ALIVE_OFF(a2)
    beqz t1, _BOSS_CHECK_PLAYER_COLLISION_FALSE
    lw t1, BOSS_STATE_OFF(a2)
    li t2, BOSS_STATE_INACTIVE
    beq t1, t2, _BOSS_CHECK_PLAYER_COLLISION_FALSE

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

    lh a5, BOSS_X_OFF(a2)
    addi a5, a5, BOSS_HITBOX_OFFSET_X
    li a6, BOSS_HITBOX_W
    add a6, a5, a6
    bge t1, a6, _BOSS_CHECK_PLAYER_COLLISION_FALSE
    bge a5, t2, _BOSS_CHECK_PLAYER_COLLISION_FALSE

    lh a5, BOSS_Y_OFF(a2)
    addi a5, a5, BOSS_HITBOX_OFFSET_Y
    li a6, BOSS_HITBOX_H
    add a6, a5, a6
    bge t3, a6, _BOSS_CHECK_PLAYER_COLLISION_FALSE
    bge a5, t4, _BOSS_CHECK_PLAYER_COLLISION_FALSE

    li a0, 1
    lh a1, BOSS_X_OFF(a2)
    ret

_BOSS_CHECK_PLAYER_COLLISION_FALSE:
    li a0, 0
    ret

# Retorna a0 = 1 se um tiro do boss acertou o player, a1 = x do tiro.
BOSS_CHECK_PLAYER_SHOT_COLLISION:
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

    li a5, 0
    la a2, BOSS_SHOTS_ACTIVE
    la a3, BOSS_SHOTS_X
    la a4, BOSS_SHOTS_Y

_BOSS_CHECK_PLAYER_SHOT_COLLISION_LOOP:
    li a6, BOSS_SHOTS_MAX
    beq a5, a6, _BOSS_CHECK_PLAYER_SHOT_COLLISION_FALSE

    lw a6, 0(a2)
    beqz a6, _BOSS_CHECK_PLAYER_SHOT_COLLISION_NEXT

    lh a6, 0(a3)
    li a7, BOSS_SHOT_W
    add a7, a6, a7
    bge t1, a7, _BOSS_CHECK_PLAYER_SHOT_COLLISION_NEXT
    bge a6, t2, _BOSS_CHECK_PLAYER_SHOT_COLLISION_NEXT

    lh a7, 0(a4)
    addi a0, a7, BOSS_SHOT_H
    bge t3, a0, _BOSS_CHECK_PLAYER_SHOT_COLLISION_NEXT
    bge a7, t4, _BOSS_CHECK_PLAYER_SHOT_COLLISION_NEXT

    sw zero, 0(a2)
    li a0, 1
    mv a1, a6
    ret

_BOSS_CHECK_PLAYER_SHOT_COLLISION_NEXT:
    addi a5, a5, 1
    addi a2, a2, 4
    addi a3, a3, 2
    addi a4, a4, 2
    j _BOSS_CHECK_PLAYER_SHOT_COLLISION_LOOP

_BOSS_CHECK_PLAYER_SHOT_COLLISION_FALSE:
    li a0, 0
    ret

BOSS_RENDER:
    addi sp, sp, -12
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   a3, 8(sp)

    la t0, CURRENT_MAP_BOSS_COUNT
    lw t1, 0(t0)
    beqz t1, _BOSS_RENDER_SHOTS_ONLY

    la s0, BOSS_TABLE
    lw t0, BOSS_ALIVE_OFF(s0)
    beqz t0, _BOSS_RENDER_SHOTS_ONLY

    lh a0, BOSS_X_OFF(s0)
    lh a1, BOSS_Y_OFF(s0)
    call WORLD_TO_SCREEN_POSITION
    mv a2, a1
    mv a1, a0

    lw t0, BOSS_STATE_OFF(s0)
    li t1, BOSS_STATE_INTRO
    beq t0, t1, _BOSS_RENDER_IGNITION
    li t1, BOSS_STATE_THROW
    beq t0, t1, _BOSS_RENDER_THROW
    li t1, BOSS_STATE_DASH
    beq t0, t1, _BOSS_RENDER_IGNITION
    li t1, BOSS_STATE_JUMP
    beq t0, t1, _BOSS_RENDER_JUMP
    la a0, BOSS_SPRITE_INTRO_FRAME
    j _BOSS_RENDER_READY

_BOSS_RENDER_IGNITION:
    lw t0, BOSS_FRAME_OFF(s0)
    srli t0, t0, BOSS_ANIM_SHIFT
    li t1, 1
    beq t0, t1, _BOSS_RENDER_IGNITION_2
    li t1, 2
    beq t0, t1, _BOSS_RENDER_IGNITION_3
    li t1, 3
    beq t0, t1, _BOSS_RENDER_IGNITION_4
    li t1, 4
    bge t0, t1, _BOSS_RENDER_IGNITION_5
    la a0, BOSS_SPRITE_IGNITION_1
    j _BOSS_RENDER_READY
_BOSS_RENDER_IGNITION_2:
    la a0, BOSS_SPRITE_IGNITION_2
    j _BOSS_RENDER_READY
_BOSS_RENDER_IGNITION_3:
    la a0, BOSS_SPRITE_IGNITION_3
    j _BOSS_RENDER_READY
_BOSS_RENDER_IGNITION_4:
    la a0, BOSS_SPRITE_IGNITION_4
    j _BOSS_RENDER_READY
_BOSS_RENDER_IGNITION_5:
    la a0, BOSS_SPRITE_IGNITION_5
    j _BOSS_RENDER_READY

_BOSS_RENDER_THROW:
    lw t0, BOSS_FRAME_OFF(s0)
    srli t0, t0, BOSS_ANIM_SHIFT
    andi t0, t0, 1
    bnez t0, _BOSS_RENDER_THROW_2
    la a0, BOSS_SPRITE_THROW_1
    j _BOSS_RENDER_READY
_BOSS_RENDER_THROW_2:
    la a0, BOSS_SPRITE_THROW_2
    j _BOSS_RENDER_READY

_BOSS_RENDER_JUMP:
    la a0, BOSS_SPRITE_JUMP

_BOSS_RENDER_READY:
    lw a3, 8(sp)
    lw t0, BOSS_DIRECTION_OFF(s0)
    xori a4, t0, 1
    call RENDER_ENTITY

_BOSS_RENDER_SHOTS_ONLY:
    lw a3, 8(sp)
    call BOSS_RENDER_SHOTS

    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 12
    ret

BOSS_RENDER_SHOTS:
    addi sp, sp, -24
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    sw   s3, 16(sp)
    sw   s4, 20(sp)

    mv s4, a3
    li s0, 0
    la s1, BOSS_SHOTS_ACTIVE
    la s2, BOSS_SHOTS_X
    la s3, BOSS_SHOTS_Y

_BOSS_RENDER_SHOTS_LOOP:
    li t0, BOSS_SHOTS_MAX
    beq s0, t0, _BOSS_RENDER_SHOTS_DONE
    lw t0, 0(s1)
    beqz t0, _BOSS_RENDER_SHOTS_NEXT

    lh a0, 0(s2)
    lh a1, 0(s3)
    call WORLD_TO_SCREEN_POSITION
    mv t1, a0
    mv t2, a1
    la a0, PLAYER_SPRITE_SHOOT_PROJECTILE
    mv a1, t1
    mv a2, t2
    mv a3, s4
    li a4, 0
    call PRINT_CLIPPED

_BOSS_RENDER_SHOTS_NEXT:
    addi s0, s0, 1
    addi s1, s1, 4
    addi s2, s2, 2
    addi s3, s3, 2
    j _BOSS_RENDER_SHOTS_LOOP

_BOSS_RENDER_SHOTS_DONE:
    lw   s4, 20(sp)
    lw   s3, 16(sp)
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 24
    ret
