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
.eqv INPUT_ENTER  0x80    # Enter - iniciar o jogo

.eqv KEYMAP_ADDR 0xFF200520

.eqv INPUT_KEYMAP_UNKNOWN 0
.eqv INPUT_KEYMAP_LINUX   1
.eqv INPUT_KEYMAP_MACOS   2
.eqv INPUT_KEYMAP_FPGA    3

# Scancodes FPGRARS/glutin para teclas fisicas.
# Se alguma tecla nao responder em outro ambiente, ajuste estes valores.
.eqv SC_W 17
.eqv SC_A 30
.eqv SC_S 31
.eqv SC_D 32
.eqv SC_J 36
.eqv SC_K 37
.eqv SC_L 38

# Scancodes observados em macOS para teclas ANSI.
# Usados como alternativa no mesmo keymap para manter input continuo.
.eqv SC_MAC_A 0
.eqv SC_MAC_S 1
.eqv SC_MAC_D 2
.eqv SC_MAC_W 13
.eqv SC_MAC_J 38
.eqv SC_MAC_K 40
.eqv SC_MAC_L 37

# Mascaras do keymap PS/2 da FPGA (RISCV-v24).
# O hardware sintetizado mapeia o bit pelo valor direto do scancode. Isso foi
# confirmado na placa: 0x1B aciona o bit 27, e nao o bit 26 descrito no PDF.
.eqv PS2_MASK_S 0x08000000  # 0x1B -> KEYMAP0 bit 27
.eqv PS2_MASK_A 0x10000000  # 0x1C -> KEYMAP0 bit 28
.eqv PS2_MASK_W 0x20000000  # 0x1D -> KEYMAP0 bit 29
.eqv PS2_MASK_D 0x00000008  # 0x23 -> KEYMAP1 bit 3
.eqv PS2_MASK_J 0x08000000  # 0x3B -> KEYMAP1 bit 27
.eqv PS2_MASK_K 0x00000004  # 0x42 -> KEYMAP2 bit 2
.eqv PS2_MASK_L 0x00000800  # 0x4B -> KEYMAP2 bit 11
# Enter 0x5A: aceita bit direto (26) e a variante deslocada (25) presente em
# revisoes da RISCV-v24. Nenhum dos dois bits e usado pelos controles do jogo.
.eqv PS2_MASK_ENTER 0x06000000

# ---------------------------------------------------------------------------
# Dados
# ---------------------------------------------------------------------------
.data
INPUT_FLAGS:
INPUT_CURRENT:       .word 0    # Teclas consideradas pressionadas neste frame
INPUT_PREVIOUS:      .word 0    # Estado do frame anterior
INPUT_PRESSED:       .word 0    # Bits que ligaram neste frame
INPUT_RELEASED:      .word 0    # Bits que desligaram neste frame
INPUT_KEYMAP_MODE:   .word INPUT_KEYMAP_UNKNOWN

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

        # O build fpga.s define gp=0 antes do main. Seleciona o KeyMap PS/2
        # diretamente no hardware, sem passar pela heuristica dos simuladores.
        beqz gp,READ_INPUT_FORCE_FPGA

        # O FPGRARS usa scancodes diferentes em Linux e macOS. K/Linux e
        # L/macOS, por exemplo, ocupam o mesmo bit, portanto os layouts nao
        # podem ser decodificados ao mesmo tempo. Detecta o backend por uma
        # tecla sem ambiguidade e guarda o resultado. Enquanto nenhuma delas
        # foi usada, Linux e o padrao.
        la t5,INPUT_KEYMAP_MODE
        lw t6,0(t5)
        bnez t6,READ_INPUT_DISPATCH

        # macOS: A/S/D, W e K ficam em bits exclusivos desse backend.
        lw t1,0(t0)
        andi t3,t1,0x07
        bnez t3,READ_INPUT_SELECT_MACOS
        lbu t1,1(t0)
        andi t3,t1,0x20
        bnez t3,READ_INPUT_SELECT_MACOS
        lbu t1,5(t0)
        andi t3,t1,0x01
        bnez t3,READ_INPUT_SELECT_MACOS
        lbu t1,4(t0)
        andi t3,t1,0x10      # Enter (ANSI 36)
        bnez t3,READ_INPUT_SELECT_MACOS

        # Linux: W, A/S/D e J tambem permitem identificar o backend.
        lbu t1,2(t0)
        andi t3,t1,0x02
        bnez t3,READ_INPUT_SELECT_LINUX
        lbu t1,3(t0)
        andi t3,t1,0xD0      # A, S, Enter
        bnez t3,READ_INPUT_SELECT_LINUX
        lbu t1,4(t0)
        andi t3,t1,0x11      # D, J
        bnez t3,READ_INPUT_SELECT_LINUX
        j READ_INPUT_LINUX

READ_INPUT_FORCE_FPGA:
        la t5,INPUT_KEYMAP_MODE
        li t6,INPUT_KEYMAP_FPGA
        sw t6,0(t5)
        j READ_INPUT_FPGA

READ_INPUT_SELECT_LINUX:
        li t6,INPUT_KEYMAP_LINUX
        sw t6,0(t5)
        j READ_INPUT_LINUX

READ_INPUT_SELECT_MACOS:
        li t6,INPUT_KEYMAP_MACOS
        sw t6,0(t5)
        j READ_INPUT_MACOS

READ_INPUT_DISPATCH:
        li t1,INPUT_KEYMAP_MACOS
        beq t6,t1,READ_INPUT_MACOS
        li t1,INPUT_KEYMAP_FPGA
        beq t6,t1,READ_INPUT_FPGA

READ_INPUT_LINUX:
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
        beqz t2,READ_INPUT_CHECK_ENTER
        ori t4,t4,INPUT_SWITCH

READ_INPUT_CHECK_ENTER:
        # Enter: scancode Linux 28 -> byte 3, bit 4
        lbu t1,3(t0)
        andi t2,t1,0x10
        beqz t2,READ_INPUT_STORE_CURRENT
        ori t4,t4,INPUT_ENTER
        j READ_INPUT_STORE_CURRENT

READ_INPUT_MACOS:
        # macOS: usa o mesmo keymap continuo, mas com scancodes ANSI.
        # Isso evita depender de repeticao de evento ASCII para movimento.
        lbu t1,0(t0)

        # A: scancode 0 -> byte 0, bit 0
        andi t2,t1,0x01
        beqz t2,READ_INPUT_CHECK_MAC_S
        ori t4,t4,INPUT_LEFT

READ_INPUT_CHECK_MAC_S:
        # S: scancode 1 -> byte 0, bit 1
        andi t2,t1,0x02
        beqz t2,READ_INPUT_CHECK_MAC_D
        ori t4,t4,INPUT_DOWN

READ_INPUT_CHECK_MAC_D:
        # D: scancode 2 -> byte 0, bit 2
        andi t2,t1,0x04
        beqz t2,READ_INPUT_CHECK_MAC_W
        ori t4,t4,INPUT_RIGHT

READ_INPUT_CHECK_MAC_W:
        # W: scancode 13 -> byte 1, bit 5
        lbu t1,1(t0)
        andi t2,t1,0x20
        beqz t2,READ_INPUT_CHECK_MAC_J
        ori t4,t4,INPUT_UP

READ_INPUT_CHECK_MAC_J:
        # J: scancode 38 -> byte 4, bit 6
        lbu t1,4(t0)
        andi t2,t1,0x40
        beqz t2,READ_INPUT_CHECK_MAC_K
        ori t4,t4,INPUT_SHOOT

READ_INPUT_CHECK_MAC_K:
        # K: scancode 40 -> byte 5, bit 0
        lbu t1,5(t0)
        andi t2,t1,0x01
        beqz t2,READ_INPUT_CHECK_MAC_L
        ori t4,t4,INPUT_JUMP

READ_INPUT_CHECK_MAC_L:
        # L: scancode 37 -> byte 4, bit 5
        lbu t1,4(t0)
        andi t2,t1,0x20
        beqz t2,READ_INPUT_CHECK_MAC_ENTER
        ori t4,t4,INPUT_SWITCH

READ_INPUT_CHECK_MAC_ENTER:
        # Enter: scancode ANSI 36 -> byte 4, bit 4
        andi t2,t1,0x10
        beqz t2,READ_INPUT_STORE_CURRENT
        ori t4,t4,INPUT_ENTER
        j READ_INPUT_STORE_CURRENT

READ_INPUT_FPGA:
        # FPGA PS/2: KeyMap0..3 guardam scancodes PS/2 em 128 bits.
        # Bits conforme RISCV-v24.pdf.
        lw t1,0(t0)          # KEYMAP0: scancodes 00 a 1F

        li t2,PS2_MASK_S
        and t3,t1,t2
        beqz t3,READ_INPUT_CHECK_PS2_A
        ori t4,t4,INPUT_DOWN

READ_INPUT_CHECK_PS2_A:
        li t2,PS2_MASK_A
        and t3,t1,t2
        beqz t3,READ_INPUT_CHECK_PS2_W
        ori t4,t4,INPUT_LEFT

READ_INPUT_CHECK_PS2_W:
        li t2,PS2_MASK_W
        and t3,t1,t2
        beqz t3,READ_INPUT_CHECK_PS2_D
        ori t4,t4,INPUT_UP

READ_INPUT_CHECK_PS2_D:
        lw t1,4(t0)          # KEYMAP1: scancodes 20 a 3F

        andi t3,t1,PS2_MASK_D
        beqz t3,READ_INPUT_CHECK_PS2_J
        ori t4,t4,INPUT_RIGHT

READ_INPUT_CHECK_PS2_J:
        li t2,PS2_MASK_J
        and t3,t1,t2
        beqz t3,READ_INPUT_CHECK_PS2_K
        ori t4,t4,INPUT_SHOOT

READ_INPUT_CHECK_PS2_K:
        lw t1,8(t0)          # KEYMAP2: scancodes 40 a 5F

        andi t3,t1,PS2_MASK_K
        beqz t3,READ_INPUT_CHECK_PS2_L
        ori t4,t4,INPUT_JUMP

READ_INPUT_CHECK_PS2_L:
        li t2,PS2_MASK_L
        and t3,t1,t2
        beqz t3,READ_INPUT_CHECK_PS2_ENTER
        ori t4,t4,INPUT_SWITCH

READ_INPUT_CHECK_PS2_ENTER:
        li t2,PS2_MASK_ENTER
        and t3,t1,t2
        beqz t3,READ_INPUT_STORE_CURRENT
        ori t4,t4,INPUT_ENTER

READ_INPUT_STORE_CURRENT:
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
