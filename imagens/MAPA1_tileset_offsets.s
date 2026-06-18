# Gerado automaticamente pelo RITMO em 2026-06-18 08:27
# Mapa: 32 colunas x 15 linhas, tile 16x16 pixels
# Prefixo: MAPA1

# Offset (em bytes) do pixel superior-esquerdo de cada tile dentro
# da imagem do tileset (192px de largura, 1 byte/pixel).
# offset[i] = (i / MAPA1_TILESET_COLS) * 192 * MAPA1_TILE_H
#           + (i % MAPA1_TILESET_COLS) * MAPA1_TILE_W
#
# Lookup:
#   la   t1, MAPA1_TILESET_OFFSETS
#   slli t2, a0, 2          # a0 = tile_id
#   add  t1, t1, t2
#   lw   t1, 0(t1)          # offset em bytes no tileset

.eqv MAPA1_TILESET_COLS 12
.eqv MAPA1_TILESET_ROWS 10
.eqv MAPA1_NUM_TILES    120

MAPA1_TILESET_OFFSETS: .word
    0, 16, 32, 48, 64, 80, 96, 112,
    128, 144, 160, 176, 3072, 3088, 3104, 3120,
    3136, 3152, 3168, 3184, 3200, 3216, 3232, 3248,
    6144, 6160, 6176, 6192, 6208, 6224, 6240, 6256,
    6272, 6288, 6304, 6320, 9216, 9232, 9248, 9264,
    9280, 9296, 9312, 9328, 9344, 9360, 9376, 9392,
    12288, 12304, 12320, 12336, 12352, 12368, 12384, 12400,
    12416, 12432, 12448, 12464, 15360, 15376, 15392, 15408,
    15424, 15440, 15456, 15472, 15488, 15504, 15520, 15536,
    18432, 18448, 18464, 18480, 18496, 18512, 18528, 18544,
    18560, 18576, 18592, 18608, 21504, 21520, 21536, 21552,
    21568, 21584, 21600, 21616, 21632, 21648, 21664, 21680,
    24576, 24592, 24608, 24624, 24640, 24656, 24672, 24688,
    24704, 24720, 24736, 24752, 27648, 27664, 27680, 27696,
    27712, 27728, 27744, 27760, 27776, 27792, 27808, 27824
