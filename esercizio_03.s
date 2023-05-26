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
INOUT:      .half 0x0000                                # Inizializzo la halfword a 0.

ASCII:      .byte 0xc5, 0x42, 0x43, 0x44                # 32 Caratteri ASCII in esadecimale.
            .byte 0x45, 0x46, 0x47, 0x48
            .byte 0x49, 0x4A, 0x4B, 0x4C
            .byte 0x4D, 0x4E, 0x4F, 0x50
            .byte 0x51, 0x52, 0x53, 0x54
            .byte 0x55, 0x56, 0x57, 0x58
            .byte 0x59, 0x5A, 0x5B, 0x5C
            .byte 0x5D, 0x5E, 0x5F, 0x60

STACK_RA:   .word 0x00000000                            # Inizializzo la word a 0.

.text
                        la $s6 , STACK_RA               # Carico l'indirizzo della word STACK_RA in s6.
                        addi $a3, 32                    # Contatore dei byte.
            
READ_12:                lh $s1, INOUT                   # Carica l'indirizzo della halfword INOUT in s1.
                        andi $s2, $s1, 0x1000           # Controllo il livello della linea 12.
                        bne $s2, $zero, READ_12         # Se linea 12 != 0 ripeti ciclo.                                    
                                                       
READ_3:                 andi $a2, $s1, 0x0008           # Controllo bit linea 3, se bit acceso ritorna valore 8 (2^3).
                        jal CHECK_LOOP                  # Salta all'etichetta CHECK_LOOP salvando in $ra l'indirizzo di questa istruzione + 4.
            
READ_2:                 andi $s4, $s1, 0x0004           # Controllo bit linea 2, parità (0 = pari, 1 = dispari).                         
READ_14:                andi $s5, $s1, 0x4000           # Controllo bit linea 14.
READ_15:                andi $a0, $s1, 0x8000           # Controllo bit linea 15.
            
READ_ASCII:             la $s7 , ASCII                  # Carica l'indirizzo della label ASCII.
                        lb $t5, 0($s7)                  # Carico un byte (carattere ASCII).
                        addi $s7, 1                     # Incremento di 1 per spostarmi all'indirizzo del byte successivo.
                        addi $t4, 0x80                  # Aggiungo una maschera che controllerà lo stato dei bit dal + al - significativo.
                        addi $t3, 8                     # Inizializzo contatore dei bit per leggere un carattere ASCII.
                        move $t6, $zero                 # Inizializzo contatore a 0, per contare i bit a 1, serve x la parità.
            
READ_BIT:               and $t2, $t5 , $t4              # Confronto il registro contente il carattere ASCII con la maschera.
                        srl $t4, $t4, 1                 # Shifto la maschera di 1 e la sovrascrivo.
                        beq $t2 , $zero , CHECK_BIT     # se $t2 == 0, resetto la linea 12.
                        jal SET_LINE_12                 # Setto la linea 12 a 1.                   
                        jal CHECK_LOOP                  # Loop di attesa in base alla linea 3.
                        addi $t6, 1                     # Incremento di 1 il contatore della parità se bit = 1.
            
CHECK_BIT:              bne $t2 , $zero , END_CHECK_BIT # Se $t2 == 0 resetta linea 12, altrimenti salta a END_CHECK_BIT.
                        jal RESET_LINE_12               # Salto linkato al reset della linea 12.
                        jal CHECK_LOOP                  # Loop di attesa in base alla linea 3.

END_CHECK_BIT:          addi $t3, -1                    # Decremento contatore dei bit.
                        bne $t3 , $zero , READ_BIT      # Quando $t3 == 0 il carattere ASCII è stato letto completamente.

                        beq $s4, $zero, EVEN_PARITY     # Se la linea 2 è a 0, faccio la parità pari.
                        andi $t7, $t6, 0x1              # Controllo il bit meno significativo del contatore, se = 1 allora il numero di bit a 1 è dispari.
                        beq $t7, $zero, ODD             # Se $t7 = 0, mando sulla linea 12 un 1. 
                        jal RESET_LINE_12               # Se $t7 = 1, mando sulla linea 12 uno 0.
                        jal CHECK_LOOP                  # Loop di attesa in base alla linea 3.

ODD:                    bne $t7, $zero, EVEN_PARITY     # Se $t7 = 1, salta a EVEN_PARITY.
                        jal SET_LINE_12                 # Se $t7 = 0, setta la linea 12.
                        jal CHECK_LOOP                  # Loop di attesa in base alla linea 3.

EVEN_PARITY:            bne $s4, $zero, BIT_STOP        # Se ho fatto la parità dispari, salto a BIT_STOP.
                        andi $t7, $t6, 0x1              # Controllo il bit meno significativo del contatore, se = 1 allora il numero di bit a 1 è dispari.
                        beq $t7, $zero, EVEN            # Se $t7 = 0, mando sulla linea 12 uno 0.
                        jal SET_LINE_12                 # Se $t7 = 1, mando sulla linea 12 un 1.
                        jal CHECK_LOOP                  # Loop di attesa in base alla linea 3.

EVEN:                   bne $t7, $zero, BIT_STOP        # Se ho settato la linea 12, salto a BIT_STOP.
                        jal RESET_LINE_12               # Altrimenti resetto la linea 12.
                        jal CHECK_LOOP                  # Loop di attesa in base alla linea 3.

BIT_STOP:               beq $a2, $zero, CONTROL1        # Controllo la linea 3, se a 0 salto CONTROL_2 e faccio CONTROL_1.
                        jal RESET_LINE_12               # Setto a 0 il bit di stop.
                        jal CONTROL_2                   # Salto alla funzione che decide quanti LOOP_52 fare.
CONTROL1:               bne $a2, $zero, END_READ        # Se ho eseguito CONTROL_2 salto a END_READ.
                        jal RESET_LINE_12               # Setto a 0 il bit di stop.
                        jal CONTROL_1                   # Salto alla funzione che decide quanti LOOP_104 fare.

END_READ:               addi $a3, -1                    # Decremento il contatore dei caratteri ASCII.
                        bne $a3, $zero, READ_3          # Se il contatore != 0 significa che devo ancora finire di leggere.

                        addi $v1, 1                     # Debug,verifica che il programma abbia verificato tutti i 32 byte
END:                    j END                           # Loop infinito per terminare il programma.

SET_LINE_12:            la $t1 , INOUT                  # Carico l'indirizzo di INOUT in $t1.
                        ori $s3, $s1, 0x1000            # Setto a 1 il bit 12.                                                                   # 00000000 00000000   0001 0000 0000 0000 nomero 0x10000 mette a 1 il bit 12
                        sh $s3 , 0($t1)                 # Salvo in INOUT la halfword con il bit 12 a 1.                                          # 00000000 00000000   0111 0001 0000 0000 es INOUT
                        jr $ra                          # Torno alla funzione chiamante.

RESET_LINE_12:          la $t1 , INOUT                  # Carico l'indirizzo di INOUT in $t1.
                        andi $s3, $s1, 0xEFFF           # Setto a 0 il bit 12.                                                                   # 00000000 00000000   1110 1111 1111 1111 nomero 0xEFFF mette a zero il bit 12
                        sh $s3 , 0($t1)                 # Salvo in INOUT la halfword con il bit 12 a 0.                                          # 00000000 00000000   0111 0001 0000 0000 es INOUT
                        jr $ra                          # Torno alla funzione chiamante.

                                                        # LOOP_52 nel caso la trasmissione dei bit (LINEA 3) è a 1.
LOOP_52:                li $t0, 0x0008                  # 0x32C8
LOOP_52_1:              addi $t0, -1                    # Decremento $t0.
                        bne $t0, $zero, LOOP_52_1       # Loop per attesa, finché $t0 non arriva a 0.
                        jr $ra                          # Torno alla funzione chiamante.

                                                        # LOOP_104 nel caso la trasmissione dei bit (LINEA 3) è a 0.
LOOP_104:               li $t0, 0x000f                  # 0x6590 
LOOP_104_1:             addi $t0, -1                    # Decremento $t0.
                        bne $t0, $zero, LOOP_104_1      # Loop per attesa, finché $t0 non arriva a 0.
                        jr $ra                          # Torno alla funzione chiamante.
                                                        
                                                        # LOOP_26 per fare "mezzo" LOOP_52.
LOOP_26:                li $t0, 0x0004                  # 0x32C8
LOOP_26_1:              addi $t0, -1                    # Decremento $t0.
                        bne $t0, $zero, LOOP_26_1       # Loop per attesa, finché $t0 non arriva a 0.
                        jr $ra                          # Torno alla funzione chiamante.
            
CHECK_LOOP:             sw $ra , 0($s6)                 # Salvo l'indirizzo dell'istruzione attualmente in $ra in $s6 così da poterlo recuperare. 
                        beq $a2 , $zero , CHECK_1       # Se la linea 3 è a 0 faccio LOOP_104. 
                        jal LOOP_52                     # Se la linea 3 è a 1 faccio LOOP_52.
CHECK_1:                bne $a2 , $zero , OUT           # Se ho fatto LOOP_52 salto ad OUT.
                        jal LOOP_104                    # Salto a LOOP_104.
OUT:                    lw $ra , 0($s6)                 # Ricarico l'indirizzo dell'istruzione precedentemente contenuta in $ra.
                        jr $ra                          # Torno alla funzione chiamante.

CONTROL_1:              sw $ra , 0($s6)                 # Salvo l'indirizzo dell'istruzione attualmente in $ra in $s6 così da poterlo recuperare. 
                        beq $a0, $zero, LOOP_CHECK_LINE_14_A    # Se la linea 15 è a 0, eseguo LOOP_104 per 2 tempi, altrimenti controllo linea 14.
                        jal LOOP_104                    # Salto a LOOP_104.
                        jal LOOP_104                    # Salto a LOOP_104.
LOOP_CHECK_LINE_14_A:   bne $a0, $zero, END_CONTROL_1   # Se la linea 15 è a 1, esco dal loop.
                        beq $s5, $zero, LOOP_1_A        # Se la linea 14 è a 1, eseguo LOOP_104 per 1.5 tempi, altrimenti salto a LOOP_1_A.
                        jal LOOP_104                    # Salto a LOOP_104.
                        jal LOOP_52                     # Salto a LOOP_52.
LOOP_1_A:               bne $s5, $zero, END_CONTROL_1   # Se la linea 14 è a 0, eseguo LOOP_104 per 1 tempo.
                        jal LOOP_104                    # Salto a LOOP_104.
END_CONTROL_1:          lw $ra , 0($s6)                 # Ricarico l'indirizzo dell'istruzione precedentemente contenuta in $ra.
                        jr $ra                          # Torno alla funzione chiamante.

CONTROL_2:              sw $ra , 0($s6)                 # Salvo l'indirizzo dell'istruzione attualmente in $ra in $s6 così da poterlo recuperare. 
                        beq $a0, $zero, LOOP_CHECK_LINE_14_B    # Se la linea 15 è a 0, eseguo LOOP_52 per 2 tempi, altrimenti controllo linea 14.
                        jal LOOP_52                     # Salto a LOOP_52.
                        jal LOOP_52                     # Salto a LOOP_52.
LOOP_CHECK_LINE_14_B:   bne $a0, $zero, END_CONTROL_2   # Se la linea 15 è a 1, esco dal loop.
                        beq $s5, $zero, LOOP_1_B        # Se la linea 14 è a 1, eseguo LOOP_52 per 1.5 tempi, altrimenti salto a LOOP_1_B.
                        jal LOOP_52                     # Salto a LOOP_52.
                        jal LOOP_26                     # Salto a LOOP_26.
LOOP_1_B:               bne $s5, $zero, END_CONTROL_2   # Se la linea 14 è a 0, eseguo LOOP_52 per 1 tempo.
                        jal LOOP_52                     # Salto a LOOP_52.
END_CONTROL_2:          lw $ra , 0($s6)                 # Ricarico l'indirizzo dell'istruzione precedentemente contenuta in $ra.
                        jr $ra                          # Torno alla funzione chiamante.
