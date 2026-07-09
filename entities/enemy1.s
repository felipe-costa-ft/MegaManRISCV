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
.eqv ENEMY1_SIZE        12


  ENEMY1_TABLE:
      # x, y, vel_x, state
      .half 0, 0
      .word 0, 0
      .half 0, 0
      .word 0, 0


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

    li t0, ENEMY1_STATE_PATROLLING
    sw t0, ENEMY1_STATE_OFF(s2)

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
    addi sp, sp, -4
    sw   ra, 0(sp)



    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

ENEMY1_RENDER:
    addi sp, sp, -16
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)

    li s0, 0
    li s1, MAPA1_INIMIGO1_COUNT
    la s2, ENEMY1_TABLE

_ENEMY1_RENDER_LOOP:

    beq s0, s1, _ENEMY1_RENDER_LOOP_END

    lh a0, ENEMY1_X_OFF(s2)
    lh a1, ENEMY1_Y_OFF(s2)
    call WORLD_TO_SCREEN_POSITION

    mv a2, a1
    mv a1, a0
    la a0, ENEMY1_SPRITE_WALKING_1
    li a4, 0
    call RENDER_ENTITY

    addi s0, s0, 1
    addi s2, s2, ENEMY1_SIZE
    j _ENEMY1_RENDER_LOOP

_ENEMY1_RENDER_LOOP_END:

    lw   s2, 12(sp)
    lw   s1, 8(sp)
    lw   s0, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 16
    ret
