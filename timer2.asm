/*
 * timer2.asm
 *
 *  Created: 9/12/2024 10:59:25
 *   Author: Facundo
 */ 

.DEF	counter = r11
.DEF	seconds_passed = r9
.equ	prescaler = (1 << CS22) | (1 << CS21) | (1 << CS20) ; Prescaler = 1024
.equ	stop_clock = (0 << CS22) | (0 << CS21) | (0 << CS20)

TIMER2_Init:					
	ldi temp, 0x00 				; WGM = 0 (Normal mode, we want an overflow every 1.05 sec)
	sts TCCR2A, temp
	ldi temp, (1 << TOIE2)		; Enable the overflow interrupt
	sts TIMSK2, temp
	clr seconds_passed
	ret

TIMER2_START:
	ldi temp, prescaler	
	sts TCCR2B, temp
	ret

; Interruption routine for Timer2 Overflow
TIMER2_COMP:
	push temp
	in temp, SREG
	push temp
	
	inc counter ; We increase counter with each overflow
	mov temp, counter
	cpi temp, ONE_SECOND ; If counter reaches ONE_SECOND increments, we add a second.
	breq add_second
	
go_back:
	pop temp
	out SREG, temp
	pop temp
	reti

add_second:
	clr counter ; We reset counter
	inc seconds_passed ; We increase seconds by one
	mov temp, seconds_passed
	cpi temp, TIMEOUT 
	brne go_back
	ldi mode, LEDS_ON_DONE ; Once we reach 10 seconds, we set the proper mode 
	ldi temp, stop_clock
	sts TCCR2B, temp
	clr seconds_passed ; Everything related to the counter is reset so its ready for next use
	ldi temp, 0x00 
	sts TCNT2, temp
	rjmp go_back