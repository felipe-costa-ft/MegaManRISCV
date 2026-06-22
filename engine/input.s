# ===========================================================================
# engine/input.asm - Sistema de Entrada do Teclado (Mega Man)
# ===========================================================================
# Lê teclas pressionadas via keymap do FPGRARS e armazena como bit flags.
# Keymap: 0xFF200520 (1 bit por scancode atualmente pressionado).
#
# Uso esperado no loop:
#   call READ_INPUT
#   # Depois, outras rotinas leem INPUT_CURRENT/INPUT_PRESSED/INPUT_RELEASED.
#
# Estados gerados:
#   INPUT_CURRENT  -> estado atual; use para movimento continuo.
#   INPUT_PRESSED  -> transicao 0->1; use para tiro, pulo, trocar arma.
#   INPUT_RELEASED -> transicao 1->0; use quando soltar tecla importar.
#
# Exemplo:
#   la   t0, INPUT_CURRENT
#   lw   t1, 0(t0)
#   andi t2, t1, INPUT_RIGHT
#   bnez t2, MOVE_RIGHT
# ===========================================================================

# ---------------------------------------------------------------------------
# Constantes de entrada - cada tecla é um bit único para permitir combinações
# ---------------------------------------------------------------------------
.eqv INPUT_LEFT   0x01    # Tecla 'a' - mover para esquerda
.eqv INPUT_RIGHT  0x02    # Tecla 'd' - mover para direita
.eqv INPUT_UP     0x04    # Tecla 'w' - olhar para cima / subir escada
.eqv INPUT_DOWN   0x08    # Tecla 's' - agachar / descer escada
.eqv INPUT_SHOOT  0x10    # Tecla 'j' - disparar
.eqv INPUT_JUMP   0x20    # Tecla 'k' - pular
.eqv INPUT_SWITCH 0x40    # Tecla 'l' - trocar arma

.eqv KEYMAP_ADDR 0xFF200520

# Scancodes FPGRARS/glutin para teclas fisicas.
# Se alguma tecla nao responder em outro ambiente, ajuste estes valores.
.eqv SC_W 17
.eqv SC_A 30
.eqv SC_S 31
.eqv SC_D 32
.eqv SC_J 36
.eqv SC_K 37
.eqv SC_L 38

# ---------------------------------------------------------------------------
# Dados
# ---------------------------------------------------------------------------
.data
INPUT_FLAGS:
INPUT_CURRENT:       .word 0    # Teclas consideradas pressionadas neste frame
INPUT_PREVIOUS:      .word 0    # Estado do frame anterior
INPUT_PRESSED:       .word 0    # Bits que ligaram neste frame
INPUT_RELEASED:      .word 0    # Bits que desligaram neste frame

.text

# ===========================================================================
# READ_INPUT - Lê o estado atual das teclas no keymap do FPGRARS
# ===========================================================================
# Argumentos: nenhum
# Retorno:
#   INPUT_CURRENT  = teclas pressionadas neste frame
#   INPUT_PRESSED  = bits que foram pressionados neste frame
#   INPUT_RELEASED = bits que foram soltos neste frame
#   INPUT_FLAGS    = alias de INPUT_CURRENT para compatibilidade
# Registradores usados: t0-t6
# Nota: função leaf, não precisa salvar ra na pilha
# ===========================================================================
READ_INPUT:
        # INPUT_PREVIOUS = INPUT_CURRENT
        la t0,INPUT_CURRENT
        lw t2,0(t0)
        la t0,INPUT_PREVIOUS
        sw t2,0(t0)

        li t0,KEYMAP_ADDR
        mv t4,zero          # t4 = INPUT_CURRENT calculado

        # W: scancode 17 -> byte 2, bit 1
        lbu t1,2(t0)
        andi t2,t1,0x02
        beqz t2,READ_INPUT_CHECK_A
        ori t4,t4,INPUT_UP

READ_INPUT_CHECK_A:
        # A: scancode 30 -> byte 3, bit 6
        lbu t1,3(t0)
        andi t2,t1,0x40
        beqz t2,READ_INPUT_CHECK_S
        ori t4,t4,INPUT_LEFT

READ_INPUT_CHECK_S:
        # S: scancode 31 -> byte 3, bit 7
        andi t2,t1,0x80
        beqz t2,READ_INPUT_CHECK_D
        ori t4,t4,INPUT_DOWN

READ_INPUT_CHECK_D:
        # D: scancode 32 -> byte 4, bit 0
        lbu t1,4(t0)
        andi t2,t1,0x01
        beqz t2,READ_INPUT_CHECK_J
        ori t4,t4,INPUT_RIGHT

READ_INPUT_CHECK_J:
        # J: scancode 36 -> byte 4, bit 4
        andi t2,t1,0x10
        beqz t2,READ_INPUT_CHECK_K
        ori t4,t4,INPUT_SHOOT

READ_INPUT_CHECK_K:
        # K: scancode 37 -> byte 4, bit 5
        andi t2,t1,0x20
        beqz t2,READ_INPUT_CHECK_L
        ori t4,t4,INPUT_JUMP

READ_INPUT_CHECK_L:
        # L: scancode 38 -> byte 4, bit 6
        andi t2,t1,0x40
        beqz t2,READ_INPUT_SAVE_CURRENT
        ori t4,t4,INPUT_SWITCH

READ_INPUT_SAVE_CURRENT:
        la t0,INPUT_CURRENT
        sw t4,0(t0)

        la t0,INPUT_PREVIOUS
        lw t2,0(t0)

        # INPUT_PRESSED = current & ~previous
        not t3,t2
        and t3,t4,t3
        la t0,INPUT_PRESSED
        sw t3,0(t0)

        # INPUT_RELEASED = previous & ~current
        not t3,t4
        and t3,t2,t3
        la t0,INPUT_RELEASED
        sw t3,0(t0)
        ret
