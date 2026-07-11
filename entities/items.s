.data

# ===========================================================================
# ITEMS
# ===========================================================================

.eqv ITEM_TYPE_HP     0
.eqv ITEM_TYPE_MP     1
.eqv ITEM_MAX         8

.eqv ITEM_X_OFF       0
.eqv ITEM_Y_OFF       2
.eqv ITEM_VEL_Y_OFF   4
.eqv ITEM_TYPE_OFF    8
.eqv ITEM_ACTIVE_OFF  12
.eqv ITEM_FRAME_OFF   16
.eqv ITEM_SIZE        20

.eqv ITEM_W           16
.eqv ITEM_H           16
.eqv ITEM_HITBOX_W    16
.eqv ITEM_HITBOX_H    16
.eqv ITEM_GRAVITY_MAX 5
.eqv ITEM_DROP_CHANCE 77
.eqv ITEM_ANIM_SHIFT  4

ITEM_TABLE:
    .half 0, 0
    .word 0, 0, 0, 0
    .half 0, 0
    .word 0, 0, 0, 0
    .half 0, 0
    .word 0, 0, 0, 0
    .half 0, 0
    .word 0, 0, 0, 0
    .half 0, 0
    .word 0, 0, 0, 0
    .half 0, 0
    .word 0, 0, 0, 0
    .half 0, 0
    .word 0, 0, 0, 0
    .half 0, 0
    .word 0, 0, 0, 0

ITEM_RNG_SEED: .word 0x12345678

.text

ITEMS_SETUP:
    la t0, ITEM_TABLE
    li t1, 0
_ITEMS_SETUP_LOOP:
    li t2, ITEM_MAX
    beq t1, t2, _ITEMS_SETUP_DONE
    sw zero, ITEM_ACTIVE_OFF(t0)
    sw zero, ITEM_VEL_Y_OFF(t0)
    sw zero, ITEM_FRAME_OFF(t0)
    addi t0, t0, ITEM_SIZE
    addi t1, t1, 1
    j _ITEMS_SETUP_LOOP
_ITEMS_SETUP_DONE:
    ret

# ITEMS_TRY_SPAWN
# a0 = x no mundo, a1 = y no mundo
# 30% de chance para HP; se nao cair, 30% de chance para MP.
ITEMS_TRY_SPAWN:
    addi sp, sp, -12
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)

    mv s0, a0
    mv s1, a1

    call ITEMS_NEXT_RANDOM
    andi t0, a0, 0xFF
    li t1, ITEM_DROP_CHANCE
    bge t0, t1, _ITEMS_TRY_SPAWN_MP_ROLL

    mv a0, s0
    mv a1, s1
    li a2, ITEM_TYPE_HP
    call ITEMS_SPAWN
    j _ITEMS_TRY_SPAWN_DONE

_ITEMS_TRY_SPAWN_MP_ROLL:
    call ITEMS_NEXT_RANDOM
    andi t0, a0, 0xFF
    li t1, ITEM_DROP_CHANCE
    bge t0, t1, _ITEMS_TRY_SPAWN_DONE

    mv a0, s0
    mv a1, s1
    li a2, ITEM_TYPE_MP
    call ITEMS_SPAWN

_ITEMS_TRY_SPAWN_DONE:
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 12
    ret

# retorna a0 = proximo valor pseudoaleatorio
ITEMS_NEXT_RANDOM:
    la t0, ITEM_RNG_SEED
    lw t1, 0(t0)
    li t2, 1103515245
    mul t1, t1, t2
    li t2, 12345
    add t1, t1, t2
    sw t1, 0(t0)
    mv a0, t1
    ret

# ITEMS_SPAWN
# a0 = x, a1 = y, a2 = tipo
ITEMS_SPAWN:
    la t0, ITEM_TABLE
    li t1, 0
_ITEMS_SPAWN_LOOP:
    li t2, ITEM_MAX
    beq t1, t2, _ITEMS_SPAWN_DONE
    lw t2, ITEM_ACTIVE_OFF(t0)
    beqz t2, _ITEMS_SPAWN_FOUND
    addi t0, t0, ITEM_SIZE
    addi t1, t1, 1
    j _ITEMS_SPAWN_LOOP

_ITEMS_SPAWN_FOUND:
    sh a0, ITEM_X_OFF(t0)
    sh a1, ITEM_Y_OFF(t0)
    sw zero, ITEM_VEL_Y_OFF(t0)
    sw a2, ITEM_TYPE_OFF(t0)
    li t2, 1
    sw t2, ITEM_ACTIVE_OFF(t0)
    sw zero, ITEM_FRAME_OFF(t0)

_ITEMS_SPAWN_DONE:
    ret

ITEMS_UPDATE:
    addi sp, sp, -12
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)

    la s0, ITEM_TABLE
    li s1, 0
_ITEMS_UPDATE_LOOP:
    li t0, ITEM_MAX
    beq s1, t0, _ITEMS_UPDATE_DONE
    lw t0, ITEM_ACTIVE_OFF(s0)
    beqz t0, _ITEMS_UPDATE_NEXT

    call ITEMS_UPDATE_ONE

_ITEMS_UPDATE_NEXT:
    addi s0, s0, ITEM_SIZE
    addi s1, s1, 1
    j _ITEMS_UPDATE_LOOP

_ITEMS_UPDATE_DONE:
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 12
    ret

# s0 = item atual
ITEMS_UPDATE_ONE:
    addi sp, sp, -4
    sw   ra, 0(sp)

    lw t0, ITEM_FRAME_OFF(s0)
    addi t0, t0, 1
    sw t0, ITEM_FRAME_OFF(s0)

    lw t0, ITEM_VEL_Y_OFF(s0)
    addi t0, t0, 1
    li t1, ITEM_GRAVITY_MAX
    ble t0, t1, _ITEMS_UPDATE_ONE_VEL_OK
    mv t0, t1
_ITEMS_UPDATE_ONE_VEL_OK:
    sw t0, ITEM_VEL_Y_OFF(s0)

    lh t1, ITEM_Y_OFF(s0)
    add t1, t1, t0
    sh t1, ITEM_Y_OFF(s0)

    lh a0, ITEM_X_OFF(s0)
    lh a1, ITEM_Y_OFF(s0)
    li a2, ITEM_HITBOX_W
    li a3, ITEM_HITBOX_H
    lw a4, ITEM_VEL_Y_OFF(s0)
    call PHYSICS_RESOLVE_VERTICAL_MAP_COLLISION
    sh a0, ITEM_Y_OFF(s0)
    sw a1, ITEM_VEL_Y_OFF(s0)

    call ITEMS_CHECK_PLAYER_COLLECT

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# s0 = item atual
ITEMS_CHECK_PLAYER_COLLECT:
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

    lh a0, ITEM_X_OFF(s0)
    li a1, ITEM_HITBOX_W
    add a1, a0, a1
    bge t1, a1, _ITEMS_CHECK_PLAYER_COLLECT_DONE
    bge a0, t2, _ITEMS_CHECK_PLAYER_COLLECT_DONE

    lh a0, ITEM_Y_OFF(s0)
    li a1, ITEM_HITBOX_H
    add a1, a0, a1
    bge t3, a1, _ITEMS_CHECK_PLAYER_COLLECT_DONE
    bge a0, t4, _ITEMS_CHECK_PLAYER_COLLECT_DONE

    lw t0, ITEM_TYPE_OFF(s0)
    li t1, ITEM_TYPE_MP
    beq t0, t1, _ITEMS_COLLECT_MP

_ITEMS_COLLECT_HP:
    la t0, PLAYER_HP
    lbu t1, 0(t0)
    addi t1, t1, ITEM_RECHARGE_AMOUNT
    li t2, PLAYER_HP_MAX
    ble t1, t2, _ITEMS_COLLECT_HP_SAVE
    mv t1, t2
_ITEMS_COLLECT_HP_SAVE:
    sb t1, 0(t0)
    j _ITEMS_COLLECT_DEACTIVATE

_ITEMS_COLLECT_MP:
    la t0, PLAYER_MP
    lbu t1, 0(t0)
    addi t1, t1, ITEM_RECHARGE_AMOUNT
    li t2, PLAYER_MP_MAX
    ble t1, t2, _ITEMS_COLLECT_MP_SAVE
    mv t1, t2
_ITEMS_COLLECT_MP_SAVE:
    sb t1, 0(t0)

_ITEMS_COLLECT_DEACTIVATE:
    sw zero, ITEM_ACTIVE_OFF(s0)

_ITEMS_CHECK_PLAYER_COLLECT_DONE:
    ret

# ITEMS_RENDER
# a3 = framebuffer
ITEMS_RENDER:
    addi sp, sp, -24
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    sw   s3, 16(sp)
    sw   s4, 20(sp)

    mv s4, a3
    la s0, ITEM_TABLE
    li s1, 0
_ITEMS_RENDER_LOOP:
    li t0, ITEM_MAX
    beq s1, t0, _ITEMS_RENDER_DONE
    lw t0, ITEM_ACTIVE_OFF(s0)
    beqz t0, _ITEMS_RENDER_NEXT

    lh a0, ITEM_X_OFF(s0)
    lh a1, ITEM_Y_OFF(s0)
    call WORLD_TO_SCREEN_POSITION
    mv s2, a0
    mv s3, a1

    lw t0, ITEM_TYPE_OFF(s0)
    lw t1, ITEM_FRAME_OFF(s0)
    srli t1, t1, ITEM_ANIM_SHIFT
    andi t1, t1, 1
    li t2, ITEM_TYPE_MP
    beq t0, t2, _ITEMS_RENDER_MP

_ITEMS_RENDER_HP:
    bnez t1, _ITEMS_RENDER_HP_2
    la a0, ITEM_HP_FRAME_1
    j _ITEMS_RENDER_READY
_ITEMS_RENDER_HP_2:
    la a0, ITEM_HP_FRAME_2
    j _ITEMS_RENDER_READY

_ITEMS_RENDER_MP:
    bnez t1, _ITEMS_RENDER_MP_2
    la a0, ITEM_MP_FRAME_1
    j _ITEMS_RENDER_READY
_ITEMS_RENDER_MP_2:
    la a0, ITEM_MP_FRAME_2

_ITEMS_RENDER_READY:
    mv a1, s2
    mv a2, s3
    mv a3, s4
    li a4, 0
    call PRINT_CLIPPED

_ITEMS_RENDER_NEXT:
    addi s0, s0, ITEM_SIZE
    addi s1, s1, 1
    j _ITEMS_RENDER_LOOP

_ITEMS_RENDER_DONE:
    lw   s4, 20(sp)
    lw   s3, 16(sp)
    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 24
    ret
