# ===========================================================================
# engine/camera.s - Camera e scroll
# ===========================================================================

.text

# CAMERA_UPDATE
# Atualiza BG_POS seguindo PLAYER_POSITION.
CAMERA_UPDATE:
    la t0, PLAYER_POSITION
    lh t1, 0(t0)
    lh t2, 2(t0)

    la t0, OLD_BG_POS
    la t3, BG_POS
    lh t4, 0(t3)
    sh t4, 0(t0)
    lh t4, 2(t3)
    sh t4, 2(t0)

    addi t1, t1, -160
    li t4, BG_X_MIN
    bge t1, t4, _CAMERA_UPDATE_X_MAX
    mv t1, t4

_CAMERA_UPDATE_X_MAX:
    li t4, TILE_W
    li t5, MAPA2_MAP_COLS
    mul t4, t4, t5
    addi t4, t4, -320
    ble t1, t4, _CAMERA_UPDATE_SAVE_X
    mv t1, t4

_CAMERA_UPDATE_SAVE_X:
    sh t1, 0(t3)

    addi t2, t2, -120
    li t4, BG_Y_MIN
    bge t2, t4, _CAMERA_UPDATE_Y_MAX
    mv t2, t4

_CAMERA_UPDATE_Y_MAX:
    li t4, BG_Y_MAX
    ble t2, t4, _CAMERA_UPDATE_SAVE_Y
    mv t2, t4

_CAMERA_UPDATE_SAVE_Y:
    sh t2, 2(t3)
    ret
