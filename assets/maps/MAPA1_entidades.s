# Gerado automaticamente pelo RITMO em 2026-07-10 16:31
# Mapa: 40 colunas x 30 linhas, tile 16x16 pixels
# Prefixo: MAPA1

.eqv MAPA1_ENTITY_POSITION_SIZE_BYTES MAPA_ENTITY_POSITION_SIZE_BYTES
.eqv MAPA1_NUM_ENTIDADES  11

.eqv MAPA1_PLAYER_COUNT 1
.eqv MAPA1_INIMIGO1_COUNT 5
.eqv MAPA1_INIMIGO2_COUNT 5

# .include "MAPA_defs.s"

# Cada tabela abaixo guarda pares col,row para um tipo de entidade.
# Iteração típica:
#   la   t1, MAPA1_NOME_DA_ENTIDADE
#   li   t2, MAPA1_NOME_DA_ENTIDADE_COUNT
# loop_ent:
#   beqz t2, done_ent
#   lbu  t3, 0(t1)  # col
#   lbu  t4, 1(t1)  # row
#   addi t1, t1, MAPA_ENTITY_POSITION_SIZE_BYTES
#   addi t2, t2, -1
#   j    loop_ent
# done_ent:

MAPA1_PLAYER: .byte
    2, 11

MAPA1_INIMIGO1: .byte
    10, 11,
    22, 11,
    4, 26,
    24, 26,
    34, 26

MAPA1_INIMIGO2: .byte
    12, 3,
    31, 4,
    16, 5,
    14, 7,
    26, 7
