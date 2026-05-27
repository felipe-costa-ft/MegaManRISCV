.data
# Número de Notas a tocar
NUM: .word 60
# Lista de nota, duração, nota, duração, ...
NOTAS: 55,234,57,234,60,351,55,234,55,234,57,117,60,234,57,234,64,117,64,234,64,351,62,469,64,234,62,234,64,234,55,234,57,234,60,351,55,234,55,234,57,117,60,234,57,234,64,117,64,234,65,351,62,938,62,117,64,117,64,938,57,234,64,234,64,234,62,234,64,351,60,117,67,117,64,117,60,117,64,117,60,117,64,117,60,117,67,117,60,117,64,117,60,117,62,117,64,117,64,234,62,351,57,351,64,234,64,117,62,234,64,234,65,351,65,351,67,234,69,938

.text

# Função PLAYMUSIC
.globl PLAYMUSIC
PLAYMUSIC:
    # Salva os registradores que serão usados na pilha
    addi sp, sp, -20      # Cria espaço na pilha
    sw s0, 0(sp)          # Salva s0
    sw s1, 4(sp)          # Salva s1
    sw t0, 8(sp)          # Salva t0
    sw a2, 12(sp)         # Salva a2
    sw a3, 16(sp)         # Salva a3

    la s0, NUM            # Define o endereço do número de notas
    lw s1, 0(s0)          # Lê o número de notas
    la s0, NOTAS          # Define o endereço das notas
    li t0, 0              # Zera o contador de notas
    li a2, 81             # Define o instrumento
    li a3, 127            # Define o volume

PLAYMUSIC_LOOP:
    beq t0, s1, PLAYMUSIC_FIM  # Se todas as notas foram tocadas, sai do loop
    lw a0, 0(s0)               # Lê o valor da nota
    lw a1, 4(s0)               # Lê a duração da nota
    li a7, 31                  # Define a syscall para tocar a nota
    ecall                      # Toca a nota
    mv a0, a1                  # Passa a duração da nota para a pausa
    li a7, 32                  # Define a syscall para a pausa
    ecall                      # Realiza uma pausa de a0 ms
    addi s0, s0, 8             # Incrementa para o endereço da próxima nota
    addi t0, t0, 1             # Incrementa o contador de notas
    j PLAYMUSIC_LOOP           # Volta ao loop

PLAYMUSIC_FIM:
    # Restaura os registradores da pilha
    lw s0, 0(sp)          # Restaura s0
    lw s1, 4(sp)          # Restaura s1
    lw t0, 8(sp)          # Restaura t0
    lw a2, 12(sp)         # Restaura a2
    lw a3, 16(sp)         # Restaura a3
    addi sp, sp, 20       # Libera o espaço na pilha

    jr ra                 # Retorna para a função chamadora
