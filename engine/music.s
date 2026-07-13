# Musica MIDI polifonica e nao bloqueante.
# Cabecalho: count, pausa_final_ms. Evento (8 bytes):
# delay_ms, duracao_ms, pitch, instrumento, volume, padding.
.data
MUSIC_CURRENT:   .word 0
MUSIC_INDEX:     .word 0
MUSIC_NEXT_TIME: .word 0

.text
# a0 = tabela da musica
MUSIC_SET_SONG:
    addi sp,sp,-8
    sw ra,0(sp)
    sw s1,4(sp)
    mv s1,a0
    la t0,MUSIC_CURRENT
    sw s1,0(t0)
    la t0,MUSIC_INDEX
    sw zero,0(t0)
    li a7,30
    ecall
    lhu t1,8(s1)
    add t1,a0,t1
    la t0,MUSIC_NEXT_TIME
    sw t1,0(t0)
    lw s1,4(sp)
    lw ra,0(sp)
    addi sp,sp,8
    ret

MUSIC_STOP:
    la t0,MUSIC_CURRENT
    sw zero,0(t0)
    ret

MUSIC_UPDATE:
    addi sp,sp,-16
    sw ra,0(sp)
    sw s1,4(sp)
    sw s2,8(sp)
    sw s3,12(sp)
    la t0,MUSIC_CURRENT
    lw s1,0(t0)
    beqz s1,_MUSIC_UPDATE_DONE
    la t0,MUSIC_INDEX
    lw s2,0(t0)
    la t0,MUSIC_NEXT_TIME
    lw s3,0(t0)

_MUSIC_UPDATE_DUE_LOOP:
    li a7,30
    ecall
    sub t0,a0,s3
    bltz t0,_MUSIC_UPDATE_SAVE

    slli t0,s2,3
    addi t0,t0,8
    add t0,s1,t0
    lbu a0,4(t0)
    lhu a1,2(t0)
    lbu a2,5(t0)
    lbu a3,6(t0)
    li a7,31
    ecall

    addi s2,s2,1
    lw t1,0(s1)
    blt s2,t1,_MUSIC_UPDATE_NEXT_EVENT
    li s2,0
    lw t1,4(s1)
    add s3,s3,t1
    lhu t1,8(s1)
    add s3,s3,t1
    j _MUSIC_UPDATE_DUE_LOOP

_MUSIC_UPDATE_NEXT_EVENT:
    slli t0,s2,3
    addi t0,t0,8
    add t0,s1,t0
    lhu t1,0(t0)
    add s3,s3,t1
    j _MUSIC_UPDATE_DUE_LOOP

_MUSIC_UPDATE_SAVE:
    la t0,MUSIC_INDEX
    sw s2,0(t0)
    la t0,MUSIC_NEXT_TIME
    sw s3,0(t0)
_MUSIC_UPDATE_DONE:
    lw s3,12(sp)
    lw s2,8(sp)
    lw s1,4(sp)
    lw ra,0(sp)
    addi sp,sp,16
    ret
