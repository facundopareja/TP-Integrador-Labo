/*
 * rtc.asm
 *
 *  Created: 11/22/2024 11:26:57 AM
 *   Author: valen
 */ 

 .def	scnd_digit = r23

 
TIME_DECOD:
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

TIME_COD:
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


	