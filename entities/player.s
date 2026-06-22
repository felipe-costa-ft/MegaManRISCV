.data

PLAYER_POSITION:     .half 0, 0
PLAYER_OLD_POSITION: .half 16, 168

.text

PLAYER_SETUP:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la t0, PLAYER_STATE
    sw   zero, 0(t0)

    la a0, MAPA1_PLAYER
    la a1, PLAYER_POSITION
    call LOAD_ENTITY_POSITION

    la a0, MAPA1_PLAYER
    la a1, PLAYER_OLD_POSITION
    call LOAD_ENTITY_POSITION

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

PLAYER_UPDATE:
    addi sp, sp, -4
    sw   ra, 0(sp)

    call PLAYER_HANDLE_INPUT

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

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

PLAYER_HANDLE_INPUT:

    la   t0, INPUT_CURRENT
    lw   t1, 0(t0)

    andi t2, t1, 0x03    # INPUT_LEFT | INPUT_RIGHT
    
    la  t0, INPUT_PRESSED
    lw  t4, 0(t0)

    andi t5, t4, INPUT_JUMP
    bnez t5, PLAYER_JUMP

_PLAYER_HANDLE_INPUT_CONTINUE:

    li   t3, INPUT_LEFT
    beq  t2, t3, PLAYER_MOVE_LEFT

    li   t3, INPUT_RIGHT
    beq  t2, t3, PLAYER_MOVE_RIGHT

    ret

PLAYER_JUMP:
    li a7, 11
    li a0, 'J'
    ecall

    li a7, 11
    li a0, 10      # '\n'
    ecall

    j _PLAYER_HANDLE_INPUT_CONTINUE


PLAYER_MOVE_RIGHT:

    la t0, PLAYER_POSITION
    lhu t1, 0(t0)
    addi t1, t1, 4
    sh t1, 0(t0)

    ret

PLAYER_MOVE_LEFT:
    la t0, PLAYER_POSITION
    lhu t1, 0(t0)
    addi t1, t1, -4
    sh t1, 0(t0)

    ret
