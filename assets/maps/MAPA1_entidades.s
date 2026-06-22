# Gerado automaticamente pelo RITMO em 2026-06-21 18:34
# Mapa: 32 colunas x 15 linhas, tile 16x16 pixels
# Prefixo: MAPA1

.eqv MAPA1_ENTITY_POSITION_SIZE_BYTES 2
.eqv MAPA1_NUM_ENTIDADES  3

.eqv MAPA1_PLAYER_COUNT 1
.eqv MAPA1_INIMIGO1_COUNT 2
.eqv MAPA1_INIMIGO2_COUNT 0

# .include "MAPA1_defs.s"

# Cada tabela abaixo guarda pares col,row para um tipo de entidade.
# Iteração típica:
#   la   t1, MAPA1_NOME_DA_ENTIDADE
#   li   t2, MAPA1_NOME_DA_ENTIDADE_COUNT
# loop_ent:
#   beqz t2, done_ent
#   lbu  t3, 0(t1)  # col
#   lbu  t4, 1(t1)  # row
#   addi t1, t1, MAPA1_ENTITY_POSITION_SIZE_BYTES
#   addi t2, t2, -1
#   j    loop_ent
# done_ent:

MAPA1_PLAYER: .byte
    1, 11

MAPA1_INIMIGO1: .byte
    10, 11,
    22, 11

# MAPA1_INIMIGO2: (nenhuma entidade definida)
