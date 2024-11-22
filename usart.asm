/*
 * usart.asm
 *
 *  Created: 15/11/2024 09:44:10
 *   Author: Facundo
 */ 

 ; Baud rate set to 9600 
.equ valor_UBRRn=103
; USART set in asynchronous mode.
.equ USART_mode = (0<<UMSEL01) | (0<<UMSEL00)
 ; Enabled transmitter, receptor and both interrupts (actually only the reception one).
.equ UCSR0B_values =  (1<<RXCIE0) | (0<<TXCIE0) | (1<<RXEN0) | (1<<TXEN0) 

; For USART configuration.
USART_Init:
	ldi temp, high(valor_UBRRn)
	sts UBRR0H, temp
	ldi temp, low(valor_UBRRn)
	sts UBRR0L, temp
	ldi temp, UCSR0B_VALUES
	sts UCSR0B, temp
	; Frame format set as 8 bit with 1 stop bit.
	ldi temp, (3<<UCSZ00)|(0<<USBS0) | USART_mode
	sts UCSR0C, temp
	ret

USART_Transmit:
	sts UDR0, temp
	ret
	
USART_Receive:
	; After receiving a character through SERIAL port, we check, in order
	; 1) If the character is 'F' (if it is we return to LOCK_STATE and end the interruption).
	; 2) If we are already in CONFIG_STATE (if we are, we can go straight to verifying if the received character is a number or not).
	; 3) If the character is 'C' (if it is we set CONFIG_STATE and end the interruption).
	lds value_received, UDR0
	mov temp, value_received
	rcall USART_Transmit
	cpi value_received, caracter_config_finished
	breq SET_LOCK_MODE
	cpi mode, CONFIG_STATE
	breq VERIFY_NUMBER
	cpi value_received, caracter_config_mode
	breq SET_CONFIG_MODE
	; Check for 'T' character should also be received here.
	brne FIN
SET_LOCK_MODE:
	ldi mode, LOCK_STATE
	rjmp FIN
SET_CONFIG_MODE:
	ldi mode, CONFIG_STATE
	rjmp FIN
; We check that received value is an ASCII number.
; If it is we store it in address = KEYCODE + numbers_received
; The loop is over when all 4 numbers have been received 
; We then enter RECEIVED_CODE_STATE
VERIFY_NUMBER:
	cpi value_received, '0'
	brlo FIN
	cpi value_received, '9'+1
	brsh FIN
	ldi XH, high(KEYCODE)
	ldi XL, low(KEYCODE)
	add XL, numbers_received
	clr temp
	adc XH, temp
	st X+, value_received  
	inc numbers_received
	cpi numbers_received, LENGTH_CODE
	brne FIN
	ldi mode, RECEIVED_CODE_STATE
FIN:
	reti