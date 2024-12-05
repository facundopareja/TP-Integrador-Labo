/*
 * twi.asm
 *
 *  Created: 11/22/2024 11:26:57 AM
 *   Author: valen
 */ 

; For a 50 kHz SCL frequency (standard mode): TWBR = (f_CPU/f_SCL - 16)/2*Prescaler = (1MHz/50kHz - 16)/2*1 = 9.
.equ	TWBR_value = 9
; From datashet DS3231 slave address is 0b1101000 = 0x68
; And 0x01 is minutes reg, 0x02 is hours reg
.equ	DS3231_addr = 0b1101000
.equ	min_reg = 0x01
.equ	hr_reg = 0x02

TWI_Init:
	ldi temp, TWBR_value
	sts TWBR, temp
	ldi temp, (0 << TWPS1) | (0 << TWPS0)
	sts TWSR, temp
	ldi temp, (1 << TWEN)
	sts TWCR, temp			; Enable TWI
	ret

; Writing to the DS3231:
TWI_WRITE:
	rcall TWI_START			; 1) Send a START condition.
	; Send Slave Address (Write Mode)
	ldi temp, (DS3231_addr << 1) | 0
	sts TWDR, temp			; 2) Transmit the DS3231 address with the R/W bit (LSB) cleared (write mode).
	rcall TWINT_CLR			; Wait for completion
	ret
TWI_WRITE_MINUTES:
	ldi temp, min_reg
	sts TWDR, temp			; 3) Send the register address we want to write to.
	rcall TWINT_CLR			; Wait for completion
	; Send Data (Minutes)
    sts TWDR, minutes       ; 4) Transmit the data byte to be written.
	rcall TWINT_CLR			; Wait for completion
	ret
TWI_WRITE_HOURS:
	ldi temp, hr_reg
	sts TWDR, temp			; 3) Send the register address we want to write to.
	rcall TWINT_CLR			; Wait for completion
	; Send Data (Hours)
    sts TWDR, hours			; 4) Transmit the data byte to be written.
	rcall TWINT_CLR			; Wait for completion
	rcall TWI_STOP			; 5) Send a STOP condition.
	ret

; Reading from the DS3231:
TWI_READ:
	rcall TWI_START ; 1) Send a START condition.
	; Send Slave Address (Write Mode)
	ldi temp, (DS3231_addr << 1) | 0 
	sts TWDR, temp			; 2) Transmit the DS3231 address with the R/W bit cleared (write mode).
	rcall TWINT_CLR			; Wait for completion
TWI_READ_MINUTES:
	ldi temp, min_reg
	sts TWDR, temp			; 3) Send the register address we want to read from.
	rcall TWINT_CLR			; Wait for completion
	rcall TWI_START			; 4) Send a repeated START condition.
	ldi temp, (DS3231_addr << 1) | 1
	sts TWDR, temp			; 5) Transmit the DS3231 address with the R/W bit set (read mode).
	rcall TWINT_CLR			; Wait for completion
	; Read Data (Minutes)
    lds minutes, TWDR		; 6) Read the data byte.
	rcall TWINT_CLR			; Wait for completion
TWI_READ_HOURS:
	ldi temp, hr_reg
	sts TWDR, temp			; 3) Send the register address we want to read from.
	rcall TWINT_CLR			; Wait for completion
	rcall TWI_START			; 4) Send a repeated START condition.
	ldi temp, (DS3231_addr << 1) | 1
	sts TWDR, temp			; 5) Transmit the DS3231 address with the R/W bit set (read mode).
	rcall TWINT_CLR			; Wait for completion
	; Read Data (Minutes)
    lds hours, TWDR			; 6) Read the data byte.
	rcall TWINT_CLR			; Wait for completion	
	rcall TWI_STOP			; 7) Send a STOP condition.
	ret

TWI_START:
	; TWI Start condition + clear TWINT flag
	ldi temp, (1 << TWINT) | (1 << TWSTA) | (1 << TWEN)
	sts TWCR, temp
	rjmp WAIT_COMPLETION
TWINT_CLR:
	ldi temp, (1 << TWEN) | (1 << TWINT)
    sts TWCR, temp
WAIT_COMPLETION:
	lds temp, TWCR
	sbrc temp, TWINT			; Wait until the operation to complete. 
	rjmp WAIT_COMPLETION
	ret
TWI_STOP:
	; TWI Stop condition + clear TWINT flag
	ldi temp, (1 << TWINT) | (1 << TWSTO) | (1 << TWEN)
	sts TWCR, temp
	ret