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
	sbic EECR,EEPE ; Loop until last write is done
	rjmp EEPROM_write
	out EEARH, eeprom_address_high ; We set address to be used to store data in.
	out EEARL, eeprom_address_low
	out EEDR, eeprom_dato ; We write data present in eeprom_dato
	sbi EECR,EEMPE ; Need to set these two bits in order
	sbi EECR,EEPE ; EEPE has to be written before 4 MC
	ret

EEPROM_READ:
    sbic EECR,EEPE; Loop until last write is done
    rjmp EEPROM_read
    out EEARH, eeprom_address_high
    out EEARL, eeprom_address_low
    sbi EECR,EERE ; Need to write a 1 here before we can read
    in eeprom_dato, EEDR ; We read into register
    ret	