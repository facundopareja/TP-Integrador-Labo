/*
 * sec_test.asm
 *
 *  Created: 12/5/2024 9:59:22 PM
 *   Author: mathe
 */ 

 /*
 * twi.asm
 *
 *  Created: 11/22/2024 11:26:57 AM
 *   Author: valen
 */ 

; For a 50 kHz SCL frequency (standard mode): TWBR = (f_CPU/f_SCL - 16)/2*Prescaler = (1MHz/50kHz - 16)/2*1 = 2.
; For a 100 kHz SCL frequency (standard mode): TWBR = (f_CPU/f_SCL - 16)/2*Prescaler = (16MHz/100kHz - 16)/2*1 = 72.
.equ	TWBR_value = 72 ; 2 - 1 mhz
; From datashet DS3231 7-bit slave address is 0b1101000 = 0x68
; And 0x01 is minutes reg, 0x02 is hours reg
.equ	DS3231_addr = 0b1101000
.equ	min_reg = 0x01
.equ	hr_reg = 0x02
.equ	ALT_START = 0x08
.equ	REPEATED_START = 0x10
.equ	MT_SLA_ACK = 0x18
.equ	MT_DATA_ACK = 0x28
.equ	MR_SLA_ACK = 0x40
.equ	MR_DATA_ACK = 0x50

TWI_Init:
	ldi temp, TWBR_value
	sts TWBR, temp
	ldi temp, (0 << TWPS1) | (0 << TWPS0)	; Prescaler = 1
	sts TWSR, temp
	ldi temp, (1 << TWEN)
	sts TWCR, temp			; Enable TWI
	ret

; Writing to the DS3231:
TWI_WRITE:
	rcall TWI_START			; Send a START condition.
	rcall TWSR_START_Check
	; Send Slave Address (Write Mode)
	ldi temp, (DS3231_addr << 1) | (0 << TWGCE)
	sts TWDR, temp			; Transmit the DS3231 address with the R/W bit (LSB) cleared (write mode).
	rcall TWSR_SLAW_ACK_Check ; Check if SLA transmit correct
TWI_WRITE_MINUTES:
	ldi temp, min_reg
	sts TWDR, temp			; Send the register address we want to write to.
	rcall TWINT_CLR			; Wait for completion
	; Send Data (Minutes)
    sts TWDR, minutes       ; Transmit the data byte to be written.
	rcall TWSR_DataT_ACK_Check ; Check if Data transmit correct

TWI_WRITE_HOURS:
	ldi temp, hr_reg
	sts TWDR, temp			; Send the register address we want to write to.
	rcall TWINT_CLR			; Wait for completion
	; Send Data (Hours)
    sts TWDR, hours			; Transmit the data byte to be written.
	rcall TWSR_DataT_ACK_Check ; Check if Data transmit correct
	rcall TWI_STOP			; Send a STOP condition.
	ret

; Reading from the DS3231:
TWI_READ:
	rcall TWI_START ; Send a START condition.
	rcall TWSR_START_Check
	; Send Slave Address (Write Mode)
	ldi temp, (DS3231_addr << 1) | (0 << TWGCE) 
	sts TWDR, temp			; Transmit the DS3231 address with the R/W bit cleared (write mode).
	rcall TWSR_SLAW_ACK_Check ; Check if sla + w transmitted ok

TWI_READ_MINUTES:
	ldi temp, min_reg
	sts TWDR, temp			; Send the register address we want to read from.
	rcall TWSR_SLAW_ACK_Check	; Wait for completion for sla + w transmitted
	rcall TWI_START			; Send a repeated START condition.
	rcall TWSR_Repeated_START_Check ; Check if all well
	ldi temp, (DS3231_addr << 1) | (1 << TWGCE)
	sts TWDR, temp			; Transmit the DS3231 address with the R/W bit set (read mode).
	rcall TWSR_SLAR_ACK_Check	; Wait for completion for sla + r transmitted
	; Read Data (Minutes)
	rcall SEND_ACK			; I let the slave know that I'm ready to receive first byte
	rcall TWSR_DataR_ACK_Check	; Wait for completion for data received
    lds minutes, TWDR		; Read the data byte.
TWI_READ_HOURS:
	ldi temp, hr_reg
	sts TWDR, temp			; Send the register address we want to read from.
	rcall TWSR_SLAW_ACK_Check	; Wait for completion for sla + r transmitted
	rcall TWI_START			; Send a repeated START condition.
	rcall TWSR_Repeated_START_Check ; Check if all well
	ldi temp, (DS3231_addr << 1) | 1
	sts TWDR, temp			; Transmit the DS3231 address with the R/W bit set (read mode).
	rcall TWSR_SLAR_ACK_Check	; Wait for completion for sla + r transmitted
	; Read Data (Hours)
	rcall SEND_NACK
	rcall TWSR_DataR_ACK_Check	; Wait for completion for data received
    lds hours, TWDR			; Read the data byte.
	rcall TWI_STOP			; Send a STOP condition.
	ret
TWI_ERROR:
	rjmp TWI_ERROR_TRANSMIT
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
TWI_ERROR_TRANSMIT:
	lds temp, UCSR0A
	sbrs temp, UDRE0
	rjmp TWI_ERROR_TRANSMIT
	ldi temp, 'E'
	rcall USART_Transmit
	ret
TWSR_Check:
	lds temp, TWSR			; Check value of TWI Status Register.
	andi temp, 0b11111000	; Mask prescaler bits.  
	ret
TWSR_START_Check:
	rcall TWSR_Check
	cpi temp, START
	brne TWI_ERROR			; If status different from START (0x08) go to ERROR.
	ret
TWSR_Repeated_START_Check:
	rcall TWSR_Check
	cpi temp, REPEATED_START
	brne TWI_ERROR			; If status different from START (0x08) go to ERROR.
	ret
TWSR_SLAW_ACK_Check:
	rcall TWINT_CLR			; Wait for completion
	rcall TWSR_Check
	cpi temp, MT_SLA_ACK
	brne TWI_ERROR			; If status different from MT_SLA_ACK (0x18) go to ERROR.
	ret
TWSR_DataT_ACK_Check:
	rcall TWINT_CLR			; Wait for completion
	rcall TWSR_Check
	cpi temp, MT_DATA_ACK
	brne TWI_ERROR			; If status different from MT_Data_ACK (0x28) go to ERROR.
	ret
TWSR_SLAR_ACK_Check:
	rcall TWINT_CLR			; Wait for completion
	rcall TWSR_Check
	cpi temp, MR_SLA_ACK
	brne TWI_ERROR			; If status different from MT_SLA_ACK (0x18) go to ERROR.
	ret
TWSR_DataR_ACK_Check:
	rcall TWINT_CLR			; Wait for completion
	rcall TWSR_Check
	cpi temp, MR_DATA_ACK
	brne TWI_ERROR			; If status different from MT_Data_ACK (0x28) go to ERROR.
	ret

SEND_ACK:
	ldi temp, (1 << TWEN) | (1 << TWEA) | (1 << TWINT)
	sts TWCR, temp
	ret

SEND_NACK:
	ldi temp, (1 << TWEN) | (0 << TWEA) | (1 << TWINT)
	sts TWCR, temp
	ret
