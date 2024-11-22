;
; TP Integrador.asm
;
; Created: 15/11/2024 08:18:40
; Author : Facundo
;
.equ caracter_config_mode = 'C'
.equ caracter_config_finished = 'F'
; Possible states
; Basic lock state
.equ LOCK_STATE = 1
; Config state (we can read 4 numeric characters to use as code)
.equ CONFIG_STATE = 2
; Once we've received all 4 numbers we can store them in EEPROM
.equ RECEIVED_CODE_STATE = 3
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

.cseg
.ORG 0x0000
	rjmp RESET

.ORG URXCaddr
	rjmp USART_Receive ; 

.ORG UTXCaddr
	rjmp USART_Transmit ; This interrupt is disabled for now

.ORG INT_VECTORS_SIZE
; Resetting SP
RESET:
	CLI
	LDI temp, HIGH(RAMEND)					
	OUT SPH, temp				
	LDI temp, LOW(RAMEND)
	OUT SPL, temp

; Setting pins PB4/PB5 as output.
PORT_INITIALIZING:
	in temp, ddrb
	ori temp, 0b00110000 
	out ddrb, temp

; Place all initializing functions for your modules here
MODULE_INITIALIZING:
	rcall USART_Init
	sei

; This loop is only meant for debugging purposes.
; It prints the code currently in EEPROM.
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
	
; Main loop, program starts in LOCK MODE. Will only progress from here once specific input is received.
start:
	cpi mode, CONFIG_STATE
	brne start
	rcall CONFIG_MODE
	rjmp start

; LEDS are turned on when entering config mode
CONFIG_MODE:
	clr numbers_received
	in temp, pinb
	ori temp, 0b00110000 
	out portb, temp ; Prendo LEDs
; Once we're in config mode we loop until we receive all 4 numbers 
; or until we get an 'F'
WAIT_CHAR:
	cpi mode, RECEIVED_CODE_STATE
	breq STORE_CODE
	cpi mode, LOCK_STATE
	breq END_CONFIG_MODE
	rjmp WAIT_CHAR
; Once we received all numbers needed for code, we can store the code in EEPROM
STORE_CODE:
	clr eeprom_address_high
	clr eeprom_address_low
	ldi XH, high(KEYCODE)
	ldi XL, low(KEYCODE)
	ldi numbers_received, LENGTH_CODE
; We loop RAM 4 times and write EEPROM each time
LOOP_STORE:
	ld eeprom_dato, X+
	rcall EEPROM_WRITE
	inc eeprom_address_low
	dec numbers_received
	cpi numbers_received, 0 
	brne LOOP_STORE
; LEDS are turned off when exiting config mode
END_CONFIG_MODE:
	in temp, pinb
	andi temp, 0b11001111 
	out portb, temp 
	ret

.include "usart.asm"
.include "eeprom.asm"

