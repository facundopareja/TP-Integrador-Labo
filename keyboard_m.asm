;puerto D separado en entradas de PIND0 a PIND3, y en salidas de PORTD4 a PORTD7
;entradas en pullup, en etapa de deteccion las salidas en 0, en etapa de busqueda salidas en 1 y rotando



.def 	tecla = 			r20
.def 	contador = 			r8

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

inicio_conteo: 									;temp, contador
	clr temp
	out TCNT0, temp								;reinicio el contador

	in temp, TCCR0B
	andi temp, ~msk_prescaler
	ori temp, clk_antireb
	out TCCR0B, temp								;inicia el conteo, clk/1024

	lds temp, PCMSK2
	andi temp, msk_entrada						;deshabilito los puertos de entrada para interrupcion de PC
	sts PCMSK2, temp

	ret

branch_detec:
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

	cpi mode, LOCK_STATE
	in temp, sreg
	sbrc temp, sreg_z
	ret

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
	in temp, PIND 								;PIND debería tener un solo bit en 0 entre los bits 0 y 3
	and tecla, temp								;solo quedan dos 0s

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
	
	ldi mode, LOCK_STATE
	ldi temp, 0xFF

end_decod:
	mov tecla, temp
	ret

guardar_psw:
	mov temp, contador
	cpi temp, PSW_LIM 						;si es el cuarto número ingresado, modifico modo a normal
	brne end_guardando

	ldi mode, LOCK_STATE

end_guardando:
	st Y+, tecla
	mov temp, tecla
	rcall USART_Transmit

	ret

validar_psw:
	mov temp, contador
	cpi temp, PSW_LIM
	brne end_validar

	clr eeprom_address_low
	clr eeprom_address_high

	ldi YL, low(passwordRAM)
	ldi YH, high(passwordRAM)

validando:
	dec contador

	ld temp, Y+
	call EEPROM_READ
	mov value_received, eeprom_dato
	inc eeprom_address_low

	cp temp, value_received
	brne incorrecto

	mov temp, contador
	cpi temp, 0x00
	brne validando

correcto:
	rcall OPEN_LOCK
	in temp, PORTB
	ori temp, (1<<PORTB4)
	out PORTB, temp

	rjmp end_validar

incorrecto:
	in temp, PORTB
	ori temp, (1<<PORTB5)
	out PORTB, temp

end_validar:
	ret

INT_teclado:
	push temp
	in temp, sreg
	push temp

	call inicio_conteo

	in value_received, PIND
	andi value_received, ~msk_entrada		;guardo el valor de las entradas en entrada_capturada

	pop temp
	out sreg, temp
	pop temp

	reti

INT_timer0:
	push temp
	in temp, sreg
	push temp

	lds temp, PCMSK2
	ori temp, msk_entrada					;vuelvo a habilitar los puertos de entrada para interrupcion de PC
	sts PCMSK2, temp

	in temp, TCCR0B
	andi temp, ~msk_prescaler
	out TCCR0B, temp							;detengo el contador

	in temp, PIND
	andi temp, ~msk_entrada

	cpi temp, 0x0F
	breq end_timer0
	cp temp, value_received
	brne end_timer0							;si el cambio que detectó sigue estando

	ldi mode, DET_STATE						;el cambio a realizar, para que el main detecte y haga

end_timer0:
	pop temp
	out sreg, temp
	pop temp

	reti
