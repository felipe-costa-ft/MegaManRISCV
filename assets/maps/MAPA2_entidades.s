# Gerado automaticamente pelo RITMO em 2026-07-10 16:34
# Mapa: 40 colunas x 30 linhas, tile 16x16 pixels
# Prefixo: MAPA2

.eqv MAPA2_ENTITY_POSITION_SIZE_BYTES MAPA_ENTITY_POSITION_SIZE_BYTES
.eqv MAPA2_NUM_ENTIDADES  11

.eqv MAPA2_PLAYER_COUNT 1
.eqv MAPA2_INIMIGO1_COUNT 5
.eqv MAPA2_INIMIGO2_COUNT 5

# .include "MAPA_defs.s"

# Cada tabela abaixo guarda pares col,row para um tipo de entidade.
# Iteração típica:
#   la   t1, MAPA2_NOME_DA_ENTIDADE
#   li   t2, MAPA2_NOME_DA_ENTIDADE_COUNT
# loop_ent:
#   beqz t2, done_ent
#   lbu  t3, 0(t1)  # col
#   lbu  t4, 1(t1)  # row
#   addi t1, t1, MAPA_ENTITY_POSITION_SIZE_BYTES
#   addi t2, t2, -1
#   j    loop_ent
# done_ent:

MAPA2_PLAYER: .byte
    5, 11

MAPA2_INIMIGO1: .byte
    17, 11,
    31, 11,
    6, 25,
    15, 25,
    31, 25

MAPA2_INIMIGO2: .byte
    37, 5,
    26, 6,
    22, 8,
    29, 8,
    36, 9
