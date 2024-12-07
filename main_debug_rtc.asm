;
; TP Integrador.asm
;
; Created: 15/11/2024 08:18:40
; Author : Facundo
;

.equ 	msk_entrada = 	0b11110000

.equ caracter_config_mode = 'C'
.equ caracter_config_finished = 'F'
.equ caracter_config_RTC = 'T'
.equ caracter_config_new_pwd = 'P'
; Possible states
; Basic lock state
.equ LOCK_STATE = 1
; Config state (we can read 4 numeric characters to use as code)
.equ CONFIG_STATE = 2
; Once we've received all 4 numbers we can store them in EEPROM
.equ RECEIVED_CODE_STATE = 3
; Once in config state, determine if a new pwd will be loaded (P) or the time will be set (T)
.equ CONFIG_RTC_STATE = 5
.equ CONFIG_NEW_PWD_STATE = 6
.equ STNBY_STATE = 7
.equ DET_STATE = 8
; Constants
.equ LENGTH_CODE = 4
.equ PSW_lim = 4
.EQU	retardo = 40

; Register labels
.DEF temp= r16
.DEF mode= r17
.DEF value_received = r18
.DEF numbers_received = r19
.DEF minutes = r21
.DEF hours = r22
; RAM
.dseg
.ORG SRAM_START
KEYCODE: .byte 4
passwordRAM: .byte LENGTH_CODE

.cseg
.ORG 0x0000
	rjmp RESET

.ORG URXCaddr
	rjmp USART_Receive

.ORG UTXCaddr
	reti ; La funcion esta incompleta

.org PCI2addr
	reti

.org OC2Aaddr
	reti

.org OC0Aaddr
	reti

.org TWIaddr

.ORG INT_VECTORS_SIZE
RESET:
	CLI
	LDI temp, HIGH(RAMEND)					
	OUT SPH, temp				
	LDI temp, LOW(RAMEND)
	OUT SPL, temp


PORT_INITIALIZING:
	in temp, ddrb
	ori temp, 0b00110010 ; Mascara para activar PB4/PB5/PB1 como salida
	out ddrb, temp
	ldi temp, msk_entrada
	out DDRD, temp

	ldi temp, ~msk_entrada						;pullup y salidas en 0
	out PORTD, temp


MODULE_INITIALIZING:
	rcall USART_Init
	rcall TWI_Init
	sei

TRANSMIT_prueba:
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp TRANSMIT_prueba
	ldi temp, 'I'
	rcall USART_Transmit
	rcall delay_500ms
STORING_CURRENT_TIME:
	ldi hours, 0x18
	rcall TWI_WRITE
	clr hours
; Envio los segundos cada 500ms para debuggear
main_loop:
LOADING_CURRENT_TIME:
	rcall TWI_READ
	ldi XH, high(KEYCODE)
	ldi XL, low(KEYCODE)
	rcall TIME_COD
	ldi XH, high(KEYCODE)
	ldi XL, low(KEYCODE)
	ldi numbers_received, (LENGTH_CODE >> 1)	; son solo 2 bytes (dos caracteres de segundos: unidades y decenas)

TRANSMIT_TIME:
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp TRANSMIT_TIME
	ld temp, X+
	rcall USART_Transmit
	dec numbers_received
	cpi numbers_received, 0
	brne TRANSMIT_TIME
TRANSMIT_PRUEBA2:
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp TRANSMIT_PRUEBA2
	ldi temp, ':'
	rcall USART_Transmit

	rcall delay_500ms
	rjmp main_loop


; --- Subrutina de retardo de 500ms ---
delay_500ms:
    ldi r18, retardo
    ldi r19, retardo
    ldi r20, retardo

delay_loop:
    dec r20
    brne delay_loop

    dec r19
    brne delay_loop

    dec r18
    brne delay_loop

    ret


#if 0


PORT_INITIALIZING:
	in temp, ddrb
	ori temp, 0b00110010 ; Mascara para activar PB4/PB5/PB1 como salida
	out ddrb, temp
	ldi temp, msk_entrada
	out DDRD, temp

	ldi temp, ~msk_entrada						;pullup y salidas en 0
	out PORTD, temp

INICIALIZACION_PC:
	lds temp, PCMSK2
	ori temp, ~msk_entrada
	sts PCMSK2, temp 			;habilito los puertos de la entrada para interrupcion PC

	in temp, PCIFR
	ori temp, (1<<PCIF0)
	out PCIFR, temp				;limpio el flag de interrupcion

	lds temp, PCICR
	ori temp, (1<<PCIE2)
	sts PCICR, temp				;habilito la interrupcion de PC para el puerto D

INICIALIZACION_TIMER0:
	ldi temp, ~(11<<WGM00)			;modo normal
	out TCCR0A, temp

	ldi temp, (0<<WGM02) | (0b000<<CS00) 	;clock detenido
	out TCCR0B, temp

	in temp, TIFR0
	ori temp, (1<<TOV0)
	out TIFR0, temp				;limpio el flag de interrupcion

	lds temp, TIMSK0
	ori temp, (1<<TOIE0)
	sts TIMSK0, temp				;habilito la interrupcion por Overflow

MODULE_INITIALIZING:
	rcall USART_Init
	rcall TWI_Init
	rcall TIMER1_Init
	sei

LOADING_CURRENT_PASSWORD:
	ldi numbers_received, LENGTH_CODE
	clr eeprom_address_high
	clr eeprom_address_low
TRANSMIT_LOOP:
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp TRANSMIT_LOOP
	rcall EEPROM_READ
	mov temp, eeprom_dato
	rcall USART_Transmit
	inc eeprom_address_low
	dec numbers_received
	cpi numbers_received, 0
	brne TRANSMIT_LOOP
LOADING_CURRENT_TIME:
	call TWI_READ
	ldi XH, high(KEYCODE)
	ldi XL, low(KEYCODE)
	call TIME_COD
	ldi XH, high(KEYCODE)
	ldi XL, low(KEYCODE)
	ldi numbers_received, LENGTH_CODE
TRANSMIT_TIME:
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp TRANSMIT_TIME
	ld temp, X+
	rcall USART_Transmit
	dec numbers_received
	cpi numbers_received, 0
	brne TRANSMIT_TIME

start:
	cpi mode, CONFIG_STATE
	breq CONFIG_MODE
	cpi mode, DET_STATE
	breq branch_detec_call
	rjmp start

CONFIG_MODE:
	clr numbers_received
	; Prendo LEDs
	sbi PORTB, PB4
	sbi PORTB, PB5
; Once we're in config mode we loop until we receive an 'F', 'P' or 'T'
WAIT_CHAR:
	cpi mode, LOCK_STATE
	breq END_CONFIG_MODE
	cpi mode, CONFIG_NEW_PWD_STATE
	breq WAIT_NEW_PWD
	cpi mode, CONFIG_RTC_STATE
	breq WAIT_TIME
	rjmp WAIT_CHAR
WAIT_TIME:
	cpi mode, RECEIVED_CODE_STATE
	breq STORE_TIME
	rjmp WAIT_TIME
WAIT_NEW_PWD:
	cpi mode, RECEIVED_CODE_STATE
	breq STORE_CODE
	rjmp WAIT_NEW_PWD
STORE_TIME:
	ldi XH, high(KEYCODE)
	ldi XL, low(KEYCODE)
	rcall TIME_DECOD
	rcall TWI_WRITE
	rjmp END_CONFIG_MODE
STORE_CODE:
	ldi XH, high(KEYCODE)
	ldi XL, low(KEYCODE)
	clr eeprom_address_high
	clr eeprom_address_low
	ldi numbers_received, LENGTH_CODE
LOOP_STORE:
	ld eeprom_dato, X+
	rcall EEPROM_WRITE
	inc eeprom_address_low
	dec numbers_received
	cpi numbers_received, 0 
	brne LOOP_STORE
END_CONFIG_MODE:
	; Apago leds
	cbi PORTB, PB4
	cbi PORTB, PB5
	rjmp start

branch_detec_call:
	call branch_detec
	rjmp start
#endif

.include "usart.asm"
.include "eeprom.asm"
.include "keyboard_m.asm"
.include "sec_test.asm"
.include "rtc.asm"
.include "servo.asm"
.include "timer2.asm"

