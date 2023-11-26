
	RELATIVE
	ORG $80600

ADDREG	EQU	$A0000
DATREG	EQU	$A0002


START	AND	#$F8FF,SR
LOOP	BRA	LOOP
	RTS


















