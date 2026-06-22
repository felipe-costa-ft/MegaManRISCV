# ===========================================================================
# engine/physics.s - Fisica e colisao com mapa
# ===========================================================================

.text

# PHYSICS_GET_COLLISION_TILE
# a0 = x em pixels na tela
# a1 = y em pixels na tela
# retorna a0 = tile de colisao, ou 0 fora do mapa
PHYSICS_GET_COLLISION_TILE:
    la  t0, BG_POS
    lh  t1, 0(t0)
    lh  t2, 2(t0)
    add a0, a0, t1
    add a1, a1, t2

    bltz a0, _PHYSICS_GET_COLLISION_TILE_EMPTY
    bltz a1, _PHYSICS_GET_COLLISION_TILE_EMPTY

    srli t0, a0, TILE_W_SHIFT
    srli t1, a1, TILE_H_SHIFT

    li   t2, MAPA1_MAP_COLS
    bge  t0, t2, _PHYSICS_GET_COLLISION_TILE_EMPTY

    li   t3, MAPA1_MAP_ROWS
    bge  t1, t3, _PHYSICS_GET_COLLISION_TILE_EMPTY

    mul  t3, t1, t2
    add  t3, t3, t0
    la   t4, MAPA1_COLISAO
    add  t4, t4, t3
    lbu  a0, 0(t4)
    ret

_PHYSICS_GET_COLLISION_TILE_EMPTY:
    li a0, 0
    ret

# PHYSICS_IS_SOLID_TILE
# a0 = tile de colisao
# retorna a0 = 1 se solido, 0 caso contrario
PHYSICS_IS_SOLID_TILE:
    li t0, 1
    beq a0, t0, _PHYSICS_IS_SOLID_TILE_TRUE
    li a0, 0
    ret

_PHYSICS_IS_SOLID_TILE_TRUE:
    li a0, 1
    ret

# PHYSICS_APPLY_GRAVITY
# Stub reservado para etapa de gravidade.
PHYSICS_APPLY_GRAVITY:
    ret

# PHYSICS_RESOLVE_HORIZONTAL_MAP_COLLISION
# a0 = x atual do corpo
# a1 = y atual do corpo
# a2 = largura do corpo
# a3 = altura do corpo
# a4 = direcao: -1 esquerda, 1 direita
# retorna a0 = x corrigido
PHYSICS_RESOLVE_HORIZONTAL_MAP_COLLISION:
    addi sp, sp, -28
    sw   ra, 0(sp)
    sw   s1, 4(sp)
    sw   s2, 8(sp)
    sw   s3, 12(sp)
    sw   s4, 16(sp)
    sw   s5, 20(sp)
    sw   s6, 24(sp)

    mv s1, a0
    mv s2, a1
    mv s3, a2
    mv s4, a3
    mv s5, a4

    bltz s5, _PHYSICS_RESOLVE_HORIZONTAL_LEFT

_PHYSICS_RESOLVE_HORIZONTAL_RIGHT:
    add  s6, s1, s3
    addi s6, s6, -1

    mv   a0, s6
    srli t0, s4, 1
    add  a1, s2, t0
    call PHYSICS_GET_COLLISION_TILE
    call PHYSICS_IS_SOLID_TILE
    bnez a0, _PHYSICS_RESOLVE_HORIZONTAL_RIGHT_HIT

    mv   a0, s6
    add  a1, s2, s4
    addi a1, a1, -2
    call PHYSICS_GET_COLLISION_TILE
    call PHYSICS_IS_SOLID_TILE
    bnez a0, _PHYSICS_RESOLVE_HORIZONTAL_RIGHT_HIT

    j _PHYSICS_RESOLVE_HORIZONTAL_DONE

_PHYSICS_RESOLVE_HORIZONTAL_RIGHT_HIT:
    srli t0, s6, TILE_W_SHIFT
    slli t0, t0, TILE_W_SHIFT
    sub  s1, t0, s3
    j _PHYSICS_RESOLVE_HORIZONTAL_DONE

_PHYSICS_RESOLVE_HORIZONTAL_LEFT:
    mv   a0, s1
    srli t0, s4, 1
    add  a1, s2, t0
    call PHYSICS_GET_COLLISION_TILE
    call PHYSICS_IS_SOLID_TILE
    bnez a0, _PHYSICS_RESOLVE_HORIZONTAL_LEFT_HIT

    mv   a0, s1
    add  a1, s2, s4
    addi a1, a1, -2
    call PHYSICS_GET_COLLISION_TILE
    call PHYSICS_IS_SOLID_TILE
    bnez a0, _PHYSICS_RESOLVE_HORIZONTAL_LEFT_HIT

    j _PHYSICS_RESOLVE_HORIZONTAL_DONE

_PHYSICS_RESOLVE_HORIZONTAL_LEFT_HIT:
    srli t0, s1, TILE_W_SHIFT
    addi t0, t0, 1
    slli s1, t0, TILE_W_SHIFT

_PHYSICS_RESOLVE_HORIZONTAL_DONE:
    li t0, PLAYER_X_MIN
    bge s1, t0, _PHYSICS_RESOLVE_HORIZONTAL_X_MAX
    mv s1, t0

_PHYSICS_RESOLVE_HORIZONTAL_X_MAX:
    li t0, PLAYER_X_MAX
    ble s1, t0, _PHYSICS_RESOLVE_HORIZONTAL_RETURN
    mv s1, t0

_PHYSICS_RESOLVE_HORIZONTAL_RETURN:
    mv a0, s1

    lw   s6, 24(sp)
    lw   s5, 20(sp)
    lw   s4, 16(sp)
    lw   s3, 12(sp)
    lw   s2, 8(sp)
    lw   s1, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 28
    ret

# PHYSICS_RESOLVE_VERTICAL_MAP_COLLISION
# Stub reservado para colisao vertical.
PHYSICS_RESOLVE_VERTICAL_MAP_COLLISION:
    ret
