# ===========================================================================
# engine/render.s - Motor de Renderização Base
# ===========================================================================

# RENDER_TILE: renderiza tile na posição x=a1, y=a2, framebuffer=a3
# a0 = número do tile
# a1 = x na tela, em pixels
# a2 = y na tela, em pixels
# a3 = framebuffer (0 ou 1)
RENDER_TILE:

    li   t3, 0
    bgez a1, PT_CL_OK
    sub  t3, zero, a1
PT_CL_OK:
    li   t4, 0
    addi t5, a1, TILE_W
    li   t6, SCREEN_W
    ble  t5, t6, PT_CR_OK
    sub  t4, t5, t6
PT_CR_OK:
    li   t5, TILE_W
    sub  t5, t5, t3
    sub  t5, t5, t4
    blez t5, PT_RET

    la   t6, tileset
    addi t6, t6, IMG_HEADER_BYTES

    # endereco_offset = base_tabela + tile_id * 4
    la   t1, MAPA1_TILESET_OFFSETS
    slli t2, a0, 2  # a0 = tile_id
    add  t1, t1, t2
    lw   t1, 0(t1)  # offset em bytes no tileset

    add t6, t6, t1
    add  t6, t6, t3

    li   t0, 0xFF0
    add  t0, t0, a3
    slli t0, t0, 20
    add  t1, a1, t3
    li   t2, SCREEN_W
    mul  t2, a2, t2
    add  t1, t1, t2
    add  t1, t0, t1

    li   t4, 0
PT_ROW:
    mv   t2, t6
    mv   t3, t1
    mv   t0, t5
PT_PIX:
    lbu  a0, 0(t2)
    sb   a0, 0(t3)
    addi t2, t2, 1
    addi t3, t3, 1
    addi t0, t0, -1
    bnez t0, PT_PIX
    li   t0, TILESET_W
    add  t6, t6, t0
    li   t0, SCREEN_W
    add  t1, t1, t0
    addi t4, t4, 1
    li   t0, TILE_H
    blt  t4, t0, PT_ROW
PT_RET:
    ret


# RENDER_MAPA:
# a0 = endereco da matriz visual do mapa
# a1 = numero de colunas do mapa
# a2 = numero de linhas do mapa
# a3 = framebuffer (0 ou 1)
RENDER_MAPA:
    addi sp, sp, -36
    sw   ra,  0(sp)
    sw   s1,  4(sp)
    sw   s2,  8(sp)
    sw   s3, 12(sp)
    sw   s4, 16(sp)
    sw   s5, 20(sp)
    sw   s6, 24(sp)
    sw   s7, 28(sp)
    sw   s8, 32(sp)

    mv   s1, a0          # mapa visual
    mv   s2, a1          # colunas do mapa
    mv   s3, a2          # linhas do mapa
    mv   s4, a3          # framebuffer

    la   t0, BG_POS
    lh   t0, 0(t0)
    srli s5, t0, TILE_W_SHIFT  # primeira coluna visivel
    andi s6, t0, TILE_OFFSET_MASK # scroll parcial dentro do tile

    li   s7, 0
RM_ROW:
    li   s8, 0
RM_COL:
    add  t0, s5, s8
    bge  t0, s2, RM_NEXT_ROW

    slli t2, s8, TILE_W_SHIFT
    sub  t2, t2, s6
    li   t3, SCREEN_W
    bge  t2, t3, RM_NEXT_ROW

    slli t4, s7, TILE_H_SHIFT

    mul  t5, s7, s2
    add  t5, t5, t0
    add  t6, s1, t5
    lbu  t5, 0(t6)

    mv   a0, t5
    mv   a1, t2
    mv   a2, t4
    mv   a3, s4
    call RENDER_TILE

    addi s8, s8, 1
    li   t0, MAP_VISIBLE_COLS
    blt  s8, t0, RM_COL

RM_NEXT_ROW:
    addi s7, s7, 1
    blt  s7, s3, RM_ROW

    lw   ra,  0(sp)
    lw   s1,  4(sp)
    lw   s2,  8(sp)
    lw   s3, 12(sp)
    lw   s4, 16(sp)
    lw   s5, 20(sp)
    lw   s6, 24(sp)
    lw   s7, 28(sp)
    lw   s8, 32(sp)
    addi sp, sp, 36
    ret
