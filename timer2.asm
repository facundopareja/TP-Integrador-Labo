/*
 * rtc.asm
 *
 *  Created: 11/22/2024 10:09:32 AM
 *   Author: valen
 */ 

.DEF	seconds_passed = r9
.equ	TIMEOUT = 10
 ; For a 1 Hz overflow (ideal for RTC functionality): OCR2A = f_clk*Tdesired/N - 1 = 32.768kHz*1sec/128 - 1 = 255.
.equ	OCR2A_value = 0xFF
 ; We'll use the timer 2 with an external crystal connected

TIMER2_Init:
	cli													; Disable global interrups for safe configuration
	ldi temp, (1 << AS2)
	sts ASSR, temp
	ldi temp, (1 << WGM21) | (1 << WGM20)				; WGM = 3 (CTC)
	sts TCCR2A, temp
	; Wait for Timer Synchronization
SYNC_LOOP:
	lds temp, ASSR
	sbrc temp, OCR2AUB									 ; Wait until ready for synchronization
	rjmp SYNC_LOOP
	
	ldi temp, OCR2A_value
	sts OCR2A, temp
	ldi temp, (0 << CS22) | (1 << CS21) | (1 << CS20)	; Prescaler = 64, en 128 para 1mhz
	sts TCCR2B, temp
	ldi temp, (1 << OCIE2A)								; Enable the Output Compare Match A interrupt
	sts TIMSK2, temp
	clr seconds_passed
	ret

; Interruption routine for Timer/Counter2 Compare Match A
TIMER2_COMP:
	push temp
	in temp, SREG
	push temp
	
	inc seconds_passed
	mov temp, seconds_passed
	cpi temp, TIMEOUT
	; If equal, TIMEOUT reached --> light red led
	; If not, keep waiting
	
go_back:
	pop temp
	out SREG, temp
	pop temp
	reti