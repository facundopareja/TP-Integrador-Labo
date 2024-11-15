/*
 * usart.asm
 *
 *  Created: 15/11/2024 09:44:10
 *   Author: Facundo
 */ 

.equ valor_UBRRn=0
.equ USART_mode = (0<<UMSEL01) | (0<<UMSEL00)

rjmp CONFIGURATION

USART_Init:
	ldi r17, high(valor_UBRRn)
	ldi r16, low(valor_UBRRn)
	; Set baud rate to UBRR0
	sts UBRR0H, r17
	sts UBRR0L, r16
	; Enable transmitter, disable receiver.
	ldi r16, (0<<RXEN0)|(1<<TXEN0)
	sts UCSR0B,r16
	; Set frame format: 8data, 1stop bit 
	; Setting USART in async mode
	ldi r16, (3<<UCSZ00)|(0<<USBS0) | USART_mode
	sts UCSR0C,r16
	ret

USART_Transmit:
	; Wait for empty transmit buffer
	lds r17, UCSR0A
	sbrs r17, UDRE0
	rjmp USART_Transmit
	; Put data (r16) into buffer, sends the data
	sts UDR0,r16
	ret