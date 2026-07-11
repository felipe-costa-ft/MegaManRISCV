# ===========================================================================
# hud.s - HUD (barra de vida)
# ===========================================================================

.text

# HUD_RENDER
# Desenha a barra de vida no canto superior esquerdo, empilhando um
# segmento (HUD_SPRITE_LIFEBAR) por ponto de vida atual do player.
# a3 = endereco base do framebuffer
HUD_RENDER:
    addi sp, sp, -20
    sw   ra, 0(sp)
    sw   s1, 4(sp)
    sw   s2, 8(sp)
    sw   s3, 12(sp)
    sw   s4, 16(sp)

    mv   s4, a3

    la   t0, PLAYER_HP
    lbu  s1, 0(t0)

    li   s2, HUD_LIFEBAR_X
    li   s3, HUD_LIFEBAR_Y

_HUD_RENDER_LOOP:
    beqz s1, _HUD_RENDER_DONE

    la   a0, HUD_SPRITE_LIFEBAR
    mv   a1, s2
    mv   a2, s3
    mv   a3, s4
    li   a4, 0
    call PRINT

    addi s3, s3, HUD_LIFEBAR_SEG_H
    addi s1, s1, -1
    j _HUD_RENDER_LOOP

_HUD_RENDER_DONE:
    mv   a3, s4
    call HUD_RENDER_ENERGY

    lw   s4, 16(sp)
    lw   s3, 12(sp)
    lw   s2, 8(sp)
    lw   s1, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 20
    ret


# HUD_RENDER_ENERGY
# Renderiza a energia ao lado da vida, recolorindo pixels nao pretos de azul.
# a3 = endereco base do framebuffer
HUD_RENDER_ENERGY:
    la   t0, PLAYER_MP
    lbu  a0, 0(t0)              # segmentos restantes
    li   a1, HUD_ENERGYBAR_X
    li   a2, HUD_LIFEBAR_Y

_HUD_RENDER_ENERGY_SEGMENT_LOOP:
    beqz a0, _HUD_RENDER_ENERGY_DONE

    la   t0, HUD_SPRITE_LIFEBAR
    lw   t5, 0(t0)              # largura
    lw   t6, 4(t0)              # altura
    addi t0, t0, IMG_HEADER_BYTES

    li   t1, SCREEN_W
    mul  t1, t1, a2
    add  t1, t1, a1
    add  t1, t1, a3             # destino do segmento

    mv   t2, t6                 # linhas restantes

_HUD_RENDER_ENERGY_ROW:
    mv   t3, t5                 # colunas restantes
    mv   t4, t1                 # destino da linha

_HUD_RENDER_ENERGY_PIXEL:
    lbu  a4, 0(t0)
    beqz a4, _HUD_RENDER_ENERGY_PIXEL_STORE
    li   a4, HUD_ENERGY_COLOR

_HUD_RENDER_ENERGY_PIXEL_STORE:
    sb   a4, 0(t4)
    addi t0, t0, 1
    addi t4, t4, 1
    addi t3, t3, -1
    bnez t3, _HUD_RENDER_ENERGY_PIXEL

    li   t3, SCREEN_W
    add  t1, t1, t3
    addi t2, t2, -1
    bnez t2, _HUD_RENDER_ENERGY_ROW

    addi a2, a2, HUD_LIFEBAR_SEG_H
    addi a0, a0, -1
    j _HUD_RENDER_ENERGY_SEGMENT_LOOP

_HUD_RENDER_ENERGY_DONE:
    ret
