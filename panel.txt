;puerto D separado en entradas de PIND0 a PIND3, y en salidas de PORTD4 a PORTD7
;entradas en pullup, en etapa de deteccion las salidas en 0, en etapa de busqueda salidas en 1 y rotando



.def 	eeprom_add_L = 		r14
.def 	eeprom_add_H = 		r15
.def 	aux = 				r16
.def 	value_received = 	r18
.def 	tecla = 			r20
.def 	contador = 			r3

.equ 	msk_entrada = 	0b11110000
.equ 	msk_prescaler = 0b00000111
.equ 	clk_antireb = 	0b00000101
.equ 	teclado_ini = 	0b11101111
.equ 	teclado_fin = 	0b01111111

.equ 	TECLA_0 = 		0b11101110
.equ 	TECLA_1 = 		0b11101101
.equ 	TECLA_2 = 		0b11101011
.equ 	TECLA_3 = 		0b11100111
.equ 	TECLA_4 = 		0b11011110
.equ 	TECLA_5 = 		0b11011101
.equ 	TECLA_6 = 		0b11011011
.equ 	TECLA_7 = 		0b11010111
.equ 	TECLA_8 = 		0b10111110
.equ 	TECLA_9 = 		0b10111101
.equ 	PSW_LIM = 			4

.equ 	STNBY_STATE = 		0b00010000
.equ 	DET_STATE = 		0b00000010
.equ 	STD_STATE = 		0b00000001

.dseg

.org SRAM_START
passwordRAM: .byte PSW_LIM

.org PCI2addr
	rjmp INT_teclado

.org OC0Aaddr
	rjmp INT_timer0

;en main

	ldi aux, msk_entrada
	out DDRD, aux

	ldi aux, ~msk_entrada						;pullup y salidas en 0
	out PORTD, aux

inicio_conteo: 									;aux, contador
	clr aux
	out TCNT0, aux								;reinicio el contador

	in aux, TCCR0B
	andi aux, ~msk_prescaler
	ori aux, clk_antireb
	out TCCR0B, aux								;inicia el conteo, clk/1024

	lds aux, PCMSK2
	andi aux, msk_entrada						;deshabilito los puertos de entrada para interrupcion de PC
	sts PCMSK2, aux

	ret

loop:
	cpi mode, DET_STATE
	breq branch_detec
	rjmp loop

branch_detec:
 	clr passwordL
 	clr passwordH
 	clr contador

 	ldi YL, low(passwordRAM)
 	ldi YH, high(passwordRAM)

stand_by:
 	cpi mode, STNBY_STATE
 	breq stand_by

detectando:
	inc contador
	call buscar_tecla
	call decod_tecla ;son ascii
	call guardar_psw
	call validar_psw

	cpi mode, STD_STATE
	breq loop

	ldi mode, STNBY_STATE

	rjmp stand_by 							;se queda detectando hasta que algo lo haga cambiar de estado

buscar_tecla:
	ldi tecla, teclado_ini
	sec

busc_fila:
	sbis PIND, PIND0
	rjmp end_busc
	sbis PIND, PIND1
	rjmp end_busc
	sbis PIND, PIND2
	rjmp end_busc
	sbis PIND, PIND3
	rjmp end_busc

	cpi tecla, teclado_fin
	breq end_busc 								;entrar acá es que no hay boton apretado, tecla quedaría en teclado_fin

	rol tecla
	rjmp busc_fila

end_busc:
	in aux, PIND 								;PIND debería tener un solo bit en 0 entre los bits 0 y 3
	and tecla, aux								;solo quedan dos 0s

	ret

decod_tecla:
	ldi aux, '0'
	cpi tecla, TECLA_0
	breq end_decod

	inc aux
	cpi tecla, TECLA_1
	breq end_decod

	inc aux
	cpi tecla_TECLA_3
	breq end_decod

	inc aux
	cpi tecla_TECLA_4
	breq end_decod
	
	inc aux
	cpi tecla_TECLA_5
	breq end_decod
	
	inc aux
	cpi tecla_TECLA_6
	breq end_decod
	
	inc aux
	cpi tecla_TECLA_7
	breq end_decod
	
	inc aux
	cpi tecla_TECLA_8
	breq end_decod
	
	inc aux
	cpi tecla_TECLA_9
	breq end_decod
	
	ldi estado, STD_STATE
	ldi aux, 0xFF

end_decod:
	mov tecla, aux
	ret

guardar_psw:
	cpi contador, PSW_LIM 						;si es el cuarto número ingresado, modifico modo a normal
	brne end_guardado

	ldi mode, STD_STATE

end_guardando:
	st Y+, tecla

	ret

validar_psw:
	cpi contador, PSW_LIM
	brne end_validar

	ldi XL, low(eeprom_add_L)
	ldi XH, high(eeprom_add_H)

	ldi YL, low(passwordRAM)
	ldi YH, high(passwordRAM)

validando:
	dec contador

	ld aux, Y+
	ld value_received, X+

	cp aux, value_received
	brne incorrecto

	cp contador, 0x00
	brne validando

correcto:
	;call abrir_cerradura
	in aux, PORTB
	ori aux, (1<<PORTB4)
	out PORTB, aux

	rjmp end_validar

incorrecto:
	in aux, PORTB
	ori aux, (1<<PORTB5)
	our PORTB, aux

end_validar:
	ret


INT_teclado:
	push aux
	in aux, sreg
	push aux

	call inicio_conteo

	in value_received, PIND
	andi value_received, ~msk_entrada		;guardo el valor de las entradas en entrada_capturada

	pop aux
	out sreg, aux
	pop aux

	reti

INT_timer0:
	push aux
	in aux, sreg
	push aux

	lds aux, PCMSK2
	ori aux, msk_entrada					;vuelvo a habilitar los puertos de entrada para interrupcion de PC
	sts PCMSK2, aux

	in aux, TCCR0B
	andi aux, ~msk_prescaler
	out TCCR0B, aux							;detengo el contador

	in aux, PIND
	andi aux, ~msk_entrada

	cpi aux, 0x00
	breq end_timer0
	cp aux, value_received
	brne end_timer0							;si el cambio que detectó sigue estando

	ldi estado, DET_STATE						;el cambio a realizar, para que el main detecte y haga

end_timer0:
	pop aux
	out sreg, aux
	pop aux

	reti