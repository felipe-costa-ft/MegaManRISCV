# Gerado automaticamente pelo RITMO em 2026-06-18 08:27
# Mapa: 32 colunas x 15 linhas, tile 16x16 pixels
# Prefixo: MAPA1

.eqv MAPA1_NUM_ENTIDADES  3
.eqv MAPA1_ENTIDADE_STRIDE 3

# .include "MAPA1_defs.s"

# Loop de iteração:
#   la   t1, MAPA1_ENTIDADES
#   li   t2, MAPA1_NUM_ENTIDADES
# loop_ent:
#   beqz t2, done_ent
#   lbu  t3, 0(t1)  # type_id
#   lbu  t4, 1(t1)  # col
#   lbu  t5, 2(t1)  # row
#   addi t1, t1, 3   # avança para próxima entidade
#   addi t2, t2, -1
#   j    loop_ent
# done_ent:

MAPA1_ENTIDADES: .byte
    1, 1, 11,
    2, 10, 11,
    2, 22, 11
