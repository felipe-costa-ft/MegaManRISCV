.data
CHAR_POS: .half 0,0
OLD_CHAR_POS: .half 0,0

.text
SETUP:
        # Desenha o fundo uma vez no início
        la a0,background
        li a1,0
        li a2,0
        li a3,0         # Mapa sempre desenhado no framebuffer 0
        call PRINT
        li a3,1
        call PRINT

GAME_LOOP:
        call KEY2        
        xori s0,s0,1   

        la t0,CHAR_POS

        # Alternar frame apenas para o personagem
        
        la a0,knight
        lh a1,0(t0)
        lh a2,2(t0)
        mv a3,s0        # Alternar frame para o personagem
        call PRINT

        # Atualizar LED (opcional)
        li t0,0xFF200604
        sw s0,0(t0)
        
        la t0,OLD_CHAR_POS

        la a0,tile
        lh a1,0(t0)
        lh a2,2(t0)
        
        mv a3,s0
        xori a3,a3,1      
        call PRINT
        
        j GAME_LOOP

KEY2:   li t1,0xFF200000    # Carrega o endereço de controle do KDMMIO
        lw t0,0(t1)         # Lê bit de controle do teclado
        andi t0,t0,0x0001  # Máscara para o bit menos significativo
        beq t0,zero,FIM    # Se não há tecla pressionada, pula para FIM
        lw t2,4(t1)         # Lê o valor da tecla pressionada

        li t0,'w'
        beq t2,t0,WALK_UP
        
        li t0,'a'
        beq t2,t0,WALK_LEFT

        li t0,'s'
        beq t2,t0,WALK_DOWN

        li t0,'d'
        beq t2,t0,WALK_RIGHT

FIM:    ret

WALK_LEFT: la t0,CHAR_POS
        la t1,OLD_CHAR_POS
        lw t2,0(t0)
        sw t2,0(t1)
        
        la t0,CHAR_POS
        lh t1,0(t0)
        addi t1,t1,-16     # Move 16 pixels à esquerda
        sh t1,0(t0)
        ret

WALK_RIGHT: la t0,CHAR_POS
        la t1,OLD_CHAR_POS
        lw t2,0(t0)
        sw t2,0(t1)

        la t0,CHAR_POS
        lh t1,0(t0)
        addi t1,t1,16      # Move 16 pixels à direita
        sh t1,0(t0)
        ret
        
WALK_UP: la t0,CHAR_POS
        la t1,OLD_CHAR_POS
        lw t2,0(t0)
        sw t2,0(t1)
        
        la t0,CHAR_POS
        lh t1,2(t0)
        addi t1,t1,-16     # Move 16 pixels à esquerda
        sh t1,2(t0)
        ret

WALK_DOWN: la t0,CHAR_POS
        la t1,OLD_CHAR_POS
        lw t2,0(t0)
        sw t2,0(t1)

        la t0,CHAR_POS
        lh t1,2(t0)
        addi t1,t1,16      # Move 16 pixels à direita
        sh t1,2(t0)
        ret

PRINT:
        li t0,0xFF0
        add t0,t0,a3       # Escolhe o framebuffer com base em a3
        slli t0,t0,20

        add t0,t0,a1       # Offset X

        li t1,320
        mul t1,t1,a2       # Offset Y
        add t0,t0,t1

        addi t1,a0,8       # Endereço inicial dos dados da imagem

        mv t2,zero          # Contador de linha
        mv t3,zero          # Contador de coluna

        lw t4,0(a0)         # Largura da imagem
        lw t5,4(a0)         # Altura da imagem

PRINT_LINHA:
        lw t6,0(t1)         # Lê pixel da imagem
        sw t6,0(t0)         # Escreve no framebuffer

        addi t0,t0,4       # Próximo pixel no framebuffer
        addi t1,t1,4       # Próximo pixel da imagem

        addi t3,t3,4       # Atualiza contador de coluna
        blt t3,t4,PRINT_LINHA

        addi t0,t0,320     # Próxima linha no framebuffer
        sub t0,t0,t4       # Ajusta para o início da linha

        mv t3,zero          # Reseta contador de coluna
        addi t2,t2,1       # Incrementa contador de linha
        blt t2,t5,PRINT_LINHA
        ret


.data
.include "../imagens/knight.data"
.include "../imagens/background.data"
.include "../imagens/tile.data"

