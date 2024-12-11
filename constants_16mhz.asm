/*
 * constants_16mhz.asm
 *
 *  Created: 12/9/2024 12:56:35 PM
 *   Author: Facundo
 */ 

; Servo
.equ	OCR1A_min = 124			; OCR1A_min = 1MHz*0.5ms/1 - 1 VALOR_PARA_1MHZ = 499
.equ	OCR1A_central = 374			; OCR1A_central = 1MHz*1.5ms/1 - 1 - VALOR PARA 1 MHZ = 1499
.equ	OCR1A_max = 624				; OCR1A_max = 1MHz*2.5ms/1 - 1 - VALOR PARA 1 MHZ = 2499
.equ	ICR1_val = 4999				; ICR1 = 1MHz/1*50Hz - 1	VALOR PARA 1MHZ = 20000 

;Timer 2
.equ	ONE_SECOND = 61
.equ	TIMEOUT = 10  

; Keyboard
.equ 	clk_antireb = 	0b00000101
.equ 	msk_prescaler = 0b00000111
