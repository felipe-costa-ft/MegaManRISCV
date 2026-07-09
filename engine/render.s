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
    j   PRINT_CLIPPED


# PRINT_CLIPPED: desenha imagem com clipping nas bordas da tela
# a0 = imagem (.word largura, altura; depois pixels)
# a1 = x na tela
# a2 = y na tela
# a3 = endereco base do framebuffer
# a4 = 0 normal; diferente de 0 espelha horizontalmente
PRINT_CLIPPED:
    addi sp, sp, -36
    sw   s0, 0(sp)
    sw   s1, 4(sp)
    sw   s2, 8(sp)
    sw   s3, 12(sp)
    sw   s4, 16(sp)
    sw   s5, 20(sp)
    sw   s6, 24(sp)
    sw   s7, 28(sp)
    sw   s8, 32(sp)

    lw   s0, 0(a0)              # largura
    lw   s1, 4(a0)              # altura

    li   s2, 0                  # left_clip
    bgez a1, _PRINT_CLIPPED_LEFT_OK
    sub  s2, zero, a1
_PRINT_CLIPPED_LEFT_OK:
    li   t0, 0                  # right_clip
    add  t1, a1, s0
    li   t2, SCREEN_W
    ble  t1, t2, _PRINT_CLIPPED_RIGHT_OK
    sub  t0, t1, t2
_PRINT_CLIPPED_RIGHT_OK:
    sub  s3, s0, s2             # largura visivel
    sub  s3, s3, t0
    blez s3, _PRINT_CLIPPED_DONE

    li   s4, 0                  # top_clip
    bgez a2, _PRINT_CLIPPED_TOP_OK
    sub  s4, zero, a2
_PRINT_CLIPPED_TOP_OK:
    li   t0, 0                  # bottom_clip
    add  t1, a2, s1
    li   t2, SCREEN_H
    ble  t1, t2, _PRINT_CLIPPED_BOTTOM_OK
    sub  t0, t1, t2
_PRINT_CLIPPED_BOTTOM_OK:
    sub  s5, s1, s4             # altura visivel
    sub  s5, s5, t0
    blez s5, _PRINT_CLIPPED_DONE

    addi s6, a0, IMG_HEADER_BYTES
    mul  t0, s4, s0
    add  s6, s6, t0
    bnez a4, _PRINT_CLIPPED_FLIP_SRC
    add  s6, s6, s2
    j    _PRINT_CLIPPED_DST
_PRINT_CLIPPED_FLIP_SRC:
    add  s6, s6, s0
    addi s6, s6, -1
    sub  s6, s6, s2

_PRINT_CLIPPED_DST:
    add  t0, a1, s2
    add  t1, a2, s4
    li   t2, SCREEN_W
    mul  t1, t1, t2
    add  s7, a3, t1
    add  s7, s7, t0

    mv   s8, s5
    bnez a4, _PRINT_CLIPPED_FLIP_ROW

_PRINT_CLIPPED_ROW:
    mv   t0, s6
    mv   t1, s7
    mv   t2, s3
_PRINT_CLIPPED_PIXEL:
    lbu  t3, 0(t0)
    sb   t3, 0(t1)
    addi t0, t0, 1
    addi t1, t1, 1
    addi t2, t2, -1
    bnez t2, _PRINT_CLIPPED_PIXEL
    add  s6, s6, s0
    li   t0, SCREEN_W
    add  s7, s7, t0
    addi s8, s8, -1
    bnez s8, _PRINT_CLIPPED_ROW
    j    _PRINT_CLIPPED_DONE

_PRINT_CLIPPED_FLIP_ROW:
    mv   t0, s6
    mv   t1, s7
    mv   t2, s3
_PRINT_CLIPPED_FLIP_PIXEL:
    lbu  t3, 0(t0)
    sb   t3, 0(t1)
    addi t0, t0, -1
    addi t1, t1, 1
    addi t2, t2, -1
    bnez t2, _PRINT_CLIPPED_FLIP_PIXEL
    add  s6, s6, s0
    li   t0, SCREEN_W
    add  s7, s7, t0
    addi s8, s8, -1
    bnez s8, _PRINT_CLIPPED_FLIP_ROW

_PRINT_CLIPPED_DONE:
    lw   s8, 32(sp)
    lw   s7, 28(sp)
    lw   s6, 24(sp)
    lw   s5, 20(sp)
    lw   s4, 16(sp)
    lw   s3, 12(sp)
    lw   s2, 8(sp)
    lw   s1, 4(sp)
    lw   s0, 0(sp)
    addi sp, sp, 36
    ret


# RENDER_TILE: renderiza tile na posição x=a1, y=a2, framebuffer=a3
# a0 = número do tile
# a1 = x na tela, em pixels
# a2 = y na tela, em pixels
# a3 = endereco base do framebuffer (0xFF000000 ou 0xFF100000)
RENDER_TILE:

    li   t3, 0
    bgez a1, _RENDER_TILE_CL_OK
    sub  t3, zero, a1
_RENDER_TILE_CL_OK:
    li   t4, 0
    addi t5, a1, TILE_W
    li   t6, SCREEN_W
    ble  t5, t6, _RENDER_TILE_CR_OK
    sub  t4, t5, t6
_RENDER_TILE_CR_OK:
    li   t5, TILE_W
    sub  t5, t5, t3
    sub  t5, t5, t4
    blez t5, _RENDER_TILE_RET

    li   a4, 0
    bgez a2, _RENDER_TILE_CT_OK
    sub  a4, zero, a2
_RENDER_TILE_CT_OK:
    li   a5, 0
    addi t0, a2, TILE_H
    li   t1, SCREEN_H
    ble  t0, t1, _RENDER_TILE_CB_OK
    sub  a5, t0, t1
_RENDER_TILE_CB_OK:
    li   a6, TILE_H
    sub  a6, a6, a4
    sub  a6, a6, a5
    blez a6, _RENDER_TILE_RET

    la   t6, tileset
    addi t6, t6, IMG_HEADER_BYTES

    # endereco_offset = base_tabela + tile_id * 4
    la   t1, MAPA1_TILESET_OFFSETS
    slli t2, a0, 2  # a0 = tile_id
    add  t1, t1, t2
    lw   t1, 0(t1)  # offset em bytes no tileset

    add t6, t6, t1
    li  t0, TILESET_W
    mul t1, a4, t0
    add t6, t6, t1
    add  t6, t6, t3

    add  t1, a1, t3
    add  t2, a2, a4
    li   t0, SCREEN_W
    mul  t2, t2, t0
    add  t1, t1, t2
    add  t1, a3, t1

    li   t4, 0
    li   a4, TILESET_W
    li   a5, SCREEN_W
_RENDER_TILE_ROW:
    mv   t2, t6
    mv   t3, t1
    mv   t0, t5
_RENDER_TILE_PIXEL:
    lbu  a0, 0(t2)
    sb   a0, 0(t3)
    addi t2, t2, 1
    addi t3, t3, 1
    addi t0, t0, -1
    bnez t0, _RENDER_TILE_PIXEL
    add  t6, t6, a4
    add  t1, t1, a5
    addi t4, t4, 1
    blt  t4, a6, _RENDER_TILE_ROW
_RENDER_TILE_RET:
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
    lh   t1, 0(t0)
    srli s5, t1, TILE_W_SHIFT
    andi s6, t1, TILE_OFFSET_MASK
    lh   t1, 2(t0)
    srli s7, t1, TILE_H_SHIFT
    andi t2, t1, TILE_OFFSET_MASK

    sub  s11, zero, t2
_RENDER_MAPA_ROW:
    bge  s7, s3, _RENDER_MAPA_DONE

    li   s8, 0
    sub  s10, zero, s6
    mul  t0, s7, s2
    add  t0, t0, s5
    add  s9, s1, t0
_RENDER_MAPA_COL:
    add  t0, s5, s8
    bge  t0, s2, _RENDER_MAPA_NEXT_ROW

    mv   t2, s10
    li   t3, SCREEN_W
    bge  t2, t3, _RENDER_MAPA_NEXT_ROW

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
    blt  s8, t0, _RENDER_MAPA_COL

_RENDER_MAPA_NEXT_ROW:
    addi s7, s7, 1
    addi s11, s11, TILE_H
    li   t0, SCREEN_H
    blt  s11, t0, _RENDER_MAPA_ROW

_RENDER_MAPA_DONE:
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
