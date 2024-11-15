.include "usart.asm"
;
; TP Integrador.asm
;
; Created: 15/11/2024 08:18:40
; Author : Facundo
;
CONFIGURATION:
; Configuracion inicial
	rcall USART_Init
	ldi r16, 0

; Replace with your application code
start:
    rcall USART_Transmit
	inc r16
    rjmp start
