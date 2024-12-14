/*
 * constants_16mhz.asm
 *
 *  Created: 12/9/2024 12:56:35 PM
 *   Author: Facundo
 */ 

; Servo
.equ	OCR1A_min = 124			; OCR1A_min = 1MHz*0.5ms/1 - 1
.equ	OCR1A_central = 374			; OCR1A_central = 1MHz*1.5ms/1 - 1
.equ	OCR1A_max = 624				; OCR1A_max = 1MHz*2.5ms/1 - 1 
.equ	ICR1_val = 4999				; ICR1 = 1MHz/1*50Hz - 1	

;Timer 2
.equ	ONE_SECOND = 61
.equ	TIMEOUT = 10  

; Keyboard
.equ 	clk_antireb = 	0b00000101
.equ 	msk_prescaler = 0b00000111

; TWI
;For a 50 kHz SCL frequency (standard mode): TWBR = (f_CPU/f_SCL - 16)/2*Prescaler = (1MHz/50kHz - 16)/2*1 = 2.
; For a 100 kHz SCL frequency (standard mode): TWBR = (f_CPU/f_SCL - 16)/2*Prescaler = (16MHz/100kHz - 16)/2*1 = 72.
.equ	TWBR_value = 36 

; USART
 ; Baud rate set to 9600 
.equ valor_UBRRn=103