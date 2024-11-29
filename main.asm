;
; TP Integrador.asm
;
; Created: 15/11/2024 08:18:40
; Author : Facundo
;
.equ caracter_config_mode = 'C'
.equ caracter_config_finished = 'F'
; Possible states
.equ CONFIG_STATE = 1
.equ LOCK_STATE = 2
.equ RECEIVED_CODE_STATE = 3
.equ 	PSW_LIM = 			4
; Constants
.equ LENGTH_CODE = 4
; Register labels
.DEF temp= r16
.DEF mode= r17
.DEF value_received = r18
.DEF numbers_received = r19
; RAM
.dseg
.ORG SRAM_START
KEYCODE: .byte 4
passwordRAM: .byte PSW_LIM

.cseg
.ORG 0x0000
	rjmp RESET

.ORG URXCaddr
	rjmp USART_Receive

.ORG UTXCaddr
	rjmp USART_Transmit ; La funcion esta incompleta

.org PCI2addr
	rjmp INT_teclado

.org OC0Aaddr
	rjmp INT_timer0

.ORG INT_VECTORS_SIZE
RESET:
	CLI
	LDI temp, HIGH(RAMEND)					
	OUT SPH, temp				
	LDI temp, LOW(RAMEND)
	OUT SPL, temp

PORT_INITIALIZING:
	in temp, ddrb
	ori temp, 0b00110000 ; Mascara para activar PB4/PB5 como salida
	out ddrb, temp
	ldi temp, msk_entrada
	out DDRD, temp

	ldi temp, ~msk_entrada						;pullup y salidas en 0
	out PORTD, temp

MODULE_INITIALIZING:
	rcall USART_Init
	sei

LOADING_CURRENT_PASSWORD:
	ldi numbers_received, LENGTH_CODE
	clr eeprom_address_high
	clr eeprom_address_low
TRANSMIT_LOOP:
	lds r17, UCSR0A
	sbrs r17, UDRE0
	rjmp TRANSMIT_LOOP
	rcall EEPROM_READ
	mov temp, eeprom_dato
	rcall USART_Transmit
	inc eeprom_address_low
	dec numbers_received
	cpi numbers_received, 0
	brne TRANSMIT_LOOP

start:
	cpi mode, CONFIG_STATE
	breq CONFIG_MODE
	cpi mode, DET_STATE
	breq branch_detec_call
	rjmp start

CONFIG_MODE:
	clr numbers_received
	in temp, pinb
	ori temp, 0b00110000 
	out portb, temp ; Prendo LEDs
WAIT_CHAR:
	cpi mode, RECEIVED_CODE_STATE
	breq STORE_CODE
	rjmp WAIT_CHAR
	clr eeprom_address_high
	clr eeprom_address_low
	ldi XH, high(KEYCODE)
	ldi XL, low(KEYCODE)
	; Habria que guardar en RTC en caso de que se haya ingresado T
STORE_CODE:
	ldi numbers_received, LENGTH_CODE
LOOP_STORE:
	ld eeprom_dato, X+
	rcall EEPROM_WRITE
	inc eeprom_address_low
	dec numbers_received
	cpi numbers_received, 0 
	brne LOOP_STORE
END_CONFIG_MODE:
	in temp, pinb
	andi temp, 0b11001111 
	out portb, temp ; Apago leds
	rjmp start

branch_detec_call:
	call branch_detec
	rjmp start

.include "usart.asm"
.include "eeprom.asm"
.include "keyboard_m.asm"

