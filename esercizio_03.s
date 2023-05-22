# Un sistema basato sul microprocessore MIPS R2000 (clock pari a 500 MHz) è incaricato della trasmissione seriale
# asincrona di una serie di caratteri ASCII memorizzati in un banco dell’area dati del sistema che funge 
# da buffer di trasmissione. In particolare, il programma di cui si richiede la scrittura deve permettere 
# di effettuare la trasmissione seriale asincrona mediante la linea 12 della cella di memoria INOUT. 
# Detta linea deve essere mantenuta al livello logico alto quando non ci sono dati da trasmettere, mentre, 
# quando un dato deve essere trasmesso, deve essere portata al livello logico basso per un tempo pari al tempo 
# concesso per la trasmissione di un bit. Successivamente devono essere trasmessi in sequenza i singoli bit 
# (dal più significativo al meno significativo), ciascuno con la durata riservata ai bit. Al termine della 
# trasmissione del carattere ASCII, dovrà essere spedita la parità del messaggio (pari o dispari) e lo stop 
# equivalente ad un livello logico alto per un tempo pari a 1 o 1.5 o 2 tempi di bit. 
# Dopo aver trasmesso il bit di stop, potrà aver luogo la trasmissione del prossimo carattere. 
# La linea 3 della cella di memoria a 16 bit INOUT fornisce l’informazione relativa alla velocità 
# di trasferimento: 0 = 9600 bit/s (104 μs per bit) 1 = 19200 bit/s (52 μs per bit). 
# La linea 2 della cella INOUT fornisce l’informazione relativa alla parità: 0 = parità pari; 
# 1 = parità dispari. Le linee 14 e 15 della cella INOUT forniscono l’informazione relativa alla 
# durata da associare al bit di stop: 00 = 1 tempo 01 = 1.5 tempi 10 o 11 = 2 tempi. 
# Il programma da scrivere dovrà prelevare 32 caratteri ASCII memorizzati nella zona di memoria adibita 
# a buffer di trasmissione e dovrà poi trasferirli serialmente. Alle celle di memoria sopra menzionate 
# si assegnino indirizzi arbitrari che cadano, però, nell’area dei dati dell’architettura MIPS. 
# Il programma deve essere assemblato, linkato e sottoposto a simulazione. Si faccia una stampa commentata 
# del sorgente del programma realizzato (corredata anche del relativo flow-chart).


.data     

INOUT:      .half 0x110c                    # halfword, per settare il valore devo fare (set value of), 
                                            # indirizzo della word(in vui è contenuta la halfword), successivamente aggiungere l'intero valore della nuova word
ASCII:      .byte 0xc5, 0x42, 0x43, 0x44
            .byte 0x45, 0x46, 0x47, 0x48
            .byte 0x49, 0x4A, 0x4B, 0x4C
            .byte 0x4D, 0x4E, 0x4F, 0x50
            .byte 0x51, 0x52, 0x53, 0x54
            .byte 0x55, 0x56, 0x57, 0x58
            .byte 0x59, 0x5A, 0x5B, 0x5C
            .byte 0x5D, 0x5E, 0x5F, 0x60

STACK_RA:   .word 0x00000000

.text
                        la $s6 , STACK_RA
                        addi $a3, 32
            
READ_12:                lh $s1, INOUT                   # Loads halfword
                        andi $s2, $s1, 0x1000           # Checks linea 12, usiamo i valori in esadecimale
                        beq $s2, $zero, READ_12         # IF linea 12 != 0 ripeti ciclo                                    
                                                       
READ_3:                 andi $a2, $s1, 0x0008           # Controllo bit linea 3, se bit acceso ritorna valore 8 
                        jal CHECK_LOOP
            
READ_2:                 andi $s4, $s1, 0x0004            # Controllo bit linea 2                         
READ_14:                andi $s5, $s1, 0x4000            # Controllo bit linea 14
READ_15:                andi $a0, $s1, 0x8000            # Controllo bit linea 15
            
            
READ_ASCII:             la $s7 , ASCII                  # read address of ascii
                        lb $t5, 0($s7)                  # prendo il carattere asci
                        addi $s7, 1                     # incremento di 1 la posizione dell'indirizzo ascii
                        addi $t4, 0x80
                        addi $t3, 8                     # inizializzo contatore a 8, ciclo bit per codice ascii
                        move $t6, $zero                 # inizializzo contatore a 0, per contare bit = 1, bit di parità
            
            
READ_BIT:               and $t2, $t5 , $t4              # se $t2 !=0 significa che bisogna fare set 
                        srl $t4, $t4, 1
            
                        beq $t2 , $zero , CHECK_BIT         # se $s3 != 0 salta a CHECK 
                        jal SET_LINE_12                   # salto linkato a loop_52                   
                        jal CHECK_LOOP
                        addi $t6, 1                     # incremento di 1 se bit = 1
            
CHECK_BIT:              bne $t2 , $zero , GO     # se $s3 == 0 salta a LOOP_104 altrimenti viene saltato
                        jal RESET_LINE_12                    # salto linkato a loop_104
                        jal CHECK_LOOP

GO:                     addi $t3, -1
                        bne $t3 , $zero , READ_BIT

                        beq $s4, $zero, EVEN_PARITY     # salta se uguali, quindi salta se bit = 0, quindi parita' pari
                        andi $t7, $t6, 0x1              # controllo bit meno significativo del contatore, se = 1 allora il numero di bit=1 è dispari
                        beq $t7, $zero, ODD             # salta se uguali, quindi se $t7 = 0, allora ODD, dispari
                        jal RESET_LINE_12               # 
                        jal CHECK_LOOP

ODD:                    bne $t7, $zero, EVEN_PARITY     # salta se diversi, quindi 
                        jal SET_LINE_12
                        jal CHECK_LOOP

EVEN_PARITY:            bne $s4, $zero, BIT_STOP
                        andi $t7, $t6, 0x1
                        beq $t7, $zero, EVEN
                        jal SET_LINE_12
                        jal CHECK_LOOP

EVEN:                   bne $t7, $zero, BIT_STOP
                        jal RESET_LINE_12
                        jal CHECK_LOOP

BIT_STOP:               beq $a2, $zero, CONTROL1
                        jal RESET_LINE_12           # bit di stop lo setto a 0
                        jal CONTROL_2         
CONTROL1:               bne $a2, $zero, END_READ
                        jal RESET_LINE_12           # bit di stop lo setto a 0
                        jal CONTROL_1

END_READ:               addi $a3, -1
                        bne $a3, $zero, READ_3      # leggo 32 ascii, dopo finisco il programma

END:                    addi $v1, 1
                        j END

# functions

SET_LINE_12:            la $t1 , INOUT                   # $t1 contiene l'indirizzo di INOUT
                        ori $s3, $s1, 0x1000             # 00000000 00000000   0001 0000 0000 0000 nomero 0xEFFF mette a 1 il bit 12
                        sh $s3 , 0($t1)                  # 00000000 00000000   0111 0001 0000 0000 
                        jr $ra                   

RESET_LINE_12:          la $t1 , INOUT                   # $t1 contiene l'indirizzo di INOUT
                        andi $s3, $s1, 0xEFFF            # 00000000 00000000   1110 1111 1111 1111 nomero 0xEFFF mette a zero il bit 12
                        sh $s3 , 0($t1)                  # 00000000 00000000   0111 0001 0000 0000
                        jr $ra                  

                                             # LOOP_52 serve nel caso la trasmissione dei bit è settata a 1
LOOP_52:                li $t0, 0x0008                   # 0x32C8
LOOP_52_1:              addi $t0, -1    
                        bne $t0, $zero, LOOP_52_1
                        jr $ra      

                                             # LOOP_104 serve nel caso la trasmissione dei bit è settata a 0
LOOP_104:               li $t0, 0x000f                   # 0x6590 
LOOP_104_1:             addi $t0, -1    
                        bne $t0, $zero, LOOP_104_1
                        jr $ra  

LOOP_26:                li $t0, 0x0004                   # 0x32C8
LOOP_26_1:              addi $t0, -1    
                        bne $t0, $zero, LOOP_26_1
                        jr $ra      
            
CHECK_LOOP:             sw $ra , 0($s6)
                        beq $a2 , $zero , CHECK_1         # se $s3 != 0 salta a CHECK 
                        jal LOOP_52                       # salto linkato a loop_52
CHECK_1:                bne $a2 , $zero , OUT             # se $s3 == 0 salta a LOOP_104 altrimenti viene saltato
                        jal LOOP_104 
OUT:                    lw $ra , 0($s6)
                        jr $ra    

CONTROL_1:              sw $ra , 0($s6)
                        beq $a0, $zero, LOOP_CHECK_LINE_14_A
                        jal LOOP_104
                        jal LOOP_104
LOOP_CHECK_LINE_14_A:   bne $a0, $zero, END_CONTROL_1
                        beq $s5, $zero, LOOP_1_A
                        jal LOOP_104
                        jal LOOP_52        
LOOP_1_A:               bne $s5, $zero, END_CONTROL_1
                        jal LOOP_104               
END_CONTROL_1:          lw $ra , 0($s6)
                        jr $ra

CONTROL_2:              sw $ra , 0($s6)
                        beq $a0, $zero, LOOP_CHECK_LINE_14_B
                        jal LOOP_52
                        jal LOOP_52
LOOP_CHECK_LINE_14_B:   bne $a0, $zero, END_CONTROL_2
                        beq $s5, $zero, LOOP_1_B
                        jal LOOP_52
                        jal LOOP_26                  
LOOP_1_B:               bne $s5, $zero, END_CONTROL_2
                        jal LOOP_52                  
END_CONTROL_2:          lw $ra , 0($s6)
                        jr $ra
