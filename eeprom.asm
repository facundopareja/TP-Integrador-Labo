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
	sbic EECR,EEPE ; Loop until previous data is written.
	rjmp EEPROM_write
	out EEARH, eeprom_address_high ; We set an address to store information at.
	out EEARL, eeprom_address_low
	out EEDR, eeprom_dato ; We write value in eeprom_dato.
	sbi EECR,EEMPE ; These 2 bits need to be set.
	sbi EECR,EEPE ; EEPE has to be set before 4 machine cycles occur.
	ret

EEPROM_READ:
    sbic EECR,EEPE; Loop until previous data is written.
    rjmp EEPROM_read
    out EEARH, eeprom_address_high ; We set an address to store information at.
    out EEARL, eeprom_address_low
    sbi EECR,EERE ; Need to write a 1 to EERE before we can read.
    in eeprom_dato, EEDR ; We load value to eeprom_dato.
    ret	