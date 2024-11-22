/*
 * usart.asm
 *
 *  Created: 15/11/2024 09:44:10
 *   Author: Facundo
 */ 

.equ valor_UBRRn=103
.equ USART_mode = (0<<UMSEL01) | (0<<UMSEL00)
.equ UCSR0B_values =  (1<<RXCIE0) | (0<<TXCIE0) | (1<<RXEN0) | (1<<TXEN0) ; Activo transmisor, receptor, interrupciones de transmision y recepcion.

USART_Init:
	ldi r17, high(valor_UBRRn)
	ldi r16, low(valor_UBRRn)
	; Set baud rate to UBRR0
	sts UBRR0H, r17
	sts UBRR0L, r16
	ldi r16, UCSR0B_VALUES
	sts UCSR0B, r16
	; Set frame format: 8data, 1stop bit 
	; Setting USART in async mode
	ldi r16, (3<<UCSZ00)|(0<<USBS0) | USART_mode
	sts UCSR0C, r16
	ret

USART_Transmit:
	sts UDR0, temp
	ret
	
USART_Receive:
	lds value_received, UDR0
	mov temp, value_received
	rcall USART_Transmit
	cpi value_received, caracter_config_finished
	breq SET_LOCK_MODE
	cpi mode, CONFIG_STATE
	breq VERIFY_NUMBER
	cpi value_received, caracter_config_mode
	breq SET_CONFIG_MODE
	; Faltaria validar que reciba una T
	brne FIN
SET_LOCK_MODE:
	ldi mode, LOCK_STATE
	rjmp FIN
SET_CONFIG_MODE:
	ldi mode, CONFIG_STATE
	rjmp FIN
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