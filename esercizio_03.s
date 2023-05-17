.data        0x10005000     ##indirizzo di partenza della cella dei dati

INOUT:      .half 0x0000    ##halfword, per settare il valore devo fare (set value of), indirizzo della word(in vui è contenuta la halfword), successivamente aggiungere l'intero valore della nuova word


ASCII:      .byte 0x41, 0x42, 0x43, 0x44
            .byte 0x45, 0x46, 0x47, 0x48
            .byte 0x49, 0x4A, 0x4B, 0x4C
            .byte 0x4D, 0x4E, 0x4F, 0x50
            .byte 0x51, 0x52, 0x53, 0x54
            .byte 0x55, 0x56, 0x57, 0x58
            .byte 0x59, 0x5A, 0x5B, 0x5C            
            .byte 0x5D, 0x5E, 0x5F, 0x60

.text
MAIN:       addi $s0, 4096                ##la lui trasla il valore da inserire di 4 bit in avanti,la addi funziona bene per settare un determinato bit


START:      lh $s1, INOUT                 ## Loads halfword
            andi $s3, $s1, 0x00001000     ## Checks linea 12, uso i valori in binario per controllare un singolo bit, 0x per assegnare tutti i bit della word contenente INOUT a 0 tranne quello che voglio controllare
            beq $s3, $zero, START   ## IF linea 12 = 0 ripeti ciclo

            # Se la linea 12 è al livello logico basso devo capire
            # come prelevare dalla linea 3 il bit che ci dirà 
            # la velocità di trasmissione e quindi il tempo per il quale
            # il livello logico basso deve essere mantenuto.

            # Trasmissione dei bit del carattere ASCII
