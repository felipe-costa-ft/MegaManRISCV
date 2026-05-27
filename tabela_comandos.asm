# OPERA��ES B�SICAS (N�MEROS INTEIROS)
add x1, x2, x3        # x1 = x2 + x3
sub x1, x2, x3        # x1 = x2 - x3
rem x1, x2, x3        # x1 = x2 % x3
mul x1, x2, x3        # x1 = x2 * x3  (Multiplica��o)
div x1, x2, x3        # x1 = x2 / x3  (Divis�o)

# OPERAÇÕES LÓGICAS
and x1, x2, x3        # x1 = x2 & x3  (AND)
or x1, x2, x3         # x1 = x2 | x3  (OR)
xor x1, x2, x3        # x1 = x2 ^ x3  (XOR)
sll x1, x2, x3        # x1 = x2 << x3 (Shift � esquerda)
srl x1, x2, x3        # x1 = x2 >> x3 (Shift � direita)

# OPERA��ES DE COMPARA��O
beq x1, x2, label     # if (x1 == x2) pula pra label, se (x1 != x2) executa o que tem dentro
bne x1, x2, label     # if (x1 != x2) pula pra label, se (x1 == x2) executa o que tem dentro
slt x1, x2, x3        # x1 = (x2 < x3)?1:0  (x2 menor que x3? Se sim retorna 1: Se n�o 0)
blt x1, x2, label     # if (x1 < x2) pula pra label
bge x1, x2, label     # if (x1 >= x2) pula pra label

# CARREGAMENTO E ARMAZENAMENTO (usando byte)
li x1, 10             # x1 = 10 (valor imediato)
lb x1, 0(x2)          # x1 = Mem�ria[x2 + 0] (carrega 1 byte da mem�ria para x1)
sb x1, 0(x2)          # Mem�ria[x2 + 0] = x1 (armazena 1 byte de x1 na mem�ria)

# CONTROLE DE FLUXO
jal label             # Chama a fun��o e salva o endere�o de retorno em ra
jr ra                 # Retorna para a fun��o chamadora (usa o endere�o em ra)

# OUTRAS INSTRU��ES �TEIS
j label               # Desvia incondicionalmente para label
