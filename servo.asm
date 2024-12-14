/*
 * servo.asm
 *
 *  Created: 11/22/2024 11:29:25 AM
 *   Author: valen
 */ 

.def	OCR1A_reg = r25

;--------- RUTINA DE CONFIGURACIÓN DEL TIMER 1 ----------------
TIMER1_Init:
	; El ancho de pulso empieza siendo de 1.5ms para que la posición inicial sea de 0°
	rcall CLOSE_LOCK

	ldi temp, (1 << WGM11) | (0 << WGM10) | (1 << COM1A1) | (0 << COM1A0)		; Modo 14 fast PWM: WGM1 = 1110. OC1A conectado y clear on CM
	sts TCCR1A, temp

	; cargo el valor de ICR1 para obtener un período de 50ms
	ldi temp, high(ICR1_val)
	sts ICR1H, temp
	ldi temp, low(ICR1_val)
	sts ICR1L, temp
	
TIMER1_ON:
	ldi temp, (1 << WGM13) | (1 << WGM12) | (0 << CS12) | (1 << CS11) | (1 << CS10) 	; Modo 14 fast PWM: WGM1 = 1110. Prescaler = 8 (CS1 = 001)
	sts TCCR1B, temp
	ret
	
CLOSE_LOCK:	
	ldi OCR1A_reg, high(OCR1A_central)
	sts OCR1AH, OCR1A_reg
	ldi OCR1A_reg, low(OCR1A_central)
	sts OCR1AL, OCR1A_reg
	ret
OPEN_LOCK:	
	ldi OCR1A_reg, high(OCR1A_max)
	sts OCR1AH, OCR1A_reg
	ldi OCR1A_reg, low(OCR1A_max)
	sts OCR1AL, OCR1A_reg
	ret