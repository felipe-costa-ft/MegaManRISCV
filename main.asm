.data

.include "imagens/felix.data"
.include "imagens/fundo.data"
.include "imagens/tile.data"
.include "imagens/telainicial.data"
.include "imagens/AndarPDireitaFelix.data"
.include "imagens/AndarPEsquerdaFelix.data"
.include "imagens/FelixOutroLado.data"
.include "imagens/FelixOutroLadoRebaixado.data"
.include "imagens/FelixRebaixado.data"

notas: .word 9, 0, 0, 67, 1000, 0, 74, 1000, 0, 70, 1500, 0, 69, 500, 0, 67, 500, 0, 70, 500, 0, 69, 500, 0, 67, 500, 0, 66, 500, 0,

CHAR_POS:     .half 30, 50
OLD_CHAR_POS: .half 30, 50       

FELIX_LARGURA: .half 24            
FELIX_ALTURA:  .half 36            

BG_POS:     .half 0, 0
OLD_BG_POS: .half 0, 0

BG_X_MIN:  .half 0
BG_X_MAX:  .half 5000
BG_Y_MIN:  .half 0
BG_Y_MAX:  .half 2000

FELIX_X_MIN: .half 0
FELIX_X_MAX: .half 304
FELIX_Y_MIN: .half 0
FELIX_Y_MAX: .half 224

FELIX_DIR:   .word 1
FELIX_FRAME: .word 0

VEL_Y:       .word 0
ESTA_NO_AR:  .word 1

NUM_BLOCOS:   .word 22
LISTA_BLOCOS:
    .half 12, 1200, 194, 326
    .half 196, 265, 178, 192
    .half 280, 370, 194, 255
    .half 385, 475, 178, 255
    .half 490, 770, 162, 255
    .half 785, 938, 178, 255
    .half 953, 1401, 194, 326
    .half 1395, 1422, 415, 572
    .half 1435, 1572, 443, 572
    .half 1587, 1882, 432, 572
    
    .half 1437, 1443, 2, 364
    .half 1480, 1485, 2, 380
    .half 1459, 1463, 2, 348
    .half 1501, 1505, 2, 348
    .half 1521, 1530, 2, 396

    .half 1547, 1591, 2, 364
    .half 1610, 1671, 2, 348
    .half 1709, 1734, 302, 317
    .half 1751, 1818, 302, 349
    .half 1835, 1881, 302, 381
    .half 1897, 1945, 128, 429

    .half 1377, 1380, 329, 412

.text

SETUP:
    la  a0, telainicial
    li  a1, 0          
    li  a2, 0          
    li  a3, 0          
    call PRINT         

KEY1:
    li  t1, 0xFF200000 
WAIT_KEY:
    li  a0, 10
    li  a7, 32
    ecall
    lw  t0, 0(t1)      
    andi t0, t0, 0x0001
    beq t0, zero, WAIT_KEY 
    lw  t2, 4(t1)      
    sw  t2, 12(t1)     

    la   a0, fundo     
    lh   a1, 0(a0)     
    li   a2, 0         
    li   a3, 0         
    call PRINT_BACKGROUND
    li   a3, 1         
    call PRINT_BACKGROUND

GAME_LOOP:
    la  t0, CHAR_POS   
    la  t1, OLD_CHAR_POS
    lw  t2, 0(t0)      
    sw  t2, 0(t1)      

    la  t0, BG_POS     
    la  t1, OLD_BG_POS 
    lw  t2, 0(t0)      
    sw  t2, 0(t1)      

    la  s1, notas      
    lw  s2, 0(s1)      
    lw  s3, 4(s1)      
    lw  s4, 8(s1)      
    li  t0, 12         
    mul s5, t0, s3     
    add s5, s5, s1     
    li  a7, 30         
    ecall              
    sub s6, a0, s4     
    lw  t1, 4(s5)      
    bgtu t1, s6, MF0   
    bne s3, s2, MF1    
    li  s3, 0          
    mv  s5, s1         
MF1:
    addi s5, s5, 12    
    li  a7, 31         
    lw  a0, 0(s5)      
    lw  a1, 4(s5)      
    li  a2, 0          
    li  a3, 60         
    ecall              
    li  a7, 30         
    ecall              
    sw  a0, 8(s1)      
    addi s3, s3, 1     
    sw  s3, 4(s1)      

MF0:
    la  t0, FELIX_FRAME
    lw  t1, 0(t0)      
    addi t1, t1, 1     
    sw  t1, 0(t0)      

    call SELECT_FELIX                 
    call KEY2                         
    call APLICAR_GRAVIDADE            
    call PROCESSAR_COLISOES_LATERAIS  

    xori s0, s0, 1     
    la  t0, CHAR_POS   
    lh  a1, 0(t0)      
    lh  a2, 2(t0)      
    mv  a3, s0         
    call PRINT         

    li   t0, 0xFF200604
    sw   s0, 0(t0)     

    la   t0, BG_POS    
    la   a0, fundo     
    lh   a1, 0(t0)     
    lh   a2, 2(t0)     
    mv   a3, s0         
    xori a3, a3, 1     
    call PRINT_BACKGROUND

    li a0, 30          
    li a7, 32          
    ecall              
    j GAME_LOOP        

KEY2:
    li  t1, 0xFF200000 
    lw  t0, 0(t1)      
    andi t0, t0, 0x0001
    beq  t0, zero, KEY2_CHECAR_AR 
    lw   t2, 4(t1)      
    j    KEY2_PROCESSA
KEY2_CHECAR_AR:
    la   t0, ESTA_NO_AR
    lw   t3, 0(t0)      
    bnez t3, KEY2_CONTINUO 
    j    KEY2_FIM
KEY2_CONTINUO:
    lw   t2, 4(t1)      
KEY2_PROCESSA:
    li  t0, 'a'
    beq t2, t0, MOVE_LEFT 
    li  t0, 'd'
    beq t2, t0, MOVE_RIGHT
    li  t0, 'w'
    beq t2, t0, MOVE_UP   
    li  t0, 's'
    beq t2, t0, MOVE_DOWN 
KEY2_FIM:
    ret

MOVE_LEFT:
    la  t0, FELIX_DIR  
    li  t1, 1          
    sw  t1, 0(t0)      
    la  t0, BG_POS     
    lh  t1, 0(t0)      
    la  t2, BG_X_MIN   
    lh  t2, 0(t2)      
    beq t1, t2, MOVE_LEFT_FELIX 
    la  t3, CHAR_POS   
    lh  t4, 0(t3)      
    li  t5, 30         
    bgt t4, t5, MOVE_LEFT_FELIX 
    addi t1, t1, -2    
    bge t1, t2, ML_BG_OK 
    mv  t1, t2
ML_BG_OK:
    sh  t1, 0(t0)      
    ret
MOVE_LEFT_FELIX:
    la  t3, CHAR_POS   
    lh  t4, 0(t3)      
    addi t4, t4, -2    
    la  t2, FELIX_X_MIN
    lh  t2, 0(t2)      
    bge t4, t2, ML_FX_OK 
    mv  t4, t2         
ML_FX_OK:
    sh  t4, 0(t3)      
    ret

MOVE_RIGHT:
    la  t0, FELIX_DIR  
    li  t1, 0          
    sw  t1, 0(t0)      
    la  t3, CHAR_POS   
    lh  t4, 0(t3)      
    li  t5, 274        
    blt t4, t5, MOVE_RIGHT_FELIX 
    la  t0, BG_POS     
    lh  t1, 0(t0)      
    la  t2, BG_X_MAX   
    lh  t2, 0(t2)      
    beq t1, t2, MOVE_RIGHT_FELIX 
    addi t1, t1, 2     
    ble t1, t2, MR_BG_OK 
    mv  t1, t2
MR_BG_OK:
    sh  t1, 0(t0)      
    ret
MOVE_RIGHT_FELIX:
    la  t3, CHAR_POS   
    lh  t4, 0(t3)      
    la  t0, BG_POS     
    lh  t1, 0(t0)      
    la  t2, BG_X_MAX   
    lh  t2, 0(t2)      
    beq t1, t2, MR_FX_LIMIT 
    li  t5, 274        
    blt t4, t5, MR_FX_CONTINUE 
    mv  t4, t5         
    j MR_FX_OK
MR_FX_LIMIT:
    la  t2, FELIX_X_MAX
    lh  t2, 0(t2)      
    blt t4, t2, MR_FX_CONTINUE
    mv  t4, t2         
    j MR_FX_OK
MR_FX_CONTINUE:
    addi t4, t4, 2     
MR_FX_OK:
    sh  t4, 0(t3)      
    ret

MOVE_UP:
    la  t0, ESTA_NO_AR 
    lw  t1, 0(t0)      
    bnez t1, FIM_MOVE_UP 
    li  t1, -10        
    la  t2, VEL_Y      
    sw  t1, 0(t2)      
    li  t1, 1          
    sw  t1, 0(t0)      
FIM_MOVE_UP:
    ret

MOVE_DOWN:
    la  t0, CHAR_POS   
    lh  t1, 2(t0)      
    li  t5, 180        
    blt t1, t5, MOVE_DOWN_FELIX
    la  t2, BG_POS     
    lh  t3, 2(t2)      
    la  t4, BG_Y_MAX   
    lh  t4, 0(t4)      
    beq t3, t4, MOVE_DOWN_FELIX
    addi t3, t3, 2     
    ble t3, t4, MD_BG_OK
    mv  t3, t4
MD_BG_OK:
    sh  t3, 2(t2)      
    ret
MOVE_DOWN_FELIX:
    addi t1, t1, 2     
    la  t2, FELIX_Y_MAX
    lh  t2, 0(t2)      
    ble t1, t2, MD_OK  
    mv  t1, t2         
MD_OK:
    sh  t1, 2(t0)      
    ret

APLICAR_GRAVIDADE:
    la  t0, CHAR_POS   
    lh  t1, 0(t0)      
    lh  t2, 2(t0)      
    
    la  s10, FELIX_LARGURA
    lh  s10, 0(s10)    
    add s11, t1, s10   
    
    la  s9, FELIX_ALTURA
    lh  s9, 0(s9)      
    add s10, t2, s9    

    la  t3, VEL_Y      
    lw  t4, 0(t3)      

    bgez t4, GRAVIDADE_DESCENDO
    li   t5, 40        
    bgt  t2, t5, GRAVIDADE_DESCENDO
    la   t6, BG_POS    
    lh   s2, 2(t6)     
    la   s3, BG_Y_MIN  
    lh   s3, 0(s3)     
    beq  s2, s3, GRAVIDADE_DESCENDO
    add  s2, s2, t4    
    bge  s2, s3, MV_BG_UP_OK
    mv   s2, s3
MV_BG_UP_OK:
    sh   s2, 2(t6)     
    j    CALC_GRAVIDADE

GRAVIDADE_DESCENDO:
    blez t4, CALC_TERRA
    li   t5, 180       
    blt  t2, t5, CALC_TERRA
    la   t6, BG_POS    
    lh   s2, 2(t6)     
    la   s3, BG_Y_MAX  
    lh   s3, 0(s3)     
    beq  s2, s3, CALC_TERRA
    add  s2, s2, t4    
    ble  s2, s3, MV_BG_DOWN_OK
    mv   s2, s3
MV_BG_DOWN_OK:
    sh   s2, 2(t6)     
    j    CALC_GRAVIDADE

CALC_TERRA:
    add t2, t2, t4     
    add s10, s10, t4   
    
CALC_GRAVIDADE:
    addi t4, t4, 1     
    li  t5, 6          
    ble t4, t5, SALVA_VEL 
    mv  t4, t5         
SALVA_VEL:
    sw  t4, 0(t3)      

    la  t5, BG_POS     
    lh   s2, 0(t5)      
    lh   s3, 2(t5)      

    la  t6, NUM_BLOCOS 
    lw  t6, 0(t6)      
    la  t3, LISTA_BLOCOS

LOOP_GRAV:
    beq t6, zero, CHAO_ABS 
    lh  a4, 0(t3)      
    lh  a5, 2(t3)      
    lh  a6, 4(t3)      
    lh  a7, 6(t3)      

    sub a4, a4, s2     
    sub a5, a5, s2     
    sub a6, a6, s3     
    sub a7, a7, s3     

    blt s11, a4, PROX_GRAV 
    bgt t1, a5, PROX_GRAV  

    lw  s7, VEL_Y      
    bge s7, zero, CHECK_CHAO_BLOCO 

    bgt t2, a7, PROX_GRAV  
    blt t2, a6, PROX_GRAV  
    
    mv  t2, a7         
    li  s7, 0          
    la  s8, VEL_Y      
    sw  s7, 0(s8)      
    j   FIM_GRAV

CHECK_CHAO_BLOCO:
    blt s10, a6, PROX_GRAV 
    addi s7, a6, 8         
    bgt s10, s7, PROX_GRAV 
    
    sub t2, a6, s9     
    li  s7, 0          
    la  s8, VEL_Y      
    sw  s7, 0(s8)      
    la  s8, ESTA_NO_AR 
    sw  zero, 0(s8)    
    j   FIM_GRAV       

PROX_GRAV:
    addi t3, t3, 8     
    addi t6, t6, -1    
    j LOOP_GRAV

CHAO_ABS:
    la  t5, FELIX_Y_MAX
    lh  t5, 0(t5)      
    blt t2, t5, MARCA_AR 
    mv  t2, t5         
    la  t4, VEL_Y      
    sw  zero, 0(t4)    
    la  t4, ESTA_NO_AR 
    sw  zero, 0(t4)    
    j   FIM_GRAV
MARCA_AR:
    li  t4, 1          
    la  t5, ESTA_NO_AR 
    sw  t4, 0(t5)      

FIM_GRAV:
    sh  t2, 2(t0)      
    ret

PROCESSAR_COLISOES_LATERAIS:
    la  t0, CHAR_POS   
    lh  t1, 0(t0)      
    lh  t2, 2(t0)      
    
    la  s9, FELIX_ALTURA
    lh  s9, 0(s9)      
    add s10, t2, s9    

    la  s11, FELIX_LARGURA
    lh  s11, 0(s11)    
    
    la  t3, OLD_CHAR_POS
    lh  t4, 0(t3)      

    la  t5, BG_POS     
    lh  s2, 0(t5)      
    lh  s4, 2(t5)      

    la  s5, OLD_BG_POS 
    lh  s3, 0(s5)      
    lh  s1, 2(s5)      

    la  t6, NUM_BLOCOS 
    lw  t6, 0(t6)      
    la  t3, LISTA_BLOCOS
LOOP_LAT:
    beq t6, zero, FIM_LAT 
    lh  a4, 0(t3)      
    lh  a5, 2(t3)      
    lh  a6, 4(t3)      
    lh  a7, 6(t3)      

    sub s7, a4, s3     
    sub s6, a5, s3     

    sub a4, a4, s2     
    sub a5, a5, s2     
    sub a6, a6, s4     
    sub a7, a7, s4     

    blt s10, a6, PROX_LAT 
    bgt t2, a7, PROX_LAT  

    add s5, t4, s11    
    ble s5, s7, CHECA_PAREDE_ESQ 

    bge t4, s6, CHECA_PAREDE_DIR
    j   PROX_LAT       

CHECA_PAREDE_ESQ:
    add s8, t1, s11    
    blt s8, a4, PROX_LAT 
    sub t1, a4, s11    
    j   PROX_LAT

CHECA_PAREDE_DIR:
    blt t1, a5, AJUSTA_PAREDE_DIR 
    j   PROX_LAT
AJUSTA_PAREDE_DIR:
    mv  t1, a5         

PROX_LAT:
    addi t3, t3, 8     
    addi t6, t6, -1    
    j   LOOP_LAT
FIM_LAT:
    sh  t1, 0(t0)      
    ret

SELECT_FELIX:
    la  t0, FELIX_DIR  
    lw  t0, 0(t0)      
    beq t0, zero, FELIX_RIGHT
    li  t1, 1          
    beq t0, t1, FELIX_LEFT
FELIX_RIGHT:
    la  t2, FELIX_FRAME
    lw  t0, 0(t2)      
    srli t0, t0, 2     
    andi t0, t0, 1     
    bnez t0, NOT_REBAIXADO 
    la   a0, FelixRebaixado 
    ret
NOT_REBAIXADO:
    la   a0, felix     
    ret
FELIX_LEFT:
    la  t2, FELIX_FRAME
    lw  t0, 0(t2)      
    srli t0, t0, 2     
    andi t0, t0, 1     
    bnez t0, NOT_REBAIXADO_LEFT
    la   a0, FelixOutroLadoRebaixado 
    ret
NOT_REBAIXADO_LEFT:
    la   a0, FelixOutroLado 
    ret

PRINT:
    li  t0, 0xFF0      
    add t0, t0, a3     
    slli t0, t0, 20    
    add t0, t0, a1     
    li  t1, 320        
    mul t1, t1, a2     
    add t0, t0, t1     
    addi t1, a0, 8     
    mv  t2, zero       
    mv  t3, zero       
    lw  t4, 0(a0)      
    lw  t5, 4(a0)      
PRINT_LINHA:
    lw  t6, 0(t1)      
    sw  t6, 0(t0)      
    addi t0, t0, 4     
    addi t1, t1, 4     
    addi t3, t3, 4     
    blt  t3, t4, PRINT_LINHA 
    addi t0, t0, 320   
    sub  t0, t0, t4     
    mv  t3, zero       
    addi t2, t2, 1     
    blt  t2, t5, PRINT_LINHA 
    ret

PRINT_BACKGROUND:
    li   t0, 0xFF0     
    add  t0, t0, a3    
    slli t0, t0, 20    
    addi t1, a0, 8     
    lw   t4, 0(a0)     
    
    la   t2, BG_POS    
    lh   t2, 2(t2)     
    
    mul  t2, t2, t4    
    add  t1, t1, t2    
    add  t1, t1, a1    
    li   t2, 0         
    li   t5, 240       
PRINT_BG_LINHA:
    li   t3, 0         
PRINT_BG_COLUNA:
    lw   t6, 0(t1)     
    sw   t6, 0(t0)     
    addi t0, t0, 4     
    addi t1, t1, 4     
    addi t3, t3, 4     
    li   t6, 320       
    blt  t3, t6, PRINT_BG_COLUNA 
    sub  t1, t1, t3    
    add  t1, t1, t4    
    addi t2, t2, 1     
    blt  t2, t5, PRINT_BG_LINHA 
    ret