# ===========================================================================
# main.asm - Ponto de Entrada do Jogo Base
# ===========================================================================
.data

.include "consts.s"
.include "assets/tileset/tileset.data"
.include "assets/maps/MAPA1_defs.s"
.include "assets/maps/MAPA1_tileset_offsets.s"
.include "assets/maps/MAPA1_entidades.s"
.include "assets/maps/MAPA1_colisao.s"
.include "assets/maps/MAPA1_visual.s"
.include "assets/sprites/player/megaman_frames.data"


.eqv STATE_PLAYING   2

BG_POS:     .half 0, 0
OLD_BG_POS: .half 0, 0

.text

main:
        li s0, 0
        call PLAYER_SETUP

GAME_LOOP:

        call READ_INPUT
        call UPDATE_GAME
        call RENDER_FRAME
        call PRESENT_FRAME
        call SWAP_FRAMEBUFFER
        call WAIT_FRAME

        j GAME_LOOP

UPDATE_GAME:
        addi sp, sp, -4
        sw   ra, 0(sp)

        call PLAYER_UPDATE

        lw   ra, 0(sp)
        addi sp, sp, 4
        ret

RENDER_FRAME:
        addi sp, sp, -8
        sw ra, 0(sp)
        sw s2, 4(sp)


        # Calcula endereço do framebuffer
        li   s2, 0xFF0
        add  s2, s2, s0
        slli s2, s2, 20 # s2 = 0xFF000000 ou 0xFF100000 dependendo do framebuffer atual


        la a0, MAPA1_VISUAL
        li a1, MAPA1_MAP_COLS
        li a2, MAPA1_MAP_ROWS
        mv a3,s2
        call RENDER_MAPA

        mv a3, s2
        call PLAYER_RENDER


        lw s2, 4(sp)
        lw ra, 0(sp)
        addi sp, sp, 8
        ret

PRESENT_FRAME:
        li t0, 0xFF200604
        sw s0, 0(t0)
        ret

SWAP_FRAMEBUFFER:
        xori s0, s0, 1
        ret

WAIT_FRAME:
        li a7, 32               # Syscall: sleep
        li a0, 30
        ecall
        ret

# ===========================================================================
# Includes
# ===========================================================================
.include "engine/render.s"
.include "engine/input.s"
.include "utils.s"

.include "entities/player.s"
# .include "engine/physics.asm"
# .include "entities/player.asm"
