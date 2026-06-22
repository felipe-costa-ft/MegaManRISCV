# ===========================================================================
# engine/render.s - Motor de Renderização Base
# ===========================================================================

# PRINT: desenha imagem ancorada no canto superior esquerdo
# a0 = imagem (.word largura, altura; depois pixels)
# a1 = x na tela
# a2 = y na tela
# a3 = endereco base do framebuffer
# a4 = 0 normal; diferente de 0 espelha horizontalmente
# Obs: nao faz clipping nem transparencia; usa t0-t6 e a5.
PRINT:
    mv  t0, a3
    add t0, t0, a1
    li  t1, 320
    mul t1, t1, a2
    add t0, t0, t1
    addi t1, a0, 8
    mv  t2, zero
    mv  t3, zero
    lw  t4, 0(a0)
    lw  t5, 4(a0)
    bnez a4, PRINT_FLIP_LINHA
PRINT_LINHA:
    lw  t6, 0(t1)
    sw  t6, 0(t0)
    addi t0, t0, 4
    addi t1, t1, 4
    addi t3, t3, 4
    blt  t3, t4, PRINT_LINHA
    addi t0, t0, 320
    sub  t0, t0, t4
    mv  t3, zero
    addi t2, t2, 1
    blt  t2, t5, PRINT_LINHA
    ret

PRINT_FLIP_LINHA:
    add  t6, t1, t4
    addi t6, t6, -1
PRINT_FLIP_PIXEL:
    lbu  a5, 0(t6)
    sb   a5, 0(t0)
    addi t6, t6, -1
    addi t0, t0, 1
    addi t3, t3, 1
    blt  t3, t4, PRINT_FLIP_PIXEL
    add  t1, t1, t4
    addi t0, t0, 320
    sub  t0, t0, t4
    mv   t3, zero
    addi t2, t2, 1
    blt  t2, t5, PRINT_FLIP_LINHA
    ret


# RENDER_ENTITY: desenha imagem ancorada na base esquerda
# a0 = imagem
# a1 = x na tela
# a2 = y da entidade no mapa/tela
# a3 = endereco base do framebuffer
# a4 = 0 normal; diferente de 0 espelha horizontalmente
RENDER_ENTITY:
    addi a2, a2, TILE_H
    lw  t0, 4(a0)
    sub a2, a2, t0
    j   PRINT


# RENDER_TILE: renderiza tile na posição x=a1, y=a2, framebuffer=a3
# a0 = número do tile
# a1 = x na tela, em pixels
# a2 = y na tela, em pixels
# a3 = endereco base do framebuffer (0xFF000000 ou 0xFF100000)
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

    add  t1, a1, t3
    li   t2, SCREEN_W
    mul  t2, a2, t2
    add  t1, t1, t2
    add  t1, a3, t1

    li   t4, 0
    li   a4, TILESET_W
    li   a5, SCREEN_W
    li   a6, TILE_H
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
    add  t6, t6, a4
    add  t1, t1, a5
    addi t4, t4, 1
    blt  t4, a6, PT_ROW
PT_RET:
    ret


# RENDER_MAPA:
# a0 = endereco da matriz visual do mapa
# a1 = numero de colunas do mapa
# a2 = numero de linhas do mapa
# a3 = endereço do framebuffer (0xFF000000 ou 0xFF100000)
RENDER_MAPA:
    addi sp, sp, -48
    sw   ra,  0(sp)
    sw   s1,  4(sp)
    sw   s2,  8(sp)
    sw   s3, 12(sp)
    sw   s4, 16(sp)
    sw   s5, 20(sp)
    sw   s6, 24(sp)
    sw   s7, 28(sp)
    sw   s8, 32(sp)
    sw   s9, 36(sp)
    sw   s10, 40(sp)
    sw   s11, 44(sp)

    mv   s1, a0          # mapa visual
    mv   s2, a1          # colunas do mapa
    mv   s3, a2          # linhas do mapa
    mv   s4, a3          # framebuffer

    la   t0, BG_POS
    lh   t0, 0(t0)
    srli s5, t0, TILE_W_SHIFT  # primeira coluna visivel
    andi s6, t0, TILE_OFFSET_MASK # scroll parcial dentro do tile

    li   s7, 0
    li   s11, 0
RM_ROW:
    li   s8, 0
    sub  s10, zero, s6
    mul  t0, s7, s2
    add  t0, t0, s5
    add  s9, s1, t0
RM_COL:
    add  t0, s5, s8
    bge  t0, s2, RM_NEXT_ROW

    mv   t2, s10
    li   t3, SCREEN_W
    bge  t2, t3, RM_NEXT_ROW

    mv   t4, s11

    lbu  t5, 0(s9)

    mv   a0, t5
    mv   a1, t2
    mv   a2, t4
    mv   a3, s4
    call RENDER_TILE

    addi s9, s9, 1
    addi s10, s10, TILE_W
    addi s8, s8, 1
    li   t0, MAP_VISIBLE_COLS
    blt  s8, t0, RM_COL

RM_NEXT_ROW:
    addi s7, s7, 1
    addi s11, s11, TILE_H
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
    lw   s9, 36(sp)
    lw   s10, 40(sp)
    lw   s11, 44(sp)
    addi sp, sp, 48
    ret
