.data
write:  .asciz "tile.data"
buffer: .space 50000

.text
main:
    la   s0, buffer   # endereço do buffer
    la   s1, buffer
    li   s2, 50000    # tamanho do buffer
 
    li a7, 1024
    la a0, write      # arquivo no qual será escrito ou criado
    li a1, 1          # modo de abertura (0: leitura, 1: escrita)
    ecall 
    mv s6, a0	  # guarda o resultado do system call em s6
    
    li s3, 48
    sb s3, 0(s1)   # s0[0] = 65 (valor numérico)
    
    addi s1, s1, 1 # s1 = s0[1]
    li s3, 44
    sb s3, 0(s1)   # s0[1] = 44 (valor numérico para a vírgula)
    
    addi s1, s1, 1 # s1 = s0[2]
    li s3, 50
    sb s3, 0(s1)   # s0[2] = 66 (valor numérico)
    
    li a7, 64       # system call para escrever ou criar arquivo
    mv a0, s6       # a0 = caminho do arquivo
    mv a1, s0 	# a1 = buffer com o conteúdo a ser escreito
    li a2, 3 	# a2 = tamanho da escrita do buffer (agora 3 bytes)
    ecall

    li a7, 57	# system call para fechar o arquivo
    mv a0, s0	# a0 = caminho do arquivo
    ecall