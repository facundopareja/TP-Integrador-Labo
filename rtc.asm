/*
 * rtc.asm
 *
 *  Created: 11/22/2024 11:26:57 AM
 *   Author: valen
 */ 

 .def	scnd_digit = r23

 
TIME_DECOD:
	; Convert ASCII to hours
	ld      temp, X+			; Load first ASCII byte (hour tens) from RAM
    subi    temp, '0'			; Convert ASCII to numeric value (e.g. 32 - 30 = 2)
	swap	temp				; Store tens on high nibble

    ld      scnd_digit, X+		; Load second ASCII byte (hour units) from RAM
    subi    scnd_digit, '0'     ; Convert ASCII to numeric value
    add     temp, scnd_digit    ; Combine tens and units
    mov     hours, temp			; Store in the hours register (BCD hour ready)
    
	ld      temp, X+			; Load third ASCII byte (minute tens) from RAM
    subi    temp, '0'			; Convert ASCII to numeric value
	swap	temp				; Store tens on high nibble

    ld      scnd_digit, X       ; Load fourth ASCII byte (minute units) from RAM
    subi    scnd_digit, '0'     ; Convert ASCII to numeric value
    add     temp, scnd_digit    ; Combine tens and units
    mov     minutes, temp		; Store in the minutes register (BCD minute ready) 
	ret

TIME_COD:
	; Convert hours to ASCII
    mov     temp, hours         ; Load hours (BCD format) into temp
    andi    temp, 0xF0          ; Mask to extract high nibble (tens place)
    swap    temp                ; Swap nibbles to shift high nibble to low nibble
    ori     temp, '0'           ; Convert to ASCII ('0' + tens digit)
    st      X+, temp            ; Store ASCII tens digit at X and increment pointer

    mov     temp, hours         ; Load hours (BCD format) into temp again
    andi    temp, 0x0F          ; Mask to extract low nibble (units place)
    ori     temp, '0'           ; Convert to ASCII ('0' + units digit)
    st      X+, temp            ; Store ASCII units digit at X and increment pointer

    ; Convert minutes to ASCII
    mov     temp, minutes       ; Load minutes (BCD format) into temp
    andi    temp, 0xF0          ; Mask to extract high nibble (tens place)
    swap    temp                ; Swap nibbles to shift high nibble to low nibble
    ori     temp, '0'           ; Convert to ASCII ('0' + tens digit)
    st      X+, temp            ; Store ASCII tens digit at X and increment pointer

    mov     temp, minutes       ; Load minutes (BCD format) into temp again
    andi    temp, 0x0F          ; Mask to extract low nibble (units place)
    ori     temp, '0'           ; Convert to ASCII ('0' + units digit)
    st      X+, temp            ; Store ASCII units digit at X and increment pointer

    ret

; ----------------------------------- TRANSMIT ROUTINES --------------------------------------
LOADING_CURRENT_TIME:
	rcall TWI_READ
	ldi XH, high(KEYCODE)
	ldi XL, low(KEYCODE)
	rcall TIME_COD
	ldi XH, high(KEYCODE)
	ldi XL, low(KEYCODE)
	ldi temp, LENGTH_CODE
	mov numbers_transmitted, temp
TRANSMIT_TIME:
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp TRANSMIT_TIME
	ld temp, X+
	rcall USART_Transmit
	dec numbers_transmitted
	mov temp, numbers_transmitted
	cpi temp,2
	in temp, SREG
	sbrc temp, SREG_Z
	rcall PRINT_SEPARATOR
	mov temp, numbers_transmitted
	cpi temp, 0
	brne TRANSMIT_TIME
	ret
	
LOADING_STR_PWD:
	ldi ZH, high(STR_PWD << 1)
	ldi ZL, low(STR_PWD << 1)
	ret
LOADING_STR_PWD_wait:
	ldi ZH, high(STR_PWD_wait << 1)
	ldi ZL, low(STR_PWD_wait << 1)
	ret
LOADING_STR_TIME:
	ldi ZH, high(STR_TIME << 1)
	ldi ZL, low(STR_TIME << 1)
	ret
LOADING_STR_TIME_wait:
	ldi ZH, high(STR_TIME_wait << 1)
	ldi ZL, low(STR_TIME_wait << 1)
	ret
LOADING_STR_INVALID:
	ldi ZH, high(STR_INVALID << 1)
	ldi ZL, low(STR_INVALID << 1)
	ret
TRANSMIT_STR:
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp TRANSMIT_STR
	lpm temp, Z+
	cpi temp, 0
	breq END_STR
	rcall USART_Transmit
	rjmp TRANSMIT_STR

END_STR:	ret


PRINT_SEPARATOR:
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp PRINT_SEPARATOR
	ldi temp, ':'
	rcall USART_Transmit
	ret

TRANSMIT_S:
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp TRANSMIT_S
	ldi temp, 'S'
	rcall USART_Transmit
	ret

TRANSMIT_SPACE:
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp TRANSMIT_SPACE
	ldi temp, ' '
	rcall USART_Transmit
	ret



	