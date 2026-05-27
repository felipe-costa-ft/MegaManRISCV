.data
#altura periodo e duração do#
notas: .word 9, 0, 0,
67, 1000, 0,
74, 1000, 0,
70, 1500, 0,
69, 500, 0,
67, 500, 0,
70, 500, 0,
69, 500, 0,
67, 500, 0,
66, 500, 0,

.text

start:

la s0, notas
lw s1, 0(s0) #quantas notas existem
lw s2, 4(s0) #em que nota eu estou
lw s3, 8(s0) #quand a ultima nota foi tocada do 6

li t0, 12
mul s4, t0, s2
add s4, s4, s0  #endereço da nota atual do 6

li a7, 30
ecall

sub s5, a0, s3 # quanto tempo já se passou desde que a última nota foi tocada

lw t1, 4(s4)
bgtu t1, s5, MF0 
        #se já for pra tocar a próxima nota do, 6
	
	bne s2, s1, MF1
		li s2, 0
		mv s4, s0
	MF1:
        addi s4, s4, 12

        li a7, 31
        lw a0, 0(s4)
        lw a1, 4(s4)
        li a2, 0
        li a3, 60
        ecall

        li a7, 30
        ecall

        sw a0, 8(s0)

        addi s2, s2, 1
        sw s2, 4(s0)
        
MF0:


li a7, 32
li a0, 10
ecall

jal start
