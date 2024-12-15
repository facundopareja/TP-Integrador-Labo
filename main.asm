;
; TP Integrador.asm
;
; Created: 15/11/2024 08:18:40
; Author : Facundo
;
.include "constants_16mhz.asm"

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
.equ LEDS_ON_WAITING = 9
.equ LEDS_ON_DONE = 10
; Constants
.equ LENGTH_CODE = 4
.equ PSW_lim = 4
.EQU retardo = 40
; Register labels
.DEF temp= r16
.DEF mode= r17
.DEF value_received = r18
.DEF numbers_received = r19
.DEF numbers_transmitted = r4
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

.org PCI1addr
	rjmp INT_teclado

.org OVF0addr
	rjmp INT_timer0

.org OVF2addr
	rjmp TIMER2_COMP

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
	out DDRD, temp								;ultimos 4 bit de D como salida

	clr temp
	out DDRC, temp 								;primeros 4 bit de C como entrada

	clr temp									;salidas en 0
	out PORTD, temp

	ldi temp, ~msk_entrada 						;pullup en bits de entrada
	out PORTC, temp

INICIALIZACION_PC:
	lds temp, PCMSK1
	ori temp, ~msk_entrada
	sts PCMSK1, temp 							;habilito los puertos de la entrada para interrupcion PC

	in temp, PCIFR
	ori temp, (1<<PCIF1)
	out PCIFR, temp								;limpio el flag de interrupcion

	lds temp, PCICR
	ori temp, (1<<PCIE1)
	sts PCICR, temp								;habilito la interrupcion de PC para el puerto D

INICIALIZACION_TIMER0:
	in temp, TCCR0B
	andi temp, ~(0b111<<CS00) 					;clock detenido
	out TCCR0B, temp

	in temp, TIFR0
	ori temp, (1<<TOV0)
	out TIFR0, temp								;limpio el flag de interrupcion

	lds temp, TIMSK0
	ori temp, (1<<TOIE0)
	sts TIMSK0, temp							;habilito la interrupcion por Overflow

MODULE_INITIALIZING:
	rcall USART_Init
	rcall TWI_Init
	rcall TIMER1_Init
	sei

LOADING_CURRENT_PASSWORD:
	ldi temp, LENGTH_CODE
	mov numbers_transmitted, temp
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
	dec numbers_transmitted
	mov temp, numbers_transmitted
	cpi temp, 0
	brne TRANSMIT_LOOP
	rcall TRANSMIT_SPACE

rcall LOADING_CURRENT_TIME

start:
	cpi mode, CONFIG_STATE
	breq CONFIG_MODE
	cpi mode, DET_STATE
	breq branch_detec_call
	rjmp start

; This loop handles configuration mode.
; After receiving either 'T' or 'P' it enters date or keycode specific loops
; Digits are stored in memory if they're valid and we wait until LENGTH_CODE numbers 
; Afterwards we iterate the stored numbers and either write them to the RTC or store them in EEPROM.
CONFIG_MODE:
	clr numbers_received
	sbi PORTB, PB4
	sbi PORTB, PB5
; Once we're in config mode we loop until we receive an 'F', 'P' or 'T'
WAIT_CHAR:
	cpi mode, LOCK_STATE
	breq END_CONFIG_MODE
	cpi mode, CONFIG_RTC_STATE
	breq WAIT_TIME
	cpi mode, CONFIG_NEW_PWD_STATE
	breq WAIT_NEW_PWD
	rjmp WAIT_CHAR
WAIT_TIME:
	rcall LOADING_STR_TIME_wait
	rcall TRANSMIT_STR
WAIT_TIME_LOOP:
	cpi mode, RECEIVED_CODE_STATE
	breq STORE_TIME
	cpi mode, LOCK_STATE
	breq END_CONFIG_MODE
	rjmp WAIT_TIME_LOOP
WAIT_NEW_PWD:
	rcall LOADING_STR_PWD_wait
	rcall TRANSMIT_STR
WAIT_NEW_PWD_LOOP:
	cpi mode, RECEIVED_CODE_STATE
	breq STORE_CODE
	cpi mode, LOCK_STATE
	breq END_CONFIG_MODE
	rjmp WAIT_NEW_PWD_LOOP
STORE_TIME:
	rcall LOADING_STR_TIME
	rcall TRANSMIT_STR
	ldi XH, high(KEYCODE)
	ldi XL, low(KEYCODE)
	rcall TIME_DECOD
	rcall TWI_WRITE
	clr numbers_received
	ldi mode, CONFIG_STATE
	rjmp WAIT_CHAR
STORE_CODE:
	rcall LOADING_STR_PWD
	rcall TRANSMIT_STR
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
	clr numbers_received
	ldi mode, CONFIG_STATE
	rjmp WAIT_CHAR
END_CONFIG_MODE:
	cbi PORTB, PB4
	cbi PORTB, PB5
	rjmp start

branch_detec_call:
	call branch_detec
	rjmp start


.include "usart.asm"
.include "eeprom.asm"
.include "keyboard_m.asm"
.include "twi.asm"
.include "rtc.asm"
.include "servo.asm"
.include "timer2.asm"

STR_PWD: .db "Cargando contrasena... ",0
STR_PWD_wait: .db "Esperando contrasena... ",0,0
STR_TIME: .db "Cargando tiempo... ",0
STR_TIME_wait: .db "Esperando tiempo... ",0,0
STR_INVALID: .db "Has ingresado un valor invalido. Ingresa un numero valido. ",0


