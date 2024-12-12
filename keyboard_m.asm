;puerto D separado en entradas de PIND0 a PIND3, y en salidas de PORTD4 a PORTD7
;entradas en pullup, en etapa de deteccion las salidas en 0, en etapa de busqueda salidas en 1 y rotando


.def 	tecla = 			r20
.def 	contador = 			r8
.def 	valor = 			r10

.equ 	teclado_ini = 	0b11110111
.equ 	teclado_fin = 	0b01111111

.equ 	TECLA_1 = 		0b11101110
.equ 	TECLA_2 = 		0b11101101
.equ 	TECLA_3 = 		0b11101011
.equ 	TECLA_4 = 		0b11011110
.equ 	TECLA_5 = 		0b11011101
.equ 	TECLA_6 = 		0b11011011
.equ 	TECLA_7 = 		0b10111110
.equ 	TECLA_8 = 		0b10111101
.equ 	TECLA_9 = 		0b10111011
.equ 	TECLA_0 = 		0b01111101
.equ 	TECLA_A = 		0b11100111
.equ 	TECLA_B = 		0b11010111
.equ 	TECLA_C = 		0b10110111
.equ 	TECLA_D =		0b01110111
.equ 	TECLA_ast = 	0b01111110
.equ 	TECLA_NUM = 	0b01111011


branch_detec:
 	clr contador

	ldi YL, low(passwordRAM)
	ldi YH, high(passwordRAM)

stand_by:
 	cpi mode, STNBY_STATE
 	breq stand_by

detectando:
	inc contador

	clr tecla

	call buscar_tecla
	call decod_tecla
	call guardar_psw

	cpi tecla, 0xFF
	breq end_detectando

	mov temp, contador
	cpi temp, PSW_LIM
	breq end_detectando

	cpi mode, DET_STATE
	brne end_detectando

	ldi mode, STNBY_STATE
	rjmp stand_by 							;se queda detectando hasta que algo lo haga cambiar de estado

end_detectando:
	call validar_psw

	ldi mode, LOCK_STATE

	ret

buscar_tecla:
	lds temp, PCICR
	andi temp, ~(1<<PCIE1)
	sts PCICR, temp								;deshabilito PC del puerto 1

	ldi tecla, teclado_ini

busc_fila:
	sec
	rol tecla

	in temp, PORTD ;(11110000)
	ori temp, msk_entrada
	and temp, tecla
	out PORTD, temp

	nop
	nop

	sbis PINC, PINC0
	rjmp pars_busc
	sbis PINC, PINC1
	rjmp pars_busc
	sbis PINC, PINC2
	rjmp pars_busc
	sbis PINC, PINC3
	rjmp pars_busc

	cpi tecla, teclado_fin
	breq error_busc								;entrar acá es que no hay boton apretado, tecla quedaría en teclado_fin

	rjmp busc_fila

error_busc:
	ser tecla
	rjmp end_busc

pars_busc:
	in temp, PINC 								;PIND debería tener un solo bit en 0 entre los bits 0 y 3
	ori temp, msk_entrada
	and tecla, temp								;solo quedan dos 0s

end_busc:
	in temp, PCIFR
	ori temp, (1<<PCIF1)
	out PCIFR, temp								;limpio el flag de interrupcion

	lds temp, PCICR
	ori temp, (1<<PCIE1)
	sts PCICR, temp								;habilitar PC del puerto 1

	ret

decod_tecla:
	ldi temp, '0'
	cpi tecla, TECLA_0
	breq end_decod

	inc temp
	cpi tecla, TECLA_1
	breq end_decod

	inc temp
	cpi tecla, TECLA_2
	breq end_decod

	inc temp
	cpi tecla, TECLA_3
	breq end_decod

	inc temp
	cpi tecla, TECLA_4
	breq end_decod
	
	inc temp
	cpi tecla, TECLA_5
	breq end_decod
	
	inc temp
	cpi tecla, TECLA_6
	breq end_decod
	
	inc temp
	cpi tecla, TECLA_7
	breq end_decod
	
	inc temp
	cpi tecla, TECLA_8
	breq end_decod
	
	inc temp
	cpi tecla, TECLA_9
	breq end_decod

	ldi temp, 'A'
	cpi tecla, TECLA_A
	breq end_decod

	inc temp
	cpi tecla, TECLA_B
	breq end_decod

	inc temp
	cpi tecla, TECLA_C
	breq end_decod

	inc temp
	cpi tecla, TECLA_D
	breq end_decod

	ldi temp, '*'
	cpi tecla, TECLA_ast
	breq end_decod

	ldi temp, '#'
	cpi tecla, TECLA_num
	breq end_decod
	
	ldi temp, 0xFF

end_decod:
	mov tecla, temp
	ret

guardar_psw:
	cpi mode, LOCK_STATE
	breq end_guardando

	cpi tecla, 0xFF
	breq end_guardando

	st Y+, tecla 											;guarda el ascii en la memoria sram

	mov temp, tecla
	call USART_Transmit										;saca el valor de la tecla (en ascii) por USART

end_guardando:
	ret

validar_psw:
	cpi mode, LOCK_STATE
	breq incorrecto

	cpi tecla, 0xFF
	breq incorrecto

	clr eeprom_address_low
	clr eeprom_address_high

	ldi YL, low(passwordRAM)
	ldi YH, high(passwordRAM)

validando:
	dec contador

	ld temp, Y+
	call EEPROM_READ
	mov valor, eeprom_dato
	inc eeprom_address_low

	cp temp, valor
	brne incorrecto

	mov temp, contador
	cpi temp, 0x00
	brne validando

correcto:
	sbi PORTB, PB4
	ldi mode, LEDS_ON_WAITING
	call OPEN_LOCK
	call LOADING_CURRENT_TIME
	call TIMER2_START
	call loop_leds_on
	call CLOSE_LOCK
	cbi PORTB, PB4
	rjmp end_validar

incorrecto:
	sbi PORTB, PB5
	ldi mode, LEDS_ON_WAITING
	call TIMER2_START
	call loop_leds_on
	cbi PORTB, PB5

end_validar:
	ret

inicio_conteo: 										;temp, contador
	clr temp
	out TCNT0, temp									;reinicio el contador

	in temp, TCCR0A
	andi temp, ~(0b11<<WGM00)						;modo normal
	out TCCR0A, temp

	in temp, TCCR0B
	andi temp, ~msk_prescaler
	ori temp, clk_antireb
	andi temp, ~(1<<WGM02)							;modo normal
	out TCCR0B, temp								;inicia el conteo, clk/1024

	lds temp, PCMSK1
	andi temp, msk_entrada							;deshabilito los puertos de entrada para interrupcion de PC
	sts PCMSK1, temp

	ret

INT_teclado:
	push temp
	in temp, sreg
	push temp

	call inicio_conteo

	in temp, PORTD
	andi temp, ~msk_entrada
	out PORTD, temp

	in valor, PINC
	ldi temp, ~msk_entrada							;guardo el valor de las entradas en entrada_capturada
	and valor, temp

	pop temp
	out sreg, temp
	pop temp

	reti

INT_timer0:
	push temp
	in temp, sreg
	push temp

	in temp, PCIFR
	ori temp, (1<<PCIF1)
	out PCIFR, temp								;limpio el flag de interrupcion

	lds temp, PCMSK1
	ori temp, ~msk_entrada						;vuelvo a habilitar los puertos de entrada para interrupcion de PC
	sts PCMSK1, temp

	in temp, TCCR0B
	andi temp, ~msk_prescaler
	out TCCR0B, temp							;detengo el contador
	
	in temp, PORTD
	andi temp, ~msk_entrada
	out PORTD, temp

	in temp, PINC
	andi temp, ~msk_entrada

	cpi temp, 0x0F
	breq end_timer0

	cp temp, valor
	brne end_timer0								;si el cambio que detectó sigue estando

	ldi mode, DET_STATE							;el cambio a realizar, para que el main detecte y haga

end_timer0:
	pop temp
	out sreg, temp
	pop temp

	reti

loop_leds_on:
	cpi mode, LEDS_ON_DONE
	brne loop_leds_on
	ret