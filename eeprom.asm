/*
 * eeprom.asm
 *
 *  Created: 17/11/2024 21:19:14
 *   Author: Facundo
 */ 
 .DEF eeprom_address_low = r14
 .DEF eeprom_address_high = r15
 .DEF eeprom_dato=r13

.cseg
EEPROM_WRITE:
	sbic EECR,EEPE ; Se loopea hasta que el dato anterior este escrito
	rjmp EEPROM_write
	out EEARH, eeprom_address_high ; Seteo direccion donde voy a guardar informacion
	out EEARL, eeprom_address_low
	out EEDR, eeprom_dato ; Guardo el valor de eeprom_dato
	sbi EECR,EEMPE ; Necesario setear estos dos bits en orden.
	sbi EECR,EEPE ; Se escribe EEPE antes de que pasen 4CM
	ret

EEPROM_READ:
    sbic EECR,EEPE; Se loopea hasta que el dato anterior este escrito
    rjmp EEPROM_read
    out EEARH, eeprom_address_high
    out EEARL, eeprom_address_low
    sbi EECR,EERE ; Necesario escribir un 1 antes de poder leer
    in eeprom_dato, EEDR ; Se carga valor
    ret	