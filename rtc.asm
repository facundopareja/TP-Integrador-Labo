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
#if 0

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
#endif

    ret


	