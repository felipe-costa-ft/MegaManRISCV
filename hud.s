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
    lw   s4, 16(sp)
    lw   s3, 12(sp)
    lw   s2, 8(sp)
    lw   s1, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 20
    ret
