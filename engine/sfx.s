# SFX nao bloqueantes aproximados dos WAVs por sequencias MIDI.
# Formato: quantidade; depois trios (pitch, duracao_ms, instrumento).
.data
SFX_CURRENT: .word 0
SFX_INDEX:   .word 0
SFX_STARTED: .word 0
SFX_ENEMY_HIT: .word 9
 .word 44,40,10, 67,40,10, 60,40,10, 55,40,10, 51,40,10, 48,40,10, 53,40,10, 79,40,10, 28,80,10
SFX_ENEMY_SHOOT: .word 3
 .word 80,40,8, 77,40,8, 73,40,8
SFX_PLAYER_HIT: .word 8
 .word 65,40,10, 28,40,10, 31,40,10, 56,40,10, 52,40,10, 47,40,10, 58,40,10, 32,40,10
SFX_TIME_STOPPER: .word 10
 .word 47,80,4, 59,40,4, 96,80,4, 108,40,4, 96,80,4, 108,40,4, 96,80,4, 108,40,4, 96,80,4, 96,120,4
SFX_BUSTER: .word 5
 .word 71,30,8, 75,30,8, 83,30,8, 88,30,8, 28,30,8
SFX_DINK: .word 1
 .word 105,53,13

.text
SFX_PLAY:
 addi sp,sp,-8
 sw ra,0(sp)
 sw s1,4(sp)
 mv s1,a0
 la t0,SFX_CURRENT
 sw s1,0(t0)
 la t0,SFX_INDEX
 sw zero,0(t0)
 addi a0,s1,4
 call _SFX_PLAY_NOTE
 lw s1,4(sp)
 lw ra,0(sp)
 addi sp,sp,8
 ret

_SFX_PLAY_NOTE:
 addi sp,sp,-4
 sw ra,0(sp)
 lw a1,4(a0)
 lw a2,8(a0)
 lw a0,0(a0)
 li a3,100
 li a7,31
 ecall
 li a7,30
 ecall
 la t0,SFX_STARTED
 sw a0,0(t0)
 lw ra,0(sp)
 addi sp,sp,4
 ret

SFX_UPDATE:
 addi sp,sp,-12
 sw ra,0(sp)
 sw s1,4(sp)
 sw s2,8(sp)
 la t0,SFX_CURRENT
 lw s1,0(t0)
 beqz s1,_SFX_UPDATE_DONE
 la t0,SFX_INDEX
 lw s2,0(t0)
 li t1,12
 mul t1,s2,t1
 addi t1,t1,4
 add t1,s1,t1
 lw t2,4(t1)
 la t0,SFX_STARTED
 lw t3,0(t0)
 li a7,30
 ecall
 sub t3,a0,t3
 bltu t3,t2,_SFX_UPDATE_DONE
 addi s2,s2,1
 lw t2,0(s1)
 bge s2,t2,_SFX_UPDATE_STOP
 la t0,SFX_INDEX
 sw s2,0(t0)
 li t1,12
 mul t1,s2,t1
 addi t1,t1,4
 add a0,s1,t1
 call _SFX_PLAY_NOTE
 j _SFX_UPDATE_DONE
_SFX_UPDATE_STOP:
 la t0,SFX_CURRENT
 sw zero,0(t0)
_SFX_UPDATE_DONE:
 lw s2,8(sp)
 lw s1,4(sp)
 lw ra,0(sp)
 addi sp,sp,12
 ret
