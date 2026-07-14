# ===========================================================================
# utils.s - Conversoes de coordenadas
# ===========================================================================

.text

# LOAD_ENTITY_POSITION
# Guarda a posição inicial de uma entidade no endereço de destino
# a0 = origem: .byte col,row
# a1 = destino: .half x,y
LOAD_ENTITY_POSITION:
    addi sp, sp, -8
    sw   ra, 0(sp)
    sw   a1, 4(sp)

    lbu  t0, 0(a0)
    lbu  a1, 1(a0)
    mv   a0, t0
    call MAP_GRID_TO_WORLD_POSITION

    lw   t0, 4(sp)
    sh   a0, 0(t0)
    sh   a1, 2(t0)

    lw   ra, 0(sp)
    addi sp, sp, 8
    ret


# MAP_GRID_TO_WORLD_POSITION
# a0 = coluna no mapa, em tiles
# a1 = linha no mapa, em tiles
# retorna:
# a0 = x no mundo, em pixels
# a1 = y no mundo, em pixels
MAP_GRID_TO_WORLD_POSITION:
    slli a0, a0, TILE_W_SHIFT
    slli a1, a1, TILE_H_SHIFT
    ret

# WORLD_TO_SCREEN_POSITION
# a0 = x no mundo, em pixels
# a1 = y no mundo, em pixels
# retorna:
# a0 = x na tela, em pixels
# a1 = y na tela, em pixels
WORLD_TO_SCREEN_POSITION:
    la   t0, BG_POS
    lh   t1, 0(t0)
    lh   t2, 2(t0)
    sub  a0, a0, t1
    sub  a1, a1, t2
    ret

# IS_WORLD_POSITION_NEAR_SCREEN
# a0 = x no mundo, a1 = y no mundo, a2 = margem fora do viewport
# retorna a0 = 1 dentro da tela expandida; 0 se deve permanecer adormecido.
IS_WORLD_POSITION_NEAR_SCREEN:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s1, 4(sp)
    mv s1, a2
    call WORLD_TO_SCREEN_POSITION

    sub t0, zero, s1
    blt a0, t0, _IS_WORLD_POSITION_NEAR_SCREEN_FALSE
    li t0, SCREEN_W
    add t0, t0, s1
    bge a0, t0, _IS_WORLD_POSITION_NEAR_SCREEN_FALSE
    sub t0, zero, s1
    blt a1, t0, _IS_WORLD_POSITION_NEAR_SCREEN_FALSE
    li t0, SCREEN_H
    add t0, t0, s1
    bge a1, t0, _IS_WORLD_POSITION_NEAR_SCREEN_FALSE
    li a0, 1
    j _IS_WORLD_POSITION_NEAR_SCREEN_DONE

_IS_WORLD_POSITION_NEAR_SCREEN_FALSE:
    li a0, 0

_IS_WORLD_POSITION_NEAR_SCREEN_DONE:
    lw s1, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 8
    ret

# MAP_GRID_TO_SCREEN_POSITION
# a0 = coluna no mapa, em tiles
# a1 = linha no mapa, em tiles
# retorna:
# a0 = x na tela, em pixels
# a1 = y na tela, em pixels
MAP_GRID_TO_SCREEN_POSITION:
    addi sp, sp, -4
    sw   ra, 0(sp)

    call MAP_GRID_TO_WORLD_POSITION
    call WORLD_TO_SCREEN_POSITION

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
