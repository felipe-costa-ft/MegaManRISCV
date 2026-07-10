# ===========================================================================
# main.s - Ponto de entrada do jogo
# ===========================================================================
.data

.include "consts.s"
.include "assets/tileset/tileset.data"
.include "assets/maps/MAPA2_defs.s"
.include "assets/maps/MAPA2_tileset_offsets.s"
.include "assets/maps/MAPA2_entidades.s"
.include "assets/maps/MAPA2_colisao.s"
.include "assets/maps/MAPA2_visual.s"
.include "assets/sprites/player/megaman_frames.data"
.include "assets/sprites/player/shoot.data"
.include "assets/sprites/enemies/enemy1_frames.data"
.include "assets/sprites/misc/dead_frames.data"

BG_POS:     .half 0, 0
OLD_BG_POS: .half 0, 0

.text

main:
        li s0, 0
        call PLAYER_SETUP
        call ENEMY1_SETUP

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
        call ENEMY1_UPDATE
        call CAMERA_UPDATE

        lw   ra, 0(sp)
        addi sp, sp, 4
        ret

RENDER_FRAME:
        addi sp, sp, -8
        sw ra, 0(sp)
        sw s2, 4(sp)

        call GAME_GET_FRAMEBUFFER_ADDR
        mv s2, a0

        la a0, MAPA2_VISUAL
        li a1, MAPA2_MAP_COLS
        li a2, MAPA2_MAP_ROWS
        mv a3, s2
        call RENDER_MAPA

        mv a3, s2
        call PLAYER_RENDER

        mv a3, s2
        call ENEMY1_RENDER


        lw s2, 4(sp)
        lw ra, 0(sp)
        addi sp, sp, 8
        ret

# GAME_GET_FRAMEBUFFER_ADDR
# retorna a0 = endereco base do framebuffer atual.
GAME_GET_FRAMEBUFFER_ADDR:
        li   a0, 0xFF0
        add  a0, a0, s0
        slli a0, a0, 20
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
.include "engine/physics.s"
.include "engine/camera.s"
.include "engine/animation.s"
.include "utils.s"

.include "entities/player.s"
.include "entities/enemy1.s"
