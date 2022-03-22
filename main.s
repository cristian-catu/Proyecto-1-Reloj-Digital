; Archivo: main.S
; Dispositivo: PIC16F887
; Autor: Cristian Catú
; Compilador: pic-as (v.30), MPLABX V5.40
;
; Programa: Proyecto 1 - Reloj Digital
; Hardware: displays de 7 segmentos, botones y leds
;
; Creado: 3 de marzo, 2022
; Última modificación: 20 de marzo, 2022

PROCESSOR 16F887
;----------------- bits de configuración --------------------
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  // config statements should precede project file includes.
#include <xc.inc>

; ------------------ VARIABLES EN MEMORIA -----------------------
PSECT udata_shr		    ; Memoria compartida
    display:            DS 4
    banderas:           DS 1
    estado:             DS 1
    minutos:            DS 4
    horas:              DS 4
    segundos:           DS 1
    
PSECT udata_bank0
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1
    estado_hora:        DS 1
    parpadeo:           DS 2
    dias:               DS 4
    meses:		DS 4
    estado_fecha:       DS 1
    segundos_timer:     DS 4
    minutos_timer:      DS 4
    estado_timer:       DS 1
    minutos_alarma:     DS 4
    horas_alarma:       DS 4    
    estado_alarma:      DS 1
    activar_alarma:     DS 1
    alarma_hora:        DS 1
    conteo_alarma_hora: DS 1
    activar_timer:      DS 1
    alarma_timer:       DS 1
    conteo_alarma_timer: DS 1
    bandera_tmr2:       DS 1
    puerto_e:           DS 1
    segundos_cronometro: DS 4
    minutos_cronometro: DS 4
    activar_cronometro: DS 1

; --------------------- VECTOR RESET ---------------------------    
PSECT resVect, class=CODE, abs, delta=2
ORG 00h ;posición 0000h para el reset
resetVec:
    PAGESEL main
    goto main

;-------------------- VECTOR INTERRUPCIONES --------------------
PSECT intVect, class=CODE, abs, delta=2
ORG 04h			    ; posición 0004h para interrupciones
PUSH:
    BANKSEL W_TEMP
    MOVWF   W_TEMP	    ; Se guarda W en una variable temporal
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	    ; Se guarda el STATUS en una variable temporal
ISR:
    BTFSC   T0IF	    ;Es la interrupcion de TMR0?
    CALL    INT_TMR0
    BTFSC   TMR1IF	    ;Es la interrupcion de TMR1?
    CALL    INT_TMR1
    BTFSC   TMR2IF	    ;Es la interrupcion de TMR2?
    CALL    INT_TMR2
    BTFSC RBIF              ;Es la interrupción del puerto B?
    CALL INT_IOCB
POP:
    BANKSEL STATUS_TEMP
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; Se recupera el valor de registro STATUS
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; Se recupera el valor de W
    RETFIE		    ; Se regresa al ciclo principal

; ------------------------ TABLA -------------------------------
PSECT code, delta=2, abs
ORG 100h ;posición para el código
tabla:
    CLRF    PCLATH		; Limpiamos registro PCLATH
    BSF	    PCLATH, 0		; Posicionamos el PC en dirección 02xxh
    ANDLW   0x0F    		; no saltar más del tamaño de la tabla
    ADDWF   PCL			; Apuntamos el PC a caracter en ASCII de CONT
    RETLW   00111111B			;display 0
    RETLW   00000110B			;display 1
    RETLW   01011011B			;display 2
    RETLW   01001111B			;display 3
    RETLW   01100110B           	;display 4
    RETLW   01101101B			;display 5
    RETLW   01111101B			;display 6
    RETLW   00000111B			;display 7
    RETLW   01111111B			;display 8
    RETLW   01101111B	                ;display 9
    RETLW   01110111B			;display 10

; ------ SUBRUTINAS DE INTERRUPCIONES ------    
INT_TMR0:
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   252
    MOVWF   TMR0	    ; 2ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    
    BANKSEL PORTD
    CLRF PORTD      
    BTFSC banderas, 1 ; se evalua la bandera para los estados, entonces se evalua si el bit 1 es cero o uno
    GOTO EVALUAR2
    GOTO EVALUAR1
    
EVALUAR1:                    ; si el bit es 0 ahora se evalua el bit 0
    BTFSC banderas, 0
    GOTO DISPLAY_1
    GOTO DISPLAY_0

EVALUAR2:                   ; si el bit es 1 ahora se evalua el bit 0
    BTFSC banderas, 0
    GOTO DISPLAY_3
    GOTO DISPLAY_2
    
DISPLAY_0:                  ; si es la combinación 00 se enciende el display 0
    MOVF display, W 
    MOVWF PORTC
    BSF PORTD, 3
    BSF banderas, 0        ; pasa a combinación 01
    BCF banderas, 1
    RETURN
DISPLAY_1:                 ; si es la combinación 01 se enciende el display 1
    MOVF display+1, W
    MOVWF PORTC
    BSF PORTD, 2
    BCF banderas, 0        ; pasa a combinación 10
    BSF banderas, 1
    RETURN
DISPLAY_2:                 ; si es la combinación 10 se enciende el display 2
    MOVF display+2, W
    MOVWF PORTC
    BSF PORTD, 1
    BSF banderas, 0        ; pasa combinación 11
    BSF banderas, 1
    RETURN
DISPLAY_3:                 ; si es la combinación 11 se enciende el display 3
    MOVF display+3, W
    MOVWF PORTC
    BSF PORTD, 0
    BCF banderas, 0        ; pasa combinación 00
    BCF banderas, 1
    RETURN

; ----------------    interrupción timer1     -------------------------
INT_TMR1: ; cada segundo
    BANKSEL TMR1H
    MOVLW   0x0B	    ; Literal a guardar en TMR1H
    MOVWF   TMR1H	    ; Guardamos literal en TMR1H
    MOVLW   0xDC	    ; Literal a guardar en TMR1L
    MOVWF   TMR1L	    ; Guardamos literal en TMR1L
    BCF	    TMR1IF	    ; Limpiamos bandera de int. TMR1
    INCF segundos
    
    MOVF segundos, W
    XORLW 60           ; se compara si segundos llegó a 60
    BTFSC STATUS, 2
    CALL SEGUNDOS_60
    
    MOVF minutos, W       
    XORLW 60           ; se compara si minutos llegó a 60
    BTFSC STATUS, 2
    CALL MINUTOS_60
    
    MOVF horas, W       
    XORLW 24           ; se compara si horas llegó a 24
    BTFSC STATUS, 2
    CALL HORAS_24
    
    BANKSEL activar_alarma        ;si la alarma está activa se compara la hora con el valor de la alarma
    BTFSC activar_alarma, 0
    CALL COMPARAR_ALARMA_MINUTOS
    
    BTFSC alarma_hora, 0          ;si la alarma está sonando se llama a una subrutina para contar a 60 y pararla
    CALL EVALUAR_ALARMA_HORA
    
    BTFSC activar_timer, 0      ;si el timer está activado se decrementa y se compara si se llega a 0
    CALL COMPARAR_TIMER
    
    BTFSC alarma_timer, 0       ;si la alarma del timer está sonando se va a una subrutina para contar a 60 y pararla
    CALL EVALUAR_ALARMA_TIMER
    
    BTFSC activar_cronometro, 0 ;si el cronómetro está activado se incrementa el cronometro
    CALL EVALUAR_CRONOMETRO
    
    BANKSEL meses          ; de aqui en adelante se evalua en que mes nos encontramos
    MOVF meses, W
    XORLW 1
    BTFSC STATUS, 2
    CALL ENERO
    
    MOVF meses, W
    XORLW 2
    BTFSC STATUS, 2
    CALL FEBRERO
    
    MOVF meses, W
    XORLW 3
    BTFSC STATUS, 2
    CALL MARZO
    
    MOVF meses, W
    XORLW 4
    BTFSC STATUS, 2
    CALL ABRIL
    
    MOVF meses, W
    XORLW 5
    BTFSC STATUS, 2
    CALL MAYO
    
    MOVF meses, W
    XORLW 6
    BTFSC STATUS, 2
    CALL JUNIO
    
    MOVF meses, W
    XORLW 7
    BTFSC STATUS, 2
    CALL JULIO
    
    MOVF meses, W
    XORLW 8
    BTFSC STATUS, 2
    CALL AGOSTO
    
    MOVF meses, W
    XORLW 9
    BTFSC STATUS, 2
    CALL SEPTIEMBRE
    
    MOVF meses, W
    XORLW 10
    BTFSC STATUS, 2
    CALL OCTUBRE
    
    MOVF meses, W
    XORLW 11
    BTFSC STATUS, 2
    CALL NOVIEMBRE
    
    MOVF meses, W
    XORLW 12
    BTFSC STATUS, 2
    CALL DICIEMBRE
    
    MOVF meses, W
    XORLW 13
    BTFSC STATUS, 2
    CALL MESES_13
    RETURN
    
; ------------- interrupción timer2 --------------------    
INT_TMR2: ;cada 250ms
    BTFSC parpadeo, 0     ; si la variable parpadeo está prendida, parpadeo+1 va alternando
    INCF parpadeo+1       ; esta variable sirve para parpadear los displays cuando se está editando
    BTFSC bandera_tmr2, 0 ; Existen dos estados en el timer 2
    GOTO ESTADO1_TMR2
    BSF bandera_tmr2, 0
    BCF	TMR2IF
    RETURN
ESTADO1_TMR2:
    INCF puerto_e        ;se incrementa el puerto E cada 500ms que es para mostrar los segundos
    BCF bandera_tmr2, 0
    BCF TMR2IF
    RETURN

; ---------------- Subrutinas para funcionamiento del modo TIMER ------------------
COMPARAR_TIMER:
    DECF segundos_timer    ; Si la bandera de timer está activada decrementamos los segundos del timer
    MOVF segundos_timer, W ;Comparamos si llegó a 255 para ponerlo en 59
    XORLW 255
    BTFSC STATUS, 2
    CALL SEGUNDOS_TIMER255
    
    MOVF minutos_timer, W ; Si minutos llegó a cero entonces analizamos si segundos llegó a cero también
    XORLW 0
    BTFSC STATUS, 2
    CALL VER_SEGUNDOS_TIMER
    MOVF minutos_timer, W ; Esto sucede cuando ponemos el timer en cero, si lo activamos
    XORLW 255             ; los minutos serán 255 entonces debemos apagarlo y activar la alarma
    BTFSC STATUS, 2
    CALL MINUTOS_TIMER255
    CALL TRANSFORMAR_SEGUNDOS_TIMER
    CALL TRANSFORMAR_MINUTOS_TIMER
    RETURN
SEGUNDOS_TIMER255:         ;Decrementamos los minutos y ponemos en 59 los segundos
    MOVLW 59
    MOVWF segundos_timer
    DECF minutos_timer
    RETURN
VER_SEGUNDOS_TIMER:
    MOVF segundos_timer, W  ;Si los segundos son cero entonces apagamos el timer y encendemos la alrma
    XORLW 0
    BTFSC STATUS, 2
    CALL RESET_TIMER
    RETURN
MINUTOS_TIMER255:
    CLRF segundos_timer
    CLRF minutos_timer
    BSF alarma_timer, 0
    BCF activar_timer, 0
    RETURN
RESET_TIMER:
    BSF alarma_timer, 0
    BCF activar_timer, 0
    RETURN

; ----------- subrutinas para funcionamiento de alarma del timer ------------
EVALUAR_ALARMA_TIMER:          ; Se cuenta hasta 60 para apagar la alarma que esta sonando
    INCF conteo_alarma_timer
    MOVF conteo_alarma_timer, W
    XORLW 60
    BTFSC STATUS, 2
    CALL RESET_ALARMA_TIMER
    RETURN
RESET_ALARMA_TIMER:       ; cuando llegamos a 60 apagamos la alarma y resetamos el contador
    CLRF conteo_alarma_timer
    BCF alarma_timer, 0
    RETURN
    
; -------------- subutinas para funcionamiento de alarma --------------
COMPARAR_ALARMA_MINUTOS: ; comparamos la alarma con la hora actual para activar la alarma
    MOVF minutos, W
    XORWF minutos_alarma, W
    BTFSC STATUS, 2
    CALL COMPARAR_ALARMA_HORAS
    RETURN
COMPARAR_ALARMA_HORAS:
    MOVF horas, W
    XORWF horas_alarma, W
    BTFSC STATUS, 2
    BSF alarma_hora, 0
    RETURN
    
; ----- subrutinas para funcionamiento de la alarma de la alarma ---------
EVALUAR_ALARMA_HORA:        ; es lo mismo que la alarma del timer
    INCF conteo_alarma_hora 
    MOVF conteo_alarma_hora, W
    XORLW 60
    BTFSC STATUS, 2
    CALL RESET_ALARMA_HORA
    RETURN
RESET_ALARMA_HORA:
    CLRF conteo_alarma_hora
    BCF alarma_hora, 0
    RETURN
    
; ------------ subrutinas para funcionamiento del crónometro ---------------
EVALUAR_CRONOMETRO:      ; Incrementamos los egundos y si llegamos a 60 incrementamos los minutos
    INCF segundos_cronometro
    MOVF segundos_cronometro, W
    XORLW 60
    BTFSC STATUS, 2
    CALL SEGUNDOS_CRONOMETRO_60
    CALL TRANSFORMAR_SEGUNDOS_CRONOMETRO
    CALL TRANSFORMAR_MINUTOS_CRONOMETRO
    RETURN
SEGUNDOS_CRONOMETRO_60:     ;si los minutos llegan a 100 entonces limpiamos los minutos y segundos del cronometro
    INCF minutos_cronometro
    CLRF segundos_cronometro
    MOVF minutos_cronometro, W
    XORLW 100
    BTFSC STATUS, 2
    CALL RESET_CRONOMETRO
    RETURN
RESET_CRONOMETRO:
    CLRF minutos_cronometro
    CLRF segundos_cronometro
    CALL TRANSFORMAR_SEGUNDOS_CRONOMETRO
    CALL TRANSFORMAR_MINUTOS_CRONOMETRO
    RETURN
    
; ------------------------- TRANSFORMACIONES A DECENAS Y UNIDADES ---------------------------------------------------------
TRANSFORMAR_MINUTOS:
    MOVF minutos, W       ; se pone minutos a la variable minutos+1 la cual nos servirá para irle restando
    MOVWF minutos+1       ; constantemente 10 e ir contando las decenas, y su valor restante dejarlo en unidades
    CLRF minutos+2
    CLRF minutos+3
    CALL DECENAS_MINUTOS    ; se obtienen las decenas
    MOVLW 10                ; se suma 10 a la variable minutos+1 por que el resultado anterior es negativo
    ADDWF minutos+1, F
    CALL UNIDADES_MINUTOS    ; se obtienen las unidades
    RETURN
DECENAS_MINUTOS:  
    MOVLW 10           ;se resta diez hasta que el número sea negativo o cero
    SUBWF minutos+1, W 
    MOVWF minutos+1
    BANKSEL STATUS
    BTFSS STATUS, 0 ; mientras sea positivo se sigue en la subrutina
    RETURN             ; si es negativo nos salimos
    INCF minutos+3, F   
    GOTO DECENAS_MINUTOS
UNIDADES_MINUTOS:
    MOVF minutos+1, W    ;el valor restante de minutos+1 se agrega a meses+2
    MOVWF minutos+2
    RETURN 

; DE AQUI EN ADELANTE SE REPITE LO MISMO PARA TODAS LAS VARIABLES
TRANSFORMAR_HORAS:
    MOVF horas, W
    MOVWF horas+1
    CLRF horas+2
    CLRF horas+3
    CALL DECENAS_HORAS
    MOVLW 10
    ADDWF horas+1, F
    CALL UNIDADES_HORAS
    RETURN

TRANSFORMAR_DIAS:
    MOVF dias, W
    MOVWF dias+1
    CLRF dias+2
    CLRF dias+3
    CALL DECENAS_DIAS
    MOVLW 10
    ADDWF dias+1, F
    CALL UNIDADES_DIAS
    RETURN

TRANSFORMAR_MESES:
    MOVF meses, W
    MOVWF meses+1
    CLRF meses+2
    CLRF meses+3
    CALL DECENAS_MESES
    MOVLW 10
    ADDWF meses+1, F
    CALL UNIDADES_MESES
    MOVF meses, W
    RETURN
    
TRANSFORMAR_MINUTOS_TIMER:
    MOVF minutos_timer, W
    MOVWF minutos_timer+1
    CLRF minutos_timer+2
    CLRF minutos_timer+3
    CALL DECENAS_MINUTOS_TIMER
    MOVLW 10
    ADDWF minutos_timer+1, F
    CALL UNIDADES_MINUTOS_TIMER
    MOVF minutos_timer, W
    RETURN
    
TRANSFORMAR_SEGUNDOS_TIMER:
    MOVF segundos_timer, W
    MOVWF segundos_timer+1
    CLRF segundos_timer+2
    CLRF segundos_timer+3
    CALL DECENAS_SEGUNDOS_TIMER
    MOVLW 10
    ADDWF segundos_timer+1, F
    CALL UNIDADES_SEGUNDOS_TIMER
    MOVF segundos_timer, W
    RETURN
    
TRANSFORMAR_MINUTOS_ALARMA:
    MOVF minutos_alarma, W
    MOVWF minutos_alarma+1
    CLRF minutos_alarma+2
    CLRF minutos_alarma+3
    CALL DECENAS_MINUTOS_ALARMA
    MOVLW 10
    ADDWF minutos_alarma+1, F
    CALL UNIDADES_MINUTOS_ALARMA
    MOVF minutos_alarma, W
    RETURN
    
TRANSFORMAR_HORAS_ALARMA:
    MOVF horas_alarma, W
    MOVWF horas_alarma+1
    CLRF horas_alarma+2
    CLRF horas_alarma+3
    CALL DECENAS_HORAS_ALARMA
    MOVLW 10
    ADDWF horas_alarma+1, F
    CALL UNIDADES_HORAS_ALARMA
    MOVF horas_alarma, W
    RETURN
    
TRANSFORMAR_MINUTOS_CRONOMETRO:
    MOVF minutos_cronometro, W
    MOVWF minutos_cronometro+1
    CLRF minutos_cronometro+2
    CLRF minutos_cronometro+3
    CALL DECENAS_MINUTOS_CRONOMETRO
    MOVLW 10
    ADDWF minutos_cronometro+1, F
    CALL UNIDADES_MINUTOS_CRONOMETRO
    MOVF minutos_cronometro, W
    RETURN
    
TRANSFORMAR_SEGUNDOS_CRONOMETRO:
    MOVF segundos_cronometro, W
    MOVWF segundos_cronometro+1
    CLRF segundos_cronometro+2
    CLRF segundos_cronometro+3
    CALL DECENAS_SEGUNDOS_CRONOMETRO
    MOVLW 10
    ADDWF segundos_cronometro+1, F
    CALL UNIDADES_SEGUNDOS_CRONOMETRO
    MOVF segundos_cronometro, W
    RETURN
   
DECENAS_MESES:
    MOVLW 10
    SUBWF meses+1, W 
    MOVWF meses+1
    BANKSEL STATUS
    BTFSS STATUS, 0 
    RETURN
    INCF meses+3, F   
    GOTO DECENAS_MESES
UNIDADES_MESES:
    MOVF meses+1, W
    MOVWF meses+2
    RETURN
    
DECENAS_DIAS:
    MOVLW 10
    SUBWF dias+1, W 
    MOVWF dias+1
    BANKSEL STATUS
    BTFSS STATUS, 0
    RETURN        
    INCF dias+3, F   
    GOTO DECENAS_DIAS
UNIDADES_DIAS:
    MOVF dias+1, W
    MOVWF dias+2
    RETURN
    
    
DECENAS_HORAS:  
    MOVLW 10
    SUBWF horas+1, W 
    MOVWF horas+1
    BANKSEL STATUS
    BTFSS STATUS, 0
    RETURN        
    INCF horas+3, F   
    GOTO DECENAS_HORAS
UNIDADES_HORAS:
    MOVF horas+1, W     
    MOVWF horas+2
    RETURN 
    
DECENAS_MINUTOS_TIMER:  
    MOVLW 10
    SUBWF minutos_timer+1, W 
    MOVWF minutos_timer+1
    BANKSEL STATUS
    BTFSS STATUS, 0
    RETURN        
    INCF minutos_timer+3, F   
    GOTO DECENAS_MINUTOS_TIMER
UNIDADES_MINUTOS_TIMER:
    MOVF minutos_timer+1, W     
    MOVWF minutos_timer+2
    RETURN 
    
DECENAS_SEGUNDOS_TIMER:  
    MOVLW 10
    SUBWF segundos_timer+1, W 
    MOVWF segundos_timer+1
    BANKSEL STATUS
    BTFSS STATUS, 0
    RETURN        
    INCF segundos_timer+3, F   
    GOTO DECENAS_SEGUNDOS_TIMER
UNIDADES_SEGUNDOS_TIMER:
    MOVF segundos_timer+1, W     
    MOVWF segundos_timer+2
    RETURN 
    
DECENAS_MINUTOS_ALARMA:  
    MOVLW 10
    SUBWF minutos_alarma+1, W 
    MOVWF minutos_alarma+1
    BANKSEL STATUS
    BTFSS STATUS, 0
    RETURN        
    INCF minutos_alarma+3, F   
    GOTO DECENAS_MINUTOS_ALARMA
UNIDADES_MINUTOS_ALARMA:
    MOVF minutos_alarma+1, W     
    MOVWF minutos_alarma+2
    RETURN
    
DECENAS_HORAS_ALARMA:  
    MOVLW 10
    SUBWF horas_alarma+1, W 
    MOVWF horas_alarma+1
    BANKSEL STATUS
    BTFSS STATUS, 0
    RETURN        
    INCF horas_alarma+3, F   
    GOTO DECENAS_HORAS_ALARMA
UNIDADES_HORAS_ALARMA:
    MOVF horas_alarma+1, W     
    MOVWF horas_alarma+2
    RETURN
    
DECENAS_MINUTOS_CRONOMETRO:  
    MOVLW 10
    SUBWF minutos_cronometro+1, W 
    MOVWF minutos_cronometro+1
    BANKSEL STATUS
    BTFSS STATUS, 0
    RETURN        
    INCF minutos_cronometro+3, F   
    GOTO DECENAS_MINUTOS_CRONOMETRO
UNIDADES_MINUTOS_CRONOMETRO:
    MOVF minutos_cronometro+1, W     
    MOVWF minutos_cronometro+2
    RETURN
    
DECENAS_SEGUNDOS_CRONOMETRO:  
    MOVLW 10
    SUBWF segundos_cronometro+1, W 
    MOVWF segundos_cronometro+1
    BANKSEL STATUS
    BTFSS STATUS, 0
    RETURN        
    INCF segundos_cronometro+3, F   
    GOTO DECENAS_SEGUNDOS_CRONOMETRO
UNIDADES_SEGUNDOS_CRONOMETRO:
    MOVF segundos_cronometro+1, W     
    MOVWF segundos_cronometro+2
    RETURN
    
; ------------- INTERRUPCIÓN IOCB ------------------
INT_IOCB:
    BTFSC estado, 2           ; se crearon cinco estados para los cinco modos, aqui se evaula en que estado estamos
    GOTO CRONOMETRO
    BTFSC estado, 1
    GOTO VERIFICAR_2
    GOTO VERIFICAR_1
    
VERIFICAR_1:
    BTFSC estado, 0
    GOTO FECHA     ;estado 2
    GOTO HORA    ;estado 1

VERIFICAR_2:
    BTFSC estado, 0
    GOTO TIMER      ;estado 3
    GOTO ALARMA       ;estado 4

; ------------------------- CÓDIGO DE HORA -----------------------------
HORA:
    BTFSS PORTB, 0	; Si se presionó botón de cambio de modo cambio mi bandera estado para pasar al siguiente
    BSF estado, 0
    CLRF PORTA
    BSF PORTA, 0        ; Señalo con el LED en que modo estoy
    BTFSC alarma_hora, 0 ; Evaluo si la alarma de la hora está sonando para la función del puerto RB4
    CALL VER_PUERTO_RB4
    BTFSC alarma_timer, 0 ; Lo mismo pero con la alarma del timer
    CALL VER_PUERTORB4
    BANKSEL estado_hora   ;Evaluo los sub-estados de la hora para editar o hacer nada
    BTFSC estado_hora, 1
    GOTO ESTADO3_HORA
    BTFSC estado_hora, 0
    GOTO ESTADO2_HORA
    GOTO ESTADO1_HORA
    
ESTADO1_HORA:
    BCF parpadeo, 0 ;Son las configuraciones si tengo que parpadear el led o los displays
    BSF parpadeo, 1
    BSF parpadeo+1, 0
    BTFSS PORTB, 3 ; Evaluo si cambio de sub-estado
    BSF estado_hora, 0
    BCF RBIF
    RETURN
ESTADO2_HORA:
    BSF parpadeo, 0
    BCF parpadeo, 1
    BTFSS PORTB, 3
    BSF estado_hora, 1
    BTFSS PORTB, 1          ;decremento o incremento minutos según el boton que presione
    INCF minutos
    BTFSS PORTB, 2
    DECF minutos
    
    MOVF minutos, W       
    XORLW 60           ; se compara si minutos llegó a 60
    BTFSC STATUS, 2
    CLRF minutos
    MOVF minutos, W
    XORLW 255      ; se compara si minutos es 255
    BTFSC STATUS, 2
    CALL MINUTOS_255
    CALL TRANSFORMAR_MINUTOS
    BCF RBIF
    RETURN
ESTADO3_HORA:
    BTFSS PORTB, 3
    CLRF estado_hora ; decremento o incremento las horas según el botón que presione
    BTFSS PORTB, 1           
    INCF horas
    BTFSS PORTB, 2
    DECF horas
    
    MOVF horas, W       
    XORLW 24           ; se compara si horas llegó a 24
    BTFSC STATUS, 2
    CLRF horas
    MOVF horas, W
    XORLW 255      ; se compara si es 255
    BTFSC STATUS, 2
    CALL HORAS_255
    CALL TRANSFORMAR_HORAS
    BCF RBIF
    RETURN

; ----------------------------- CÓDIGO DE FECHA -----------------------------
FECHA: ; se repite exactamente lo mismo que con la hora
    CLRF estado_hora
    BTFSS PORTB, 0	; Si se presionó botón de cambio de modo
    BSF estado, 1
    CLRF PORTA
    BSF PORTA, 1
    BCF parpadeo, 1
    BTFSC alarma_hora, 0
    CALL VER_PUERTO_RB4
    BTFSC alarma_timer, 0
    CALL VER_PUERTORB4
    BANKSEL estado_fecha
    BTFSC estado_fecha, 1
    GOTO ESTADO3_FECHA
    BTFSC estado_fecha, 0
    GOTO ESTADO2_FECHA
    GOTO ESTADO1_FECHA
    
ESTADO1_FECHA:
    BCF parpadeo, 0
    BSF parpadeo+1, 0
    BTFSS PORTB, 3
    BSF estado_fecha, 0
    BCF RBIF
    RETURN
ESTADO2_FECHA:
    BSF parpadeo, 0
    BTFSS PORTB, 3
    BSF estado_fecha, 1
    BTFSS PORTB, 1
    INCF dias
    BTFSS PORTB, 2
    DECF dias
    CALL MESES_Y_DIAS
    BCF RBIF
    CALL TRANSFORMAR_DIAS
    RETURN
ESTADO3_FECHA:
    BTFSS PORTB, 3
    CLRF estado_fecha
    BTFSS PORTB, 1
    INCF meses
    BTFSS PORTB, 2
    DECF meses
    CALL MESES_Y_DIAS
    BCF RBIF
    CALL TRANSFORMAR_MESES
    RETURN
    
MESES_Y_DIAS: ; dependiendo del mes, evaluamos los días para ver el límite
    BANKSEL meses
    MOVF meses, W
    XORLW 1
    BTFSC STATUS, 2
    CALL ENERO_EDICION
    
    MOVF meses, W
    XORLW 2
    BTFSC STATUS, 2
    CALL FEBRERO_EDICION
    
    MOVF meses, W
    XORLW 3
    BTFSC STATUS, 2
    CALL MARZO_EDICION
    
    MOVF meses, W
    XORLW 4
    BTFSC STATUS, 2
    CALL ABRIL_EDICION
    
    MOVF meses, W
    XORLW 5
    BTFSC STATUS, 2
    CALL MAYO_EDICION
    
    MOVF meses, W
    XORLW 6
    BTFSC STATUS, 2
    CALL JUNIO_EDICION
    
    MOVF meses, W
    XORLW 7
    BTFSC STATUS, 2
    CALL JULIO_EDICION
    
    MOVF meses, W
    XORLW 8
    BTFSC STATUS, 2
    CALL AGOSTO_EDICION
    
    MOVF meses, W
    XORLW 9
    BTFSC STATUS, 2
    CALL SEPTIEMBRE_EDICION
    
    MOVF meses, W
    XORLW 10
    BTFSC STATUS, 2
    CALL OCTUBRE_EDICION
    
    MOVF meses, W
    XORLW 11
    BTFSC STATUS, 2
    CALL NOVIEMBRE_EDICION
    
    MOVF meses, W
    XORLW 12
    BTFSC STATUS, 2
    CALL DICIEMBRE_EDICION
    
    MOVF meses, W
    XORLW 13
    BTFSC STATUS, 2
    CALL MESES_13
    
    MOVF meses, W
    XORLW 0
    BTFSC STATUS, 2
    CALL MESES_0
    RETURN

; ---------------------------- CÓDIGO DE TIMER ----------------------------
TIMER: ; el cambio de estados, y parpadeo funciona de manera similar
    CLRF estado_fecha
    BTFSS PORTB, 0	; Si se presionó botón de cambio de modo
    BCF estado, 0
    CLRF PORTA
    BSF PORTA, 2
    BANKSEL estado_timer
    BTFSC estado_timer, 1
    GOTO ESTADO3_TIMER
    BTFSC estado_timer, 0
    GOTO ESTADO2_TIMER
    GOTO ESTADO1_TIMER

ESTADO1_TIMER:
    BCF parpadeo, 0
    BSF parpadeo+1, 0
    BTFSS PORTB, 3
    BSF estado_timer, 0
    BTFSC alarma_hora, 0 ; RB4 tiene distinta funcionalidad si estamos con la alarma sonando
    GOTO ESTA_SONANDO
    BTFSC alarma_timer, 0
    GOTO ESTA_SONANDO2
    BTFSS PORTB, 4     ;activamos el timer si presionamos el RB4
    INCF activar_timer
    BCF RBIF
    RETURN
ESTADO2_TIMER:
    BSF parpadeo, 0
    BTFSS PORTB, 3
    BSF estado_timer, 1 ;decremento o incremento los segundos dependiendo del boton que presione
    BTFSS PORTB, 1
    INCF segundos_timer
    BTFSS PORTB, 2
    DECF segundos_timer
    MOVF segundos_timer, W       
    XORLW 60           ; se compara si los segundos llegaron a 60
    BTFSC STATUS, 2
    CLRF segundos_timer
    MOVF segundos_timer, W
    XORLW 255      ; se compara si los segundos son 255
    BTFSC STATUS, 2
    CALL SEGUNDOS_TIMER_255
    BTFSC alarma_hora, 0
    CALL VER_PUERTO_RB4
    BTFSC alarma_timer, 0
    CALL VER_PUERTORB4
    CALL TRANSFORMAR_SEGUNDOS_TIMER
    BCF RBIF
    RETURN
ESTADO3_TIMER:
    BTFSS PORTB, 3
    CLRF estado_timer ; decremento o incremento los minutos del timer dependiendo el boton
    BTFSS PORTB, 1
    INCF minutos_timer
    BTFSS PORTB, 2
    DECF minutos_timer
    
    MOVF minutos_timer, W       
    XORLW 100           ; se compara si minutos llegó a 60
    BTFSC STATUS, 2
    CLRF minutos_timer
    MOVF minutos_timer, W
    XORLW 255      ; se compara si minutos es 255
    BTFSC STATUS, 2
    CALL MINUTOS_TIMER_255
    BTFSC alarma_hora, 0
    CALL VER_PUERTO_RB4
    BTFSC alarma_timer, 0
    CALL VER_PUERTORB4
    CALL TRANSFORMAR_MINUTOS_TIMER
    BCF RBIF
    RETURN 
    
; ------------------------ CÓDIGO DE ALARMA ----------------------------
ALARMA: ;funciona muy similar al timer y a la hora
    CLRF estado_timer
    BTFSS PORTB, 0	; Si se presionó botón de cambio de modo
    BSF estado, 2
    CLRF PORTA
    BSF PORTA, 3
    
    BANKSEL estado_alarma
    BTFSC estado_alarma, 1
    GOTO ESTADO3_ALARMA
    BTFSC estado_alarma, 0
    GOTO ESTADO2_ALARMA
    GOTO ESTADO1_ALARMA

    
ESTADO1_ALARMA:
    BCF parpadeo, 0
    BSF parpadeo+1, 0
    BTFSS PORTB, 3
    BSF estado_alarma, 0
    BTFSS activar_alarma, 0
    BCF parpadeo, 1
    BTFSC activar_alarma, 0
    BSF parpadeo, 1
 
    BTFSC alarma_hora, 0
    GOTO ESTA_SONANDO
    BTFSC alarma_timer, 0
    GOTO ESTA_SONANDO2
    BTFSS PORTB, 4         ;Activamos la alarma con este boton
    INCF activar_alarma
    BCF RBIF
    RETURN
ESTA_SONANDO:
    BTFSS PORTB, 4
    CALL APAGAR_ALARMA_HORA 
    BCF RBIF
    RETURN
ESTA_SONANDO2:
    BTFSS PORTB, 4
    CALL APAGAR_ALARMA_TIMER 
    BCF RBIF
    RETURN
    
    
ESTADO2_ALARMA:
    BCF parpadeo, 1
    BSF parpadeo, 0
    BTFSS PORTB, 3
    BSF estado_alarma, 1
    BTFSS PORTB, 1
    INCF minutos_alarma
    BTFSS PORTB, 2
    DECF minutos_alarma
    
    MOVF minutos_alarma, W       
    XORLW 60           ; se compara si minutos llegó a 60
    BTFSC STATUS, 2
    CLRF minutos_alarma
    MOVF minutos_alarma, W
    XORLW 255      ; se compara si minutos es 255
    BTFSC STATUS, 2
    CALL MINUTOS_ALARMA_255
    CALL TRANSFORMAR_MINUTOS_ALARMA
    BTFSC alarma_hora, 0
    CALL VER_PUERTO_RB4
    BTFSC alarma_timer, 0
    CALL VER_PUERTORB4
    BCF RBIF
    RETURN
ESTADO3_ALARMA:
    BSF parpadeo, 0
    BTFSS PORTB, 3
    CLRF estado_alarma
    BTFSS PORTB, 1
    INCF horas_alarma
    BTFSS PORTB, 2
    DECF horas_alarma
    
    MOVF horas_alarma, W       
    XORLW 24           ; se compara si horas llegó a 24
    BTFSC STATUS, 2
    CLRF horas_alarma
    MOVF horas_alarma, W
    XORLW 255      ; se compara si horas es 255
    BTFSC STATUS, 2
    CALL HORAS_ALARMA_255
    CALL TRANSFORMAR_HORAS_ALARMA
    BTFSC alarma_hora, 0
    CALL VER_PUERTO_RB4
    BTFSC alarma_timer, 0
    CALL VER_PUERTORB4
    BCF RBIF
    RETURN

; ------------------ CODIGO CRONOMETRO -------------------------
CRONOMETRO: ; no hay sub estados en el cronoómetro ya que no hay que editar nada
    CLRF estado_alarma
    BTFSS PORTB, 0	; Si se presionó botón de cambio de modo
    CLRF estado
    CLRF PORTA
    BSF PORTA, 4
    BCF parpadeo, 1
    BTFSS PORTB, 3      ; reseteamos el cronometro si presionamos este botón
    CALL RESET_CRONOMETRO
    BTFSC alarma_hora, 0
    GOTO ESTA_SONANDO
    BTFSC alarma_timer, 0
    GOTO ESTA_SONANDO2
    BTFSS PORTB, 4       ; Activamos el cronometro si presionamos este boton
    INCF activar_cronometro
    BCF RBIF
    RETURN
; ----------------- EVALUAMOS LA ALARMA y EL LED PARA SEGUNDOS ----------------------
VER_ALARMA_TIMER:
    BTFSS alarma_timer, 0
    CALL APAGAR_LED
    BTFSC alarma_timer, 0
    CALL ENCENDER_LED
    RETURN
ALTERNAR_PUERTO_E:
    BTFSC puerto_e, 0
    BCF PORTE, 0
    BTFSS puerto_e, 0
    BSF PORTE, 0
    RETURN
APAGAR_LED:
    BANKSEL PORTA
    BCF PORTA, 5
    RETURN
ENCENDER_LED:
    BANKSEL PORTA
    BSF PORTA, 5
    RETURN
; ----------------------------- MAIN ---------------------------
main: ; llamamos a todas la configuraciones
    CALL CONFIG_IO
    CALL CONFIG_VARIABLES
    CALL CONFIG_RELOJ
    CALL CONFIG_TMR0
    CALL CONFIG_TMR1
    CALL CONFIG_TMR2
    CALL CONFIG_INT
LOOP:
    BANKSEL alarma_hora
    BTFSS alarma_hora, 0 ;vemos si la alarma de la hora o del timer están activadas
    CALL VER_ALARMA_TIMER
    BTFSC alarma_hora, 0 ;si están activadas las alarmas encendemos el LED
    CALL ENCENDER_LED
    BANKSEL parpadeo
    BTFSC parpadeo, 1    ;si esta activada la bandera de parpadeo se alterna el puerto E
    CALL ALTERNAR_PUERTO_E
    BTFSS parpadeo, 1
    BSF PORTE, 0
; -------------------------- ESTADOS LOOP ------------------------------
    BTFSC estado, 2  ; se comprueba en cual estado nos encontramos
    GOTO ESTADO5
    BTFSC estado, 1
    GOTO COMPROBAR_2
    GOTO COMPROBAR_1
    
COMPROBAR_1:                    ; si el bit es 0 ahora se evalua el bit 0
    BTFSC estado, 0
    GOTO ESTADO2     ;2
    GOTO ESTADO1    ;1

COMPROBAR_2:
    BTFSC estado, 0
    GOTO ESTADO3      ;3
    GOTO ESTADO4       ;4
; ---------------------- ESTADO 1 ---------------------------------------
ESTADO1:
    BANKSEL estado_hora ;se comprueba en cual sub estado nos encontramos para ver que display parpadear
    BTFSC estado_hora, 1
    GOTO ESTADO3_HORA_LOOP
    BTFSC estado_hora, 0
    GOTO ESTADO2_HORA_LOOP
    GOTO ESTADO1_HORA_LOOP

ESTADO1_HORA_LOOP:
    GOTO HORA_A_DISPLAY
    
ESTADO2_HORA_LOOP:
    BTFSC parpadeo+1, 0 ;este bit está parpadeando cada 250ms entonces pasamos a reset display1 y a hora display cada 250ms
    GOTO HORA_A_DISPLAY ; esto se debe a que estamos editando los minutos
    GOTO RESET_DISPLAY1

ESTADO3_HORA_LOOP:
    BTFSC parpadeo+1, 0 ; lo mismo con el display 2
    GOTO HORA_A_DISPLAY
    GOTO RESET_DISPLAY2

HORA_A_DISPLAY:
    BANKSEL minutos
    MOVF minutos+2, W
    CALL tabla
    MOVWF display
    MOVF minutos+3, W
    CALL tabla
    MOVWF display+1
    MOVF horas+2, W
    CALL tabla
    MOVWF display+2
    MOVF horas+3, W
    CALL tabla
    MOVWF display+3
    GOTO LOOP
RESET_DISPLAY1:
    CLRF display
    CLRF display+1
    GOTO LOOP
RESET_DISPLAY2:
    CLRF display+2
    CLRF display+3
    GOTO LOOP
; -------------------------- ESTADO 2 -------------------------------   
ESTADO2: ;todos los estados tienen la misma funcionalidad pero con sus variables respectivas
    BANKSEL estado_fecha
    BTFSC estado_fecha, 1
    GOTO ESTADO3_FECHA_LOOP
    BTFSC estado_fecha, 0
    GOTO ESTADO2_FECHA_LOOP
    GOTO ESTADO1_FECHA_LOOP

ESTADO1_FECHA_LOOP:
    GOTO FECHA_A_DISPLAY
ESTADO2_FECHA_LOOP:
    BTFSC parpadeo+1, 0
    GOTO FECHA_A_DISPLAY
    GOTO RESET_DISPLAY1
ESTADO3_FECHA_LOOP:
    BTFSC parpadeo+1, 0
    GOTO FECHA_A_DISPLAY
    GOTO RESET_DISPLAY2
    
FECHA_A_DISPLAY:
    BANKSEL dias
    MOVF dias+2, W
    CALL tabla
    MOVWF display
    MOVF dias+3, W
    CALL tabla
    MOVWF display+1
    MOVF meses+2, W
    CALL tabla
    MOVWF display+2
    MOVF meses+3, W
    CALL tabla
    MOVWF display+3
    GOTO LOOP
    
; ----------------- ESTADO 3 -------------------
ESTADO3:
    BANKSEL estado_timer
    BTFSC estado_timer, 1
    GOTO ESTADO3_TIMER_LOOP
    BTFSC estado_timer, 0
    GOTO ESTADO2_TIMER_LOOP
    GOTO ESTADO1_TIMER_LOOP

ESTADO1_TIMER_LOOP:
    GOTO TIMER_A_DISPLAY
ESTADO2_TIMER_LOOP:
    BTFSC parpadeo+1, 0
    GOTO TIMER_A_DISPLAY
    GOTO RESET_DISPLAY1
ESTADO3_TIMER_LOOP:
    BTFSC parpadeo+1, 0
    GOTO TIMER_A_DISPLAY
    GOTO RESET_DISPLAY2
    
TIMER_A_DISPLAY:
    BANKSEL segundos_timer
    MOVF segundos_timer+2, W
    CALL tabla
    MOVWF display
    MOVF segundos_timer+3, W
    CALL tabla
    MOVWF display+1
    MOVF minutos_timer+2, W
    CALL tabla
    MOVWF display+2
    MOVF minutos_timer+3, W
    CALL tabla
    MOVWF display+3
    GOTO LOOP    

; ---------------------- ESTADO 4 ---------------------
ESTADO4:
    BANKSEL estado_alarma
    BTFSC estado_alarma, 1
    GOTO ESTADO3_ALARMA_LOOP
    BTFSC estado_alarma, 0
    GOTO ESTADO2_ALARMA_LOOP
    GOTO ESTADO1_ALARMA_LOOP
    
ESTADO1_ALARMA_LOOP:
    GOTO ALARMA_A_DISPLAY
ESTADO2_ALARMA_LOOP:
    BTFSC parpadeo+1, 0
    GOTO ALARMA_A_DISPLAY
    GOTO RESET_DISPLAY1
ESTADO3_ALARMA_LOOP:
    BTFSC parpadeo+1, 0
    GOTO ALARMA_A_DISPLAY
    GOTO RESET_DISPLAY2
    
ALARMA_A_DISPLAY:
    BANKSEL minutos_alarma
    MOVF minutos_alarma+2, W
    CALL tabla
    MOVWF display
    MOVF minutos_alarma+3, W
    CALL tabla
    MOVWF display+1
    MOVF horas_alarma+2, W
    CALL tabla
    MOVWF display+2
    MOVF horas_alarma+3, W
    CALL tabla
    MOVWF display+3
    GOTO LOOP 
; --------------------- ESTADO 5 ----------------------------    
ESTADO5:
    BANKSEL segundos_cronometro
    MOVF segundos_cronometro+2, W
    CALL tabla
    MOVWF display
    MOVF segundos_cronometro+3, W
    CALL tabla
    MOVWF display+1
    MOVF minutos_cronometro+2, W
    CALL tabla
    MOVWF display+2
    MOVF minutos_cronometro+3, W
    CALL tabla
    MOVWF display+3
    GOTO LOOP
; -------------- CONFIGURACIONES ----------------------
CONFIG_IO:                    ; se configuran las entradas y salidas respectivas
    BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH
    
    BANKSEL TRISA
    BSF TRISB, 0
    BSF TRISB, 1
    BSF TRISB, 2
    BSF TRISB, 3
    BSF TRISB, 4
    CLRF TRISC
    CLRF TRISA
    BCF TRISD, 0
    BCF TRISD, 1
    BCF TRISD, 2
    BCF TRISD, 3
    BCF TRISE, 0
        
    BANKSEL OPTION_REG    ; Se configuran los pull up del puerto B
    BCF OPTION_REG, 7
    BANKSEL WPUB 
    BSF WPUB0
    BSF WPUB1
    BSF WPUB2
    BSF WPUB3
    BSF WPUB4
    
    BANKSEL PORTA
    CLRF PORTA
    CLRF PORTC
    BCF PORTD, 0
    BCF PORTD, 1
    BCF PORTD, 2
    BCF PORTD, 3
    BCF PORTE, 0
    RETURN
    
CONFIG_VARIABLES: ; ponemos valores inicales a cada variable
    BANKSEL dias ; para el uno de enero
    MOVLW 1
    MOVWF dias
    CALL TRANSFORMAR_DIAS
    MOVLW 1
    MOVWF meses
    CALL TRANSFORMAR_MESES
    CLRF segundos ; limpiamos el resto de variables
    CLRF horas
    CLRF minutos
    CLRF horas_alarma
    CLRF minutos_alarma
    CLRF segundos_cronometro
    CLRF minutos_cronometro
    CLRF segundos_timer
    CLRF minutos_timer
    CALL TRANSFORMAR_HORAS
    CALL TRANSFORMAR_MINUTOS
    CALL TRANSFORMAR_HORAS_ALARMA
    CALL TRANSFORMAR_MINUTOS_ALARMA
    CALL TRANSFORMAR_SEGUNDOS_CRONOMETRO
    CALL TRANSFORMAR_MINUTOS_CRONOMETRO
    CALL TRANSFORMAR_SEGUNDOS_TIMER
    CALL TRANSFORMAR_MINUTOS_TIMER
    BANKSEL parpadeo
    BSF parpadeo, 1
    CLRF estado
    CLRF estado_hora
    CLRF estado_fecha
    CLRF estado_timer
    CLRF estado_alarma
    CLRF activar_alarma
    CLRF alarma_hora
    CLRF conteo_alarma_hora
    CLRF activar_timer
    CLRF alarma_timer
    CLRF conteo_alarma_timer
    CLRF bandera_tmr2
    CLRF puerto_e
    CLRF activar_cronometro
    RETURN

CONFIG_RELOJ:
    BANKSEL OSCCON		; cambiamos a banco 1
    BSF	    OSCCON, 0		; SCS -> 1, Usamos reloj interno
    BCF	    OSCCON, 6
    BSF	    OSCCON, 5
    BSF	    OSCCON, 4		; IRCF<2:0> -> 011 500kHz
    RETURN    
    
CONFIG_TMR0:
    BANKSEL OPTION_REG	    ; cambiamos de banco
    BCF	    T0CS	    ; TMR0 como temporizador
    BCF	    PSA		    ; prescaler a TMR0
    BSF	    PS2
    BCF	    PS1
    BSF	    PS0		    ; PS<2:0> -> 111 prescaler 1 : 64
    
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   252
    MOVWF   TMR0	    ; 2ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    RETURN 
    
CONFIG_TMR1:
    BANKSEL T1CON	    ; Cambiamos a banco 00
    BCF	    TMR1CS	    ; Reloj interno
    BCF	    T1OSCEN	    ; Apagamos LP
    BCF	    T1CKPS1	    ; Prescaler 1:2
    BSF	    T1CKPS0
    BCF	    TMR1GE	    ; TMR1 siempre contando
    BSF	    TMR1ON	    ; Encendemos TMR1
    
    BANKSEL TMR1H           ; TMR1 a 1s
    MOVLW   0x0B
    MOVWF   TMR1H	    ; Guardamos literal en TMR1H
    MOVLW   0xDC
    MOVWF   TMR1L	    ; Guardamos literal en TMR1L   
    RETURN
    
CONFIG_TMR2:
    BANKSEL PR2		    ; Cambiamos a banco 01
    MOVLW   122		    ; Valor para interrupciones cada 250ms
    MOVWF   PR2		    ; Cargamos litaral a PR2
    
    BANKSEL T2CON	    ; Cambiamos a banco 00
    BSF	    T2CKPS1	    ; Prescaler 1:16
    BSF	    T2CKPS0
    
    BSF	    TOUTPS3	    ;Postscaler 1:16
    BSF	    TOUTPS2
    BSF	    TOUTPS1
    BSF	    TOUTPS0
    
    BSF	    TMR2ON	    ; Encendemos TMR2
    RETURN

CONFIG_INT:
    BANKSEL PIE1	    ; Cambiamos a banco 01
    BSF	    TMR1IE	    ; Habilitamos int. TMR1
    BSF	    TMR2IE	    ; Habilitamos int. TMR2
    
    BANKSEL INTCON	    ; Cambiamos a banco 00
    BSF	    PEIE	    ; Habilitamos int. perifericos
    BSF	    GIE		    ; Habilitamos int. globales
    BSF	    T0IE	    ; Habilitamos interrupcion TMR0
    BCF	    T0IF	    ; Limpiamos bandera de TMR0
    BCF	    TMR1IF	    ; Limpiamos bandera de TMR1
    BCF	    TMR2IF	    ; Limpiamos bandera de TMR2
    
    BANKSEL IOCB
    BSF IOCB0
    BSF IOCB1
    BSF IOCB2
    BSF IOCB3
    BSF IOCB4
    RETURN
    
; -------------------------------- MESES EN EDICIÓN -------------------------------------
ENERO_EDICION:
    MOVLW 32 ; para cada mes se evalua si se llegó al limite y volvemos resetear en cero
    SUBWF dias, W 
    BTFSC STATUS, 0
    CALL FIN_DE_MES
    MOVF dias, W
    XORLW 0
    BTFSC STATUS, 2
    CALL PONER_31
    RETURN
FEBRERO_EDICION:
    MOVLW 29
    SUBWF dias, W 
    BTFSC STATUS, 0
    CALL FIN_DE_MES
    MOVF dias, W
    XORLW 0
    BTFSC STATUS, 2
    CALL PONER_28
    RETURN
MARZO_EDICION:
    MOVLW 32
    SUBWF dias, W 
    BTFSC STATUS, 0
    CALL FIN_DE_MES
    MOVF dias, W
    XORLW 0
    BTFSC STATUS, 2
    CALL PONER_31
    RETURN
ABRIL_EDICION:
    MOVLW 31
    SUBWF dias, W 
    BTFSC STATUS, 0
    CALL FIN_DE_MES
    MOVF dias, W
    XORLW 0
    BTFSC STATUS, 2
    CALL PONER_30
    RETURN
MAYO_EDICION:
    MOVLW 32
    SUBWF dias, W 
    BTFSC STATUS, 0
    CALL FIN_DE_MES
    MOVF dias, W
    XORLW 0
    BTFSC STATUS, 2
    CALL PONER_31
    RETURN
JUNIO_EDICION:
    MOVLW 31
    SUBWF dias, W 
    BTFSC STATUS, 0
    CALL FIN_DE_MES
    MOVF dias, W
    XORLW 0
    BTFSC STATUS, 2
    CALL PONER_30
    RETURN
JULIO_EDICION:
    MOVLW 32
    SUBWF dias, W 
    BTFSC STATUS, 0
    CALL FIN_DE_MES
    MOVF dias, W
    XORLW 0
    BTFSC STATUS, 2
    CALL PONER_31
    RETURN
AGOSTO_EDICION:
    MOVLW 32
    SUBWF dias, W 
    BTFSC STATUS, 0
    CALL FIN_DE_MES
    MOVF dias, W
    XORLW 0
    BTFSC STATUS, 2
    CALL PONER_31
    RETURN
SEPTIEMBRE_EDICION:
    MOVLW 31
    SUBWF dias, W 
    BTFSC STATUS, 0
    CALL FIN_DE_MES
    MOVF dias, W
    XORLW 0
    BTFSC STATUS, 2
    CALL PONER_30
    RETURN
OCTUBRE_EDICION:
    MOVLW 32
    SUBWF dias, W 
    BTFSC STATUS, 0
    CALL FIN_DE_MES
    MOVF dias, W
    XORLW 0
    BTFSC STATUS, 2
    CALL PONER_31
    RETURN
NOVIEMBRE_EDICION:
    MOVLW 31
    SUBWF dias, W 
    BTFSC STATUS, 0
    CALL FIN_DE_MES
    MOVF dias, W
    XORLW 0
    BTFSC STATUS, 2
    CALL PONER_30
    RETURN
DICIEMBRE_EDICION:
    MOVLW 32
    SUBWF dias, W 
    BTFSC STATUS, 0
    CALL FIN_DE_MES
    MOVF dias, W
    XORLW 0
    BTFSC STATUS, 2
    CALL PONER_31
    RETURN
; ---------------------- MESES EN MODO NORMAL -----------------------
ENERO:
    MOVF dias, W ; es el mismo procedimiento solo que se incrementan los meses si el día se pasa del limite
    XORLW 32
    BTFSC STATUS, 2
    CALL FINAL_DE_MES
    RETURN
FEBRERO:
    MOVF dias, W
    XORLW 29
    BTFSC STATUS, 2
    CALL FINAL_DE_MES
    RETURN
MARZO:
    MOVF dias, W
    XORLW 32
    BTFSC STATUS, 2
    CALL FINAL_DE_MES
    RETURN
ABRIL:
    MOVF dias, W
    XORLW 31
    BTFSC STATUS, 2
    CALL FINAL_DE_MES
    RETURN
MAYO:
    MOVF dias, W
    XORLW 32
    BTFSC STATUS, 2
    CALL FINAL_DE_MES
    RETURN
JUNIO:
    MOVF dias, W
    XORLW 31
    BTFSC STATUS, 2
    CALL FINAL_DE_MES
    RETURN
JULIO:
    MOVF dias, W
    XORLW 32
    BTFSC STATUS, 2
    CALL FINAL_DE_MES
    RETURN
AGOSTO:
    MOVF dias, W
    XORLW 32
    BTFSC STATUS, 2
    CALL FINAL_DE_MES
    RETURN
SEPTIEMBRE:
    MOVF dias, W
    XORLW 31
    BTFSC STATUS, 2
    CALL FINAL_DE_MES
    RETURN
OCTUBRE:
    MOVF dias, W
    XORLW 32
    BTFSC STATUS, 2
    CALL FINAL_DE_MES
    RETURN
NOVIEMBRE:
    MOVF dias, W
    XORLW 31
    BTFSC STATUS, 2
    CALL FINAL_DE_MES
    RETURN
DICIEMBRE:
    MOVF dias, W
    XORLW 32
    BTFSC STATUS, 2
    CALL FINAL_DE_MES
    RETURN
MESES_13:
    MOVLW 1
    MOVWF meses
    CALL TRANSFORMAR_MESES
    RETURN

MESES_0:
    MOVLW 12
    MOVWF meses
    CALL TRANSFORMAR_MESES
    RETURN

FIN_DE_MES: ; cuando se termina el mes en edición ponemos uno en dias
    BANKSEL dias
    MOVLW 1
    MOVWF dias
    CALL TRANSFORMAR_DIAS
    MOVF dias+3, W
    RETURN
FINAL_DE_MES: ;lo mismo solo que incrementamos el mes cuando no es edición
    MOVLW 1
    MOVWF dias
    INCF meses
    CALL TRANSFORMAR_MESES
    CALL TRANSFORMAR_DIAS
    RETURN
    
; Para los meses con el respectivo limite de días
PONER_31:
    MOVLW 31
    MOVWF dias
    CALL TRANSFORMAR_DIAS
    RETURN
PONER_30:
    MOVLW 30
    MOVWF dias
    CALL TRANSFORMAR_DIAS
    RETURN
PONER_28:
    MOVLW 28
    MOVWF dias
    CALL TRANSFORMAR_DIAS
    RETURN

    ; funciones que se ejecutan para los overflows de todas las variables
SEGUNDOS_60:
    CLRF segundos
    INCF minutos
    CALL TRANSFORMAR_MINUTOS
    RETURN
MINUTOS_60:
    CLRF minutos
    INCF horas
    CALL TRANSFORMAR_MINUTOS
    CALL TRANSFORMAR_HORAS
    RETURN
MINUTOS_255:
    MOVLW 59
    MOVWF minutos
    RETURN
HORAS_24:
    CLRF horas
    INCF dias
    CALL TRANSFORMAR_DIAS
    CALL TRANSFORMAR_HORAS
    RETURN
HORAS_255:
    MOVLW 23
    MOVWF horas
    RETURN
MINUTOS_ALARMA_255:
    MOVLW 59
    MOVWF minutos_alarma
    RETURN
HORAS_ALARMA_255:
    MOVLW 23
    MOVWF horas_alarma
    RETURN
MINUTOS_TIMER_255:
    MOVLW 99
    MOVWF minutos_timer
    RETURN
SEGUNDOS_TIMER_255:
    MOVLW 59
    MOVWF segundos_timer
    RETURN
; ----------------- código que servirá para la función del puerto RB4 si la alarma está prendida
VER_PUERTO_RB4:
    BTFSS PORTB, 4
    CALL APAGAR_ALARMA_HORA
    RETURN
APAGAR_ALARMA_HORA:
    BCF activar_alarma, 0
    BCF alarma_hora, 0
    CLRF conteo_alarma_hora
    RETURN
VER_PUERTORB4:
    BTFSS PORTB, 4
    CALL APAGAR_ALARMA_TIMER
    RETURN
APAGAR_ALARMA_TIMER:
    BCF alarma_timer, 0
    CLRF conteo_alarma_timer
    RETURN
END