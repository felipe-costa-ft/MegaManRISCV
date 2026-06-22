# ===========================================================================
# engine/animation.s - Animacao generica
# ===========================================================================

.text

# ANIMATION_UPDATE
# a0 = endereco do contador de frame.
ANIMATION_UPDATE:
    lw t0, 0(a0)
    addi t0, t0, 1
    sw t0, 0(a0)
    ret

# ANIMATION_GET_FRAME_INDEX
# a0 = contador, a1 = shift de velocidade, a2 = total de frames
# retorna a0 = indice do frame
ANIMATION_GET_FRAME_INDEX:
    srl a0, a0, a1
    rem a0, a0, a2
    ret
