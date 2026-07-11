# ===========================================================================
# PLAYER STATE
# ===========================================================================

.eqv PLAYER_STATE_IDLE          0
.eqv PLAYER_STATE_ANDANDO       1
.eqv PLAYER_STATE_NO_AR         2
.eqv PLAYER_STATE_ATIRANDO      3
.eqv PLAYER_STATE_ATIRA_PULANDO 4
.eqv PLAYER_STATE_NA_ESCADA     5
.eqv PLAYER_STATE_ATIRA_ESCADA  6
.eqv PLAYER_STATE_KNOCKBACK     7


.eqv PLAYER_HP_MAX              10
.eqv PLAYER_MP_MAX              28

ESTA_INVULNERAVEL:      .word 0
INVULNERAVEL_TIMER:      .word 0
INVULNERAVEL_DURACAO:    .word 2000   # 2s piscando após o dano

KNOCKBACK_TIMER:         .word 0
KNOCKBACK_DURACAO:       .word 350    # 350ms travado, sendo empurrado
KNOCKBACK_VEL_X:         .word 0

.eqv KNOCKBACK_SPEED 2
.eqv FRAME_MS 30   # aproximacao do tempo por frame (ver WAIT_FRAME), usado para decrementar os timers acima





# ===========================================================================
# PLAYER ATTR
# ===========================================================================

.eqv PLAYER_LARGURA 24
.eqv PLAYER_ALTURA  24
.eqv PLAYER_HITBOX_OFFSET_X 4
.eqv PLAYER_HITBOX_LARGURA 16

.eqv PLAYER_SHOOT_DURATION 8
.eqv PLAYER_SHOTS_MAX      3
.eqv PLAYER_SHOT_SPEED     8
.eqv PLAYER_SHOT_W         8
.eqv PLAYER_SHOT_H         8

.eqv PLAYER_X_MIN 0
.eqv PLAYER_X_MAX 296
.eqv PLAYER_Y_MIN 0
.eqv PLAYER_Y_MAX 216


# ===========================================================================
# MAPA
# ===========================================================================

# Largura e altura de um tile em pixels
.eqv TILE_W 16
.eqv TILE_H 16

# Quantidade de shifts necessários para multiplicar pela largura e altura
.eqv TILE_W_SHIFT 4
.eqv TILE_H_SHIFT 4
.eqv TILE_OFFSET_MASK 15

.eqv TILESET_COLS 12
.eqv TILESET_W 192
.eqv SCREEN_W 320
.eqv SCREEN_H 240
.eqv IMG_HEADER_BYTES 8
.eqv MAP_VISIBLE_COLS 21
.eqv MAP_VISIBLE_ROWS 16

.eqv BG_X_MIN  0
.eqv BG_X_MAX  192
.eqv BG_Y_MIN  0
.eqv BG_Y_MAX  240

# ===========================================================================
# HUD
# ===========================================================================

.eqv HUD_LIFEBAR_X       8
.eqv HUD_LIFEBAR_Y       8
.eqv HUD_LIFEBAR_SEG_H   3
