# Gerado automaticamente pelo RITMO em 2026-07-10 13:04
# Mapa: 40 colunas x 30 linhas, tile 16x16 pixels
# Prefixo: MAPA2

.eqv MAPA2_FLAT_ENTITY_SIZE_BYTES 3
.eqv MAPA2_FLAT_NUM_ENTIDADES  3
.eqv MAPA2_FLAT_ENTITY_FIELD_TYPE 0
.eqv MAPA2_FLAT_ENTITY_FIELD_COL  1
.eqv MAPA2_FLAT_ENTITY_FIELD_ROW  2

# .include "MAPA2_defs.s"

# Formato flat: cada entidade ocupa type,col,row.
# Iteração típica:
#   la   t1, MAPA2_ENTIDADES_FLAT
#   li   t2, MAPA2_FLAT_NUM_ENTIDADES
# loop_ent:
#   beqz t2, done_ent
#   lbu  t3, MAPA2_FLAT_ENTITY_FIELD_TYPE(t1)
#   lbu  t4, MAPA2_FLAT_ENTITY_FIELD_COL(t1)
#   lbu  t5, MAPA2_FLAT_ENTITY_FIELD_ROW(t1)
#   addi t1, t1, MAPA2_FLAT_ENTITY_SIZE_BYTES
#   addi t2, t2, -1
#   j    loop_ent
# done_ent:

MAPA2_ENTIDADES_FLAT: .byte
    MAPA2_ENTITY_TYPE_PLAYER, 5, 11,
    MAPA2_ENTITY_TYPE_INIMIGO1, 17, 11,
    MAPA2_ENTITY_TYPE_INIMIGO1, 31, 25
