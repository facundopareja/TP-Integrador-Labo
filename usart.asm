/*
 * usart.asm
 *
 *  Created: 15/11/2024 09:44:10
 *   Author: Facundo
 */ 

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
	push temp
	in temp, SREG
	push temp
	; After receiving a character through SERIAL port, we check, in order
	; 1) If the character is 'F' (if it is we return to LOCK_STATE and end the interruption).
	; 2) If we are already in CONFIG_STATE and 'P' has been previously pressed 
	;    (if it's the case, we can go straight to verifying if the received character is a number or not).
	; 3) If the character is 'C' (if it is we set CONFIG_STATE and end the interruption).
	; 4) If the character is 'T' (if it is we check being in CONFIG_STATE, set CONFIG_RTC_STATE end the interruption).
	; 4) If the character is 'P' (if it is we check being in CONFIG_STATE, set CONFIG_NEW_PWD_STATE end the interruption).
	lds value_received, UDR0
	mov temp, value_received
	rcall USART_Transmit
	rcall TRANSMIT_SPACE
	cpi value_received, caracter_config_finished
	breq SET_LOCK_MODE
	cpi mode, CONFIG_NEW_PWD_STATE
	breq VERIFY_NUMBER	
	cpi mode, CONFIG_RTC_STATE
	breq VERIFY_TIME
	cpi value_received, caracter_config_mode
	breq SET_CONFIG_MODE
	; Check for 'T' and 'P' character.
	cpi value_received, caracter_config_RTC
	breq SET_RTC_CONFIG_MODE
	cpi value_received, caracter_config_new_pwd
	breq SET_NEW_PWD_CONFIG_MODE
	rjmp FIN
SET_LOCK_MODE:
	ldi mode, LOCK_STATE
	rjmp FIN
SET_CONFIG_MODE:
	ldi mode, CONFIG_STATE
	rjmp FIN
; If 'T' or 'P' pressed, we need to check that we were already in CONFIG_STATE
SET_RTC_CONFIG_MODE:
	cpi mode, CONFIG_STATE
	brne FIN
	ldi mode, CONFIG_RTC_STATE
	rjmp FIN
SET_NEW_PWD_CONFIG_MODE:
	cpi mode, CONFIG_STATE
	brne FIN
	ldi mode, CONFIG_NEW_PWD_STATE
	rjmp FIN

; We check that the receied value is a number 
; between 00 and 23 if hours, or between 00 and 59 if minutes.
; If right, we store one by one in addr KEYCODE + numbers_received
; We then enter RECEIVED_CODE_STATE
VERIFY_TIME:
	cpi numbers_received, 0
	breq FRST_TIME_DIGIT
	cpi numbers_received, 1
	breq SCND_TIME_DIGIT
	cpi numbers_received, 2
	breq THRD_TIME_DIGIT
FRTH_TIME_DIGIT:
	cpi value_received, '0'
	brlo FIN_INVALID
	cpi value_received, '9'+ 1 		; if HH:MM second H > 9 --> end
	brsh FIN_INVALID
	rjmp LOAD_X_POINTER
FRST_TIME_DIGIT:
	cpi value_received, '0'
	brlo FIN_INVALID
	cpi value_received, '2' + 1		; if HH:MM first H > 2 --> end
	brsh FIN_INVALID
	rjmp LOAD_X_POINTER
SCND_TIME_DIGIT:
	cpi value_received, '0'
	brlo FIN_INVALID
	ldi XH, high(KEYCODE)
	ldi XL, low(KEYCODE)
	ld temp, X
	cpi temp, '2'
	breq SCND_DIGIT_LOWER_2
	cpi value_received, '9' + 1		; if HH:MM second H > 9 --> end
	brsh FIN_INVALID
	rjmp LOAD_X_POINTER
THRD_TIME_DIGIT:
	cpi value_received, '0'
	brlo FIN_INVALID
	cpi value_received, '5' + 1		; if HH:MM first M > 5 --> end
	brsh FIN_INVALID
	rjmp LOAD_X_POINTER

SCND_DIGIT_LOWER_2:
	cpi value_received, '3' + 1		; if HH:MM second H > 3 && first digit H = 2 --> end
	brsh FIN_INVALID
	rjmp LOAD_X_POINTER

; We check that received value is an ASCII number.
; If it is we store it in address = KEYCODE + numbers_received
; The loop is over when all 4 numbers have been received 
; We then enter RECEIVED_CODE_STATE
VERIFY_NUMBER:
	cpi value_received, '0'
	brlo FIN_INVALID
	cpi value_received, '9' + 1
	brsh FIN_INVALID
LOAD_X_POINTER:
	ldi XH, high(KEYCODE)
	ldi XL, low(KEYCODE)
STORE_NUMBERS:	
	add XL, numbers_received
	clr temp
	adc XH, temp
	st X+, value_received  
	inc numbers_received
	cpi numbers_received, LENGTH_CODE
	brne FIN
	ldi mode, RECEIVED_CODE_STATE

FIN:
	pop temp
	out SREG, temp
	pop temp
	reti
FIN_INVALID:
	rcall LOADING_STR_INVALID
	rcall TRANSMIT_STR
	pop temp
	out SREG, temp
	pop temp
	reti