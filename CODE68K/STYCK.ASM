	RELATIVE
	ORG $80600
;
;-------------------------------------
;
;
; SuperStar Slot
; Programmer: Francis Styck
; Octorber 15, 1988
;
;  Object shapes : VGAOBJCT.PIC and VGA2OBJ.PIC loaded at $1F400
;  Main screen	 : TREESCRN.PIC loaded at $00000
;
;
ADDREG	EQU	$A0000		; ADDRESS REGISTER OF GRAPHICS CHIP
DATREG	EQU	$A0002		; DATA REGISTER OF GRAPHICS CHIP

DAC	EQU	$A0800		; ADDRESS OF DAC

HSYNCV	EQU	$800BC		; HORIZONTAL SYNC VECTOR ADDRESS
VBLNKV	EQU	$800B0		; VERTICAL BLANK VECTOR ADDRESS

REELCLR EQU	$80500		; TABLE OF REEL COLORS

;-----------------------
; GRAPHICS CHIP COMMANDS
;-----------------------

CAGCPY	EQU	$E000
CAMOVE	EQU	$8000
CWPR	EQU	$0800
CAFRCT	EQU	$C000
CALINE	EQU	$8800
CCPY	EQU	$6000

;--------------------------------------------------------------

NUMOBJ	EQU	23		; NUMBER OF OBJECTS ON REEL

RWIDTH	EQU	100		; WIDTH OF REEL
RLNGTH	EQU	160		; LENGTH OF REEL
RSPACE	EQU	22		; SPACE BETWEEN REELS

OBJW	EQU	72		; WIDTH OF OBJECTS
OBJH	EQU	40		; HEIGHT OF OBJECT  39
OBJSP	EQU	10		; OBJECT SPACING


OBJR1X	EQU	155		; LEFT X VALUE FOR REEL 1 OBJECTS
OBJR2X	EQU	278		; LEFT X VALUE FOR REEL 2 OBJECTS
OBJR3X	EQU	396		; LEFT X VALUE FOR REEL 3 OBJECTS

;-----------------------
; MACROS
;-----------------------

AFRCT	.MACRO	ARG1,ARG2,ARG3
	MOVE	#(CAFRCT+ARG1),D0
	BSR	SENDIT
	MOVE	ARG2,D0
	BSR	SENDIT
	MOVE	ARG3,D0
	BSR	SENDIT
	.ENDM

;--------------------------------------------

AGCPY	.MACRO	ARG1,ARG2,ARG3,ARG4,ARG5
	MOVE	#CAGCPY+ARG1,D0
	BSR	SENDIT
	MOVE	ARG2,D0
	BSR	SENDIT
	MOVE	ARG3,D0
	BSR	SENDIT
	MOVE	ARG4,D0
	BSR	SENDIT
	MOVE	ARG5,D0
	BSR	SENDIT
	.ENDM

;--------------------------------------------

AGCPY2	.MACRO	ARG1,ARG2,ARG3
	MOVE	#CAGCPY+ARG1,D0
	BSR	SENDIT

	MOVE.W	(A0)+,D0	;GET DATA FROM TABLE
	BSR	SENDIT

	MOVE.W	(A0),D0 	;GET DATA FROM TABLE
	BSR	SENDIT

	MOVE	ARG2,D0
	BSR	SENDIT
	MOVE	ARG3,D0
	BSR	SENDIT
	.ENDM

;--------------------------------------------

AMOVE	.MACRO	ARG1,ARG2
	MOVE	#CAMOVE,D0
	BSR	SENDIT
	MOVE	ARG1,D0
	BSR	SENDIT
	MOVE	ARG2,D0
	BSR	SENDIT
	.ENDM

;--------------------------------------------

ALINE	.MACRO	ARG1,ARG2
	MOVE	#CALINE,D0
	BSR	SENDIT
	MOVE	ARG1,D0
	BSR	SENDIT
	MOVE	ARG2,D0
	BSR	SENDIT
	.ENDM

;--------------------------------------------

WPR	.MACRO	ARG1,ARG2
	MOVE	#CWPR+ARG1,D0
	BSR	SENDIT
	MOVE	ARG2,D0
	BSR	SENDIT
	.ENDM

;--------------------------------------------
;  Start of main routine
;--------------------------------------------

START
	MOVE	#$4EF9,D0	; BYTE FOR JUMP INSTRUCTION
	MOVE	D0,HSYNCV	; INTO HSYNC VECTOR
	MOVE	D0,VBLNKV	; INTO VBLANK VECTOR

	LEA	HSYNC,A0	; GET ADDRESS OF OUR HSYNC ROUTINE
	MOVE.L	A0,HSYNCV+2	; POINT TO OUR ROUTINE

	LEA	VBLNK,A0	; GET ADDRESS OF OUR VBLNK ROUTINE
	MOVE.L	A0,VBLNKV+2	; POINT TO OUR ROUTINE

	MOVE.L	#REELCLR,CLRLOC ; POINT TO THE COLOR TABLE

	MOVE.L	#2,RL1SKIP	; Speed to spin reels
	MOVE.L	#2,RL2SKIP	; 4 - fast  2 - med  3 - slow
	MOVE.L	#2,RL3SKIP

	MOVE.L	#0,RL1SCNL
	MOVE.L	#0,RL2SCNL
	MOVE.L	#0,RL3SCNL

;;;;;	BSR	SETCLRS 	; SETUP THE PALETTE


; SETUP INTERUPT (CURSOR POSITION)

	MOVE	#$E8,ADDREG	; SETUP CURSOR DEFENITION REGISTER
	MOVE	#$B000,DATREG

	MOVE	#$9A,ADDREG	; SETUP GRAPHIC CURSOR REGISTER
	MOVE	#33,DATREG	; 26 DOWN
	MOVE	#240,DATREG	; 104 DOWN

	MOVE	#$98,ADDREG	; SET CURSOR X START AND END
	MOVE	#$A095,DATREG	; X LOCATION OF INTERUPT 95 TO A0

	AND	#$F8FF,SR	; TURN ON ALL INTERUPPTS


;-----------------------------------------------------------------------
;  Starting addresses for objects on the reels


	MOVE.L	#($40000000+(-29*16*320)),OBJ1R1Y	:Reel 1
	MOVE.L	#($40000000+((10+(1*OBJSP))*16*320)),OBJ2R1Y
	MOVE.L	#($40000000+((49+(2*OBJSP))*16*320)),OBJ3R1Y
	MOVE.L	#($40000000+((88+(3*OBJSP))*16*320)),OBJ4R1Y

	MOVE.L	#($40000000+(-29*16*320)),OBJ1R2Y	;Reel 2
	MOVE.L	#($40000000+((10+(1*OBJSP))*16*320)),OBJ2R2Y
	MOVE.L	#($40000000+((49+(2*OBJSP))*16*320)),OBJ3R2Y
	MOVE.L	#($40000000+((88+(3*OBJSP))*16*320)),OBJ4R2Y

	MOVE.L	#($40000000+(-29*16*320)),OBJ1R3Y	;Reel 3
	MOVE.L	#($40000000+((10+(1*OBJSP))*16*320)),OBJ2R3Y
	MOVE.L	#($40000000+((49+(2*OBJSP))*16*320)),OBJ3R3Y
	MOVE.L	#($40000000+((88+(3*OBJSP))*16*320)),OBJ4R3Y


	BSR	DRWREEL 		; DRAW THE REELS
;;;;;	BSR	FACEPLT 		; DRAW FACE PLATE AROUND REELS

	BSR	TOPRL1			; POINT TO BEGINING OF REEL 1
	BSR	TOPRL2			;		       REEL 2
	BSR	TOPRL3			;		       REEL 3


	MOVE.L	#(160*OBJH),D5		; NUMBER OF TIMES TO SPIN

;-----------------------------------------------------------------------
;
; Main Loop of spinning the reels
;

CHRLP

;------------
;  SLOW THINGS DOWN

	MOVE.L	#$FF,D4 	 ; NUMBER OF TIMES TO LOOP
LOOP
	DBRA	D4,LOOP

;-----------------------------------------------------------------------
;  REEL 1

	MOVE.L	#-OBJH,D4			  ;OBJECT HEIGHT
	MOVE.L	#00,D6
	MOVE.L	OBJ1R1Y,D2				;DESTINATION ADDRESS
	CMP.L	#($40000000+((10)*320*16)),D2		;IS D2 > 10
	BHI	RL1SKP					;YES, ITS OK
;-----------
; CLIPPING - TOP

	SUB.L	#($40000000+((10)*320*16)),D2	    ;CLIP IT.  Y-10
	NEG.L	D2				    ;NEGATE IT
	MOVE.L	D2,D4				    ;SAVE FOR DESTINATION
	DIVU	#(320*16),D4			    ;DIVIDE OUT TO GET Y VALUE
	MOVE.L	D4,D6				    ;SAVE Y DIFFERENCE
	SUB.L	#OBJH,D4			    ;SUBTRACT IT FROM HEIGHT
						    ;D4 USED IN  CPY2 (HEIGHT)
	MOVE.L	#($40000000+((10)*320*16)),D2	    ;PUT IN NEW DEST. ADDR
;-----------
;;;RL1SKP
	ADD.L	#(75*16),D2	; ADD IN X VALUE FOR REEL1
	BSR	RWPNTR		; Set RWP to destination address in D2

; GET CLIPPED OBJECT ACCORDING TO Y VALUE IN D6
;-----------------------------------------------
;
	DIVU	#6,D6		;40/4 = 10 DIFFERENT SHAPES

	MULU	#4,D6		;MAKE IT 0,4,8,12,16,20,24,28,32,36
	MOVE.L	RL1OBJ1,A0	;GET OBJECT ADDRESS

	MOVE.L	#CLPOBJ,A1	;GET TABLE OFFSET TO ADD TO OBJECTS ADDRESS
	ADD.L	D6,A1		;INDEX TO THE ONE WE WANT (D6=0,4,8,12,16)
	MOVE.L	(A1),D6 	;GET THE OFFSET
	ADD.L	(A0),D6 	;ADD IT TO THE OBJECTS ADDRESS

;----TEST---


	MOVE.L	OBJ1R1Y,D2			    ;DESTINATION ADDRESS
	SUB.L	#($40000000+((10)*320*16)),D2	    ;CLIP IT.  Y-10
	NEG.L	D2				    ;NEGATE IT
	ADD.L	D2,D6

;----TEST---

	BSR	CPY2		;PUT IT ON THE SCREEN

	JMP	SKPCLP

;
;---------------------

RL1SKP
	ADD.L	#(75*16),D2	; ADD IN X VALUE FOR REEL1
	BSR	RWPNTR		; Set RWP to destination address in D2

	MOVE.L	RL1OBJ1,A0	; Point to object to put there
	ADD.L	(A0),D6 	; ADD OFFSET FOR CLIPPING
	BSR	CPY2		; Put object at RWP

;---------------------------
SKPCLP
	MOVE.L	OBJ2R1Y,D2	; WHERE TO PUT OBJECT
	ADD.L	#(75*16),D2	; ADD IN X VALUE FOR REEL1
	BSR	RWPNTR		; Set RWP to destination address in D2
	MOVE.L	RL1OBJ2,A0	; OBJECT TO SHOW
	BSR	CPY
;---------------------------

	MOVE.L	OBJ3R1Y,D2	; WHERE TO PUT OBJECT
	ADD.L	#(75*16),D2	; ADD IN X VALUE FOR REEL1
	BSR	RWPNTR		; Set RWP to destination address in D2
	MOVE.L	RL1OBJ3,A0	; OBJECT TO SHOW
	BSR	CPY

;---------------------------

	MOVE.L	#-OBJH,D4
	MOVE.L	#00,D6
	MOVE.L	OBJ4R1Y,D2	;DESTINATION ADDRESS

	CMP.L	#($40000000+((170-OBJH)*320*16)),D2    ;170-height = 132
	BLS	RL1SKP2

;-----------
; CLIPPING - BOTTOM

	SUB.L	#($40000000+((170-OBJH)*320*16)),D2	;CLIP IT.
	MOVE.L	D2,D4				;SAVE IN D4
	DIVU	#(320*16),D4			;DIVIDE OUT TO GET Y VALUE
	MOVE.L	D4,D6
	SUB.L	#OBJH,D4			  ;SUBTRACT IT FROM HEIGHT

	MOVE.L	OBJ4R1Y,D2			;DESTINATION STAYS THE SAME
;-----------

RL1SKP2
	ADD.L	#(75*16),D2	; ADD IN X VALUE FOR REEL1
	BSR	RWPNTR		; Set RWP to destination address in D2

; GET CLIPPED OBJECT ACCORDING TO Y VALUE IN D6
;-----------------------------------------------
;
	DIVU	#4,D6		;40/4 = 10 DIFFERENT SHAPES

	MULU	#4,D6		;MAKE IT 0,4,8,12,16,20,24,28,32,36
	MOVE.L	RL1OBJ4,A0

	MOVE.L	#CLPOBJ,A1	;GET TABLE ADDRESS FOR CLIPPED CHERRY
	ADD.L	D6,A1		;INDEX TO THE ONE WE WANT (D6=0,4,8,12,16)
	MOVE.L	(A1),D6 	;GET THE OFFSET
	ADD.L	(A0),D6 	;ADD IT TO THE OBJECTS ADDRESS

	BSR	CPY2

	JMP	SKPCLP2

;
;---------------------

	MOVE.L	RL1OBJ4,A0	; GET ADDRESS TABLE INTO A0
	MOVE.L	(A0),D6 	; GET ADDRESS FROM TABLE INTO D6
	BSR	CPY2		; PUT OBJECT ONTO THE SCREEN
;---------------------------
SKPCLP2


;-----------------------------------------------------------------------
;  REEL 2

	MOVE.L	#-OBJH,D4
	MOVE.L	#00,D6
	MOVE.L	OBJ1R2Y,D2
	CMP.L	#($40000000+(10*320*16)),D2
	BHI	RL2SKP
;-----------
; CLIPPING - TOP

	SUB.L	#($40000000+(10*320*16)),D2	;CLIP IT.  Y-10
	NEG.L	D2				;NEGATE IT
	MOVE.L	D2,D4				;SAVE FOR DESTINATION
	DIVU	#(320*16),D4			;DIVIDE OUT TO GET Y VALUE
	MOVE.L	D4,D6				;SAVE FOR SOURCE CLIPPING
	SUB.L	#OBJH,D4			  ;SUBTRACT IT FROM HEIGHT
						;D4 USED IN  CPY2
	MOVE.L	#($40000000+(10*320*16)),D2	;PUT IN NEW DESTINATION ADDR
;-----------
RL2SKP
	ADD.L	#(2176),D2	; ADD IN X VALUE FOR REEL2
	BSR	RWPNTR		; Set RWP to destination address in D2

; GET CLIPPED OBJECT ACCORDING TO Y VALUE IN D6
;-----------------------------------------------
;
	DIVU	#4,D6		;40/4 = 10 DIFFERENT SHAPES

	MULU	#4,D6		;MAKE IT 0,4,8,12,16,20,24,28,32,36
	MOVE.L	RL2OBJ1,A0	;GET OBJECT ADDRESS

	MOVE.L	#CLPOBJ,A1	;GET TABLE OFFSET TO ADD TO OBJECTS ADDRESS
	ADD.L	D6,A1		;INDEX TO THE ONE WE WANT (D6=0,4,8,12,16)
	MOVE.L	(A1),D6 	;GET THE OFFSET
	ADD.L	(A0),D6 	;ADD IT TO THE OBJECTS ADDRESS

	BSR	CPY2		;PUT IT ON THE SCREEN

	JMP	SKPCLP3

;
;---------------------

	MOVE.L	RL2OBJ1,A0
	ADD.L	(A0),D6 	; ADD OFFSET FOR CLIPPING
	BSR	CPY2

;---------------------------
SKPCLP3
	MOVE.L	OBJ2R2Y,D2	; WHERE TO PUT OBJECT
	ADD.L	#(2176),D2	; ADD IN X VALUE FOR REEL2
	BSR	RWPNTR		; Set RWP to destination address in D2
	MOVE.L	RL2OBJ2,A0	; OBJECT TO SHOW
	BSR	CPY
;---------------------------

	MOVE.L	OBJ3R2Y,D2	; WHERE TO PUT OBJECT
	ADD.L	#(2176),D2	; ADD IN X VALUE FOR REEL2
	BSR	RWPNTR		; Set RWP to destination address in D2
	MOVE.L	RL2OBJ3,A0	; OBJECT TO SHOW
	BSR	CPY
;---------------------------

	MOVE.L	#-OBJH,D4
	MOVE.L	#00,D6
	MOVE.L	OBJ4R2Y,D2			   ; WHERE TO PUT OBJECT

	CMP.L	#($40000000+((170-OBJH)*320*16)),D2
	BLS	RL2SKP2

;-----------
; CLIPPING - BOTTOM

	SUB.L	#($40000000+((170-OBJH)*320*16)),D2	;CLIP IT.
	MOVE.L	D2,D4				;SAVE IN D4
	DIVU	#(320*16),D4			;DIVIDE OUT TO GET Y VALUE
	MOVE.L	D4,D6
	SUB.L	#OBJH,D4			  ;SUBTRACT IT FROM HEIGHT

	MOVE.L	OBJ4R2Y,D2			;DESTINATION STAYS THE SAME
;-----------

RL2SKP2
	ADD.L	#(2176),D2	; ADD IN X VALUE FOR REEL2
	BSR	RWPNTR		; Set RWP to destination address in D2

; GET CLIPPED OBJECT ACCORDING TO Y VALUE IN D6
;-----------------------------------------------
;
	DIVU	#4,D6		;40/4 = 10 DIFFERENT SHAPES

	MULU	#4,D6		;MAKE IT 0,4,8,12,16,20,24,28,32,36
	MOVE.L	RL2OBJ4,A0

	MOVE.L	#CLPOBJ,A1	;GET TABLE ADDRESS FOR CLIPPED CHERRY
	ADD.L	D6,A1		;INDEX TO THE ONE WE WANT (D6=0,4,8,12,16)
	MOVE.L	(A1),D6 	;GET THE OFFSET
	ADD.L	(A0),D6 	;ADD IT TO THE OBJECTS ADDRESS

	BSR	CPY2

	JMP	SKPCLP4

;
;---------------------

	MOVE.L	RL2OBJ4,A0	; GET ADDRESS TABLE INTO A0
	MOVE.L	(A0),D6 	; GET ADDRESS FROM TABLE INTO D6
	BSR	CPY2		; PUT OBJECT ONTO THE SCREEN
;---------------------------
SKPCLP4


;-----------------------------------------------------------------------
; REEL 3

	MOVE.L	#-OBJH,D4
	MOVE.L	#00,D6
	MOVE.L	OBJ1R3Y,D2
	CMP.L	#($40000000+(10*320*16)),D2
	BHI	RL3SKP
;-----------
; CLIPPING - TOP

	SUB.L	#($40000000+(10*320*16)),D2	;CLIP IT.  Y-10
	NEG.L	D2				;NEGATE IT
	MOVE.L	D2,D4				;SAVE FOR DESTINATION
	MOVE.L	D4,D6				;SAVE FOR SOURCE CLIPPING
	DIVU	#(320*16),D4			;DIVIDE OUT TO GET Y VALUE
	SUB.L	#OBJH,D4			  ;SUBTRACT IT FROM HEIGHT
						;D4 USED IN  CPY2
	MOVE.L	#($40000000+(10*320*16)),D2	;PUT IN NEW DESTINATION ADDR
;-----------
RL3SKP
	ADD.L	#(3152),D2	; ADD IN X VALUE FOR REEL3

	BSR	RWPNTR		; Set RWP to destination address in D2
	MOVE.L	RL3OBJ1,A0
	ADD.L	(A0),D6
	BSR	CPY2
;---------------------------

	MOVE.L	OBJ2R3Y,D2	; WHERE TO PUT OBJECT
	ADD.L	#(3152),D2	; ADD IN X VALUE FOR REEL3
	BSR	RWPNTR		; Set RWP to destination address in D2
	MOVE.L	RL3OBJ2,A0	; OBJECT TO SHOW
	BSR	CPY
;---------------------------

	MOVE.L	OBJ3R3Y,D2	; WHERE TO PUT OBJECT
	ADD.L	#(3152),D2	; ADD IN X VALUE FOR REEL3
	BSR	RWPNTR		; Set RWP to destination address in D2
	MOVE.L	RL3OBJ3,A0	; OBJECT TO SHOW
	BSR	CPY
;---------------------------

	MOVE.L	#-OBJH,D4
	MOVE.L	#00,D6
	MOVE.L	OBJ4R3Y,D2			   ; WHERE TO PUT OBJECT

	CMP.L	#($40000000+((170-OBJH)*320*16)),D2
	BLS	RL3SKP2

;-----------
; CLIPPING - BOTTOM

	SUB.L	#($40000000+((170-OBJH)*320*16)),D2	;CLIP IT.
	MOVE.L	D2,D4				;SAVE IN D4
	MOVE.L	D4,D6
	DIVU	#(320*16),D4			;DIVIDE OUT TO GET Y VALUE
	SUB.L	#OBJH,D4			  ;SUBTRACT IT FROM HEIGHT

	MOVE.L	OBJ4R3Y,D2			;DESTINATION STAYS THE SAME
;-----------

RL3SKP2
	ADD.L	#(3152),D2	; ADD IN X VALUE FOR REEL3
	BSR	RWPNTR		; Set RWP to destination address in D2
	MOVE.L	RL3OBJ4,A0	; GET ADDRESS TABLE INTO A0
	MOVE.L	(A0),D6 	; GET ADDRESS FROM TABLE INTO D6
	BSR	CPY2		; PUT OBJECT ONTO THE SCREEN


;-----------------------------------------------------------------------
;    Increment object destination addresses to next position

	MOVE.L	RL1SKIP,D0	    ; NUMBER OF SCAN LINES TO SKIP, REEL 1
	BEQ	NOINC1		    ; IF ZERO THEN STOP INCREMENTING IT
	ADD.L	D0,RL1SCNL	    ; ADD TO SCAN LINE COUNTER
	MULU	#(320*16),D0
	ADD.L	D0,OBJ1R1Y
	ADD.L	D0,OBJ2R1Y
	ADD.L	D0,OBJ3R1Y
	ADD.L	D0,OBJ4R1Y
NOINC1
	MOVE.L	RL2SKIP,D0	    ; NUMBER OF SCAN LINES TO SKIP, REEL 2
	ADD.L	D0,RL2SCNL	    ; ADD TO SCAN LINE COUNTER
	MULU	#(320*16),D0
	ADD.L	D0,OBJ1R2Y
	ADD.L	D0,OBJ2R2Y
	ADD.L	D0,OBJ3R2Y
	ADD.L	D0,OBJ4R2Y

	MOVE.L	RL3SKIP,D0	    ; NUMBER OF SCAN LINES TO SKIP, REEL 3
	ADD.L	D0,RL3SCNL	    ; ADD TO SCAN LINE COUNTER
	MULU	#(320*16),D0
	ADD.L	D0,OBJ1R3Y
	ADD.L	D0,OBJ2R3Y
	ADD.L	D0,OBJ3R3Y
	ADD.L	D0,OBJ4R3Y

	BSR	CHKRL1
	BSR	CHKRL2
	BSR	CHKRL3

;-----------------------------------------------------------------------

	DBRA	D5,CHRLP

;-----------------------------------------------------------------------

	RTS


;
;  Subroutines for the SUPERSTAR slot machine
;
;
;-----------------------------------------------------------
; INCREMENT TO NEXT OBJECT IN TABLE AND RESET IF NECESSARY
; USES - A0, D3
;-----------------------------------------------------------

CHKRL1
	CMP.L	#(OBJH+OBJSP-1),RL1SCNL 	;CHECK FOR OBJECT HEIGHT
	BLS	RL1OK			;NOT YET DONE WITH OBJECT
	MOVE.L	#$00,RL1SCNL

; Initialize destination addresses of objects
;				Y	   X
	MOVE.L	#($40000000+(-29*16*320)),OBJ1R1Y	:Reel 1
	MOVE.L	#($40000000+((10+(1*OBJSP))*16*320)),OBJ2R1Y
	MOVE.L	#($40000000+((49+(2*OBJSP))*16*320)),OBJ3R1Y
	MOVE.L	#($40000000+((88+(3*OBJSP))*16*320)),OBJ4R1Y


	MOVE.L	RL1OBJ3,RL1OBJ4
	MOVE.L	RL1OBJ2,RL1OBJ3 	; TRICKLE DOWN THE OBJECT POINTERS
	MOVE.L	RL1OBJ1,RL1OBJ2

	ADD.L	#4,RL1OBJS
	MOVE.L	RL1OBJS,A0	   ;GET ADDRESS OF TABLE IN A0
	MOVE.L	A0,RL1OBJ1

	MOVE.B	RL1CNT,D3	; 23 OBJECTS ON THIS REEL
	SUBQ	#1,D3
	MOVE.B	D3,RL1CNT
	BNE.S	R1SKIP

	BSR	TOPRL1		; SHOWED ALL THE OBJECTS, WRAP AROUND

R1SKIP

RL1OK
	RTS


;-----------------------------------------------------------
; INCREMENT TO NEXT OBJECT IN TABLE AND RESET IF NECESSARY
; USES - A0, D3
;-----------------------------------------------------------

CHKRL2
	CMP.L	#(OBJH+OBJSP-1),RL2SCNL 	    ;CHECK FOR OBJECT HEIGHT
	BLS	RL2OK			;NOT YET DONE WITH OBJECT
	MOVE.L	#$00,RL2SCNL

; Initialize destination addresses of objects
;				Y	   X
	MOVE.L	#($40000000+(-29*16*320)),OBJ1R2Y
	MOVE.L	#($40000000+((10+(1*OBJSP))*16*320)),OBJ2R2Y
	MOVE.L	#($40000000+((49+(2*OBJSP))*16*320)),OBJ3R2Y
	MOVE.L	#($40000000+((88+(3*OBJSP))*16*320)),OBJ4R2Y


	MOVE.L	RL2OBJ3,RL2OBJ4
	MOVE.L	RL2OBJ2,RL2OBJ3 	; TRICKLE DOWN THE OBJECT POINTERS
	MOVE.L	RL2OBJ1,RL2OBJ2

	ADD.L	#4,RL2OBJS	   ; GET NEXT OBJECT FROM TABLE
	MOVE.L	RL2OBJS,A0	   ; GET ADDRESS OF TABLE IN A0
	MOVE.L	A0,RL2OBJ1

	MOVE.B	RL2CNT,D3	; GO THROUGH ALL NUMOBJ's OBJECTS
	SUBQ	#1,D3
	MOVE.B	D3,RL2CNT
	BNE.S	R2SKIP		; IF ZERO, THEN DISPLAYED ALL NUMOBJ's OBJECTS

	BSR	TOPRL2		; WRAP AROUND THE REEL

R2SKIP

RL2OK
	RTS

;-----------------------------------------------------------
; INCREMENT TO NEXT OBJECT IN TABLE AND RESET IF NECESSARY
; USES - A0, D3
;-----------------------------------------------------------

CHKRL3
	CMP.L	#(OBJH+OBJSP-1),RL3SCNL 	    ;CHECK FOR OBJECT HEIGHT
	BLS	RL2OK			;NOT YET DONE WITH OBJECT
	MOVE.L	#$00,RL3SCNL

; Initialize destination addresses of objects
;				Y	   X
	MOVE.L	#($40000000+(-29*16*320)),OBJ1R3Y
	MOVE.L	#($40000000+((10+(1*OBJSP))*16*320)),OBJ2R3Y
	MOVE.L	#($40000000+((49+(2*OBJSP))*16*320)),OBJ3R3Y
	MOVE.L	#($40000000+((88+(3*OBJSP))*16*320)),OBJ4R3Y


	MOVE.L	RL3OBJ3,RL3OBJ4
	MOVE.L	RL3OBJ2,RL3OBJ3 ; TRICKLE DOWN THE OBJECT POINTERS
	MOVE.L	RL3OBJ1,RL3OBJ2

	ADD.L	#4,RL3OBJS
	MOVE.L	RL3OBJS,A0	;GET ADDRESS OF TABLE IN A0
	MOVE.L	A0,RL3OBJ1

	MOVE.B	RL3CNT,D3
	SUBQ	#1,D3
	MOVE.B	D3,RL3CNT
	BNE.S	R3SKIP

	BSR	TOPRL3		; WRAP AROUND THE REEL

R3SKIP

	RTS


;----------------------------------------------
;   reset reel1 to top of reel object
;----------------------------------------------

TOPRL1
	MOVE.B	#NUMOBJ,RL1CNT	   ;RESET OBJECT COUNTER

	MOVE.L	#REEL1,RL1OBJS

	MOVE.L	RL1OBJS,A0	   ;GET ADDRESS OF TABLE IN A0
	MOVE.L	A0,RL1OBJ1

	ADD.L	#4,A0
	MOVE.L	A0,RL1OBJ2

	ADD.L	#4,A0
	MOVE.L	A0,RL1OBJ3

	ADD	#4,A0
	MOVE.L	A0,RL1OBJ4

;;;;	MOVE.L	#$00,RL1SCNL

;------------------------------------

	MOVE.L	RL1SKIP,D3	 ; SLOW DOWN UNTIL WE STOP THE REEL
	BEQ.S	TOP1RTS
	SUB.L	#1,D3
	MOVE.L	D3,RL1SKIP
	BNE.S	TOP1RTS

	MOVE.L	#0,RL1SKIP
;------------------------------------

TOP1RTS
	RTS


;----------------------------------------------
;   reset reel2 to top of reel object
;----------------------------------------------

TOPRL2
	MOVE.B	#NUMOBJ,RL2CNT	   ;RESET OBJECT COUNTER

	MOVE.L	#REEL2,RL2OBJS

	MOVE.L	RL2OBJS,A0	   ;GET ADDRESS OF TABLE IN A0
	MOVE.L	A0,RL2OBJ1

	ADD.L	#4,A0
	MOVE.L	A0,RL2OBJ2

	ADD.L	#4,A0
	MOVE.L	A0,RL2OBJ3

	ADD	#4,A0
	MOVE.L	A0,RL2OBJ4

	MOVE.L	#$00,RL2SCNL


;------------------------------------
	MOVE.L	RL1SKIP,D3
	BNE.S	TOP2RTS 	 ; REEL 1 NOT STOPPED YET

	MOVE.L	RL2SKIP,D3	 ; SLOW DOWN UNTIL WE STOP THE REEL
	BEQ.S	TOP2RTS
	SUB.L	#1,D3
	MOVE.L	D3,RL2SKIP
	BNE.S	TOP2RTS

	MOVE.L	#0,RL2SKIP
;------------------------------------

TOP2RTS
	RTS



;----------------------------------------------
;   reset reel3 to top of reel object
;----------------------------------------------

TOPRL3
	MOVE.B	#NUMOBJ,RL3CNT	       ;RESET OBJECT COUNTER

	MOVE.L	#REEL3,RL3OBJS

	MOVE.L	RL3OBJS,A0	   ;GET ADDRESS OF TABLE IN A0
	MOVE.L	A0,RL3OBJ1

	ADD.L	#4,A0
	MOVE.L	A0,RL3OBJ2

	ADD.L	#4,A0
	MOVE.L	A0,RL3OBJ3

	ADD	#4,A0
	MOVE.L	A0,RL3OBJ4

;;;;	MOVE.L	#$00,RL3SCNL


;------------------------------------
	MOVE.L	RL2SKIP,D3
	BNE.S	TOP3RTS 	 ; REEL 2 NOT STOPPED YET

	MOVE.L	RL3SKIP,D3	 ; SLOW DOWN UNTIL WE STOP THE REEL
	BEQ.S	TOP3RTS
	SUB.L	#1,D3
	MOVE.L	D3,RL3SKIP
	BNE.S	TOP3RTS

	MOVE.L	#0,RL3SKIP
;------------------------------------

TOP3RTS
	RTS

;---------------------------------------
;  DRAW REELS
;---------------------------------------

DRWREEL
	WPR 0,#$FFFF
	WPR 1,#$FFFF

	AMOVE #140,#-10
	AFRCT 0,#(140+RWIDTH),#(-RLNGTH-10)

	AMOVE #(140+RSPACE+RWIDTH),#-10
	AFRCT 0,#(140+RWIDTH+RWIDTH+RSPACE),#(-RLNGTH-10)

	AMOVE #(140+RWIDTH+RWIDTH+RSPACE+RSPACE),#-10
	AFRCT 0,#(140+RWIDTH+RWIDTH+RSPACE+RSPACE+RWIDTH),#(-RLNGTH-10)


	RTS

;-------------------------------------------------------
;	FILL IN AROUND REELS USING PATTERN MEMORY
;-------------------------------------------------------

FACEPLT
	WPR	0,#87		;COLOR 1
	WPR	1,#75		;COLOR 2

	WPR	8,#140
	WPR	9,#-170
	WPR	10,#484
	WPR	11,#-10 	; SETUP AREA TO DRAW IN


	MOVE	#1,ADDREG
	MOVE	#$1800,DATREG
	MOVE	#16,DATREG

	MOVE	#3,D1		; SETUP PATTERN RAM
FACLUP	MOVE	#$5555,DATREG
	MOVE	#$5555,DATREG
	MOVE	#$5555,DATREG
	MOVE	#$5555,DATREG

	DBRA	D1,FACLUP

	AMOVE	0,0
	AFRCT	$C0,#640,#-199	; FILL USING PATTERN RAM

	RTS

;------------------------------------
;  SETUP PALETTE
;------------------------------------

SETCLRS

	MOVE.L	#PALETTE,A0
	MOVE	#31,D0		; 16 COLORS TO SETUP

SLUP	MOVE.B	(A0)+,DAC	;DAC ADDRESS
	MOVE.B	(A0)+,DAC+2	;R
	MOVE.B	(A0)+,DAC+2	;G
	MOVE.B	(A0)+,DAC+2	;B

	DBRA	D0,SLUP
	RTS

;-----------------------------------------
; SEND DATA TO GRAPHIC CHIPS FIFO BUFFER
;-----------------------------------------

SENDIT
	MOVE	ADDREG,D3
	BTST	#1,D3
	BEQ	SENDIT

	MOVE	#0,ADDREG
	MOVE	D0,ADDREG+2
	RTS

;----------------------------------
;  HORIZONTAL SYNC ROUTINE
;----------------------------------

HSYNC
	MOVEM.L D7/A6,-(SP)	; SAVE REGISTERS

	MOVE.L	CLRLOC,A6	; THESE VARIABLES ARE SET IN VBLNK

	MOVE.B	(A6)+,D7	; GET COLOR
	MOVE.B	#$FF,DAC	;DAC ADDRESS
	MOVE.B	D7,DAC+2	;R
	MOVE.B	D7,DAC+2	;G
	MOVE.B	D7,DAC+2	;B

	MOVE.L	A6,CLRLOC	; SAVE NEW COLOR LOCATION

EXIT
	MOVEM.L (SP)+,D7/A6	; SAVE ALL REGISTERS
	RTE


;***********************************
;  VERTICAL BLANK ROUTINE
;***********************************

VBLNK
	MOVE.L	#REELCLR,CLRLOC 	; RESET ADDRESS OF COLOR TABLE
					; FOR REELS
	RTE


;-----------------------------------------------------
;  RAM STORAGE DEFENITIONS
;-----------------------------------------------------
;------------------------------------------------------
;  VARIABLE TABLE
;------------------------------------------------------


;------------------------------------------------------

OBJ1R1Y   BLKL	  1		  ; Address of object 1, reel1
OBJ2R1Y   BLKL	  1		  ; Address of object 2, reel1
OBJ3R1Y   BLKL	  1		  ; Address of object 3, reel1
OBJ4R1Y   BLKL	  1		  ; Address of object 4, reel1

OBJ1R2Y   BLKL	  1		  ; Address of object 1, reel2
OBJ2R2Y   BLKL	  1		  ; Address of object 2, reel2
OBJ3R2Y   BLKL	  1		  ; Address of object 3, reel2
OBJ4R2Y   BLKL	  1		  ; Address of object 4, reel2

OBJ1R3Y   BLKL	  1		  ; Address of object 1, reel3
OBJ2R3Y   BLKL	  1		  ; Address of object 2, reel3
OBJ3R3Y   BLKL	  1		  ; Address of object 3, reel3
OBJ4R3Y   BLKL	  1		  ; Address of object 4, reel3

;------------------------------------------------------

RL1OBJ1 BLKL	1
RL1OBJ2 BLKL	1
RL1OBJ3 BLKL	1
RL1OBJ4 BLKL	1

RL2OBJ1 BLKL	1
RL2OBJ2 BLKL	1
RL2OBJ3 BLKL	1
RL2OBJ4 BLKL	1

RL3OBJ1 BLKL	1
RL3OBJ2 BLKL	1
RL3OBJ3 BLKL	1
RL3OBJ4 BLKL	1

;------------------------------------------------------

RL1OBJS BLKL	1	; Address of table of objects for reel 1
RL2OBJS BLKL	1	; Address of table of objects for reel 2
RL3OBJS BLKL	1	; Address of table of objects for reel 3

;------------------------------------------------------

CLRLOC	LONG	0

RL1SKIP LONG	0	; Number of scan lines to increment objects
RL2SKIP LONG	0	; 1 2 OR 4
RL3SKIP LONG	0


RL1CNT	DEFB	0	; KEEPS TRACK OF THE # OF OBJECTS SHOWN
RL2CNT	DEFB	0	; 23 FOR SUPER STAR
RL3CNT	DEFB	0

RL1SCNL LONG	0	; NUMBER OF SCAN LINES TO SCROLL THROUGH
RL2SCNL LONG	0	; 39 FOR 1 INCREMENT
RL3SCNL LONG	0	; 19 FOR 2 INCREMENT
			;  9 FOR 4 INCREMENT

;----------------------------------------
;  Static variables
;
;-----------------------------------------
;  PALETTE FOR PAYOUT TABLE
;-----------------------------------------

PALETTE
	DEFB	255,63,63,63
	DEFB	254,63,63,21
	DEFB	253,63,21,63
	DEFB	252,63,21,21
	DEFB	251,63,0,0
	DEFB	250,21,63,21

	DEFB	249,63,40,0
	DEFB	248,55,35,0
	DEFB	247,44,12,16
	DEFB	246,42,0,42
	DEFB	245,53,53,0

	DEFB	243,0,0,63
	DEFB	242,0,40,0
	DEFB	241,45,45,45
	DEFB	240,0,0,50
	DEFB	239,0,0,55

	DEFB	238,32,0,32	; PURPLES
	DEFB	237,40,0,40
	DEFB	236,47,0,47
	DEFB	235,55,0,55
	DEFB	234,63,0,63

	DEFB	233,49,22,0	; ORANGES
	DEFB	232,55,22,0
	DEFB	231,56,23,0
	DEFB	230,59,23,0
	DEFB	229,63,24,0

	DEFB	228,40,40,0	; YELLOWS
	DEFB	227,46,46,0
	DEFB	226,51,51,0
	DEFB	225,57,57,0
	DEFB	224,63,63,0

	DEFB	223,0,0,0
	DEFB	222,0,0,0


;------------------------------------------
;  TABLE OF OBJECTS FOR REEL
;------------------------------------------

;  ADD IN 320*16 TO GET RID OF BLACK LINE OF SHAPES

CHERRY	EQU	$000FA000+(320*16)	 ;ACTUAL ADDRESS *16
PLUMB	EQU	$000FA280+(320*16)
LEMON	EQU	$000FA500+(320*16)
ORANGE	EQU	$000FA780+(320*16)
BELL	EQU	$000FAA00+(320*16)
BAR	EQU	$000FAC80+(320*16)


;----------------------------------------------------------
;   TABLE OF CLIPPED OBJECTS OFFSETS FROM UNCLIPPED OBJECT
;----------------------------------------------------------


CLPOBJ

	LONG	0
	LONG	(320*16*40)
	LONG	(320*16*80)
	LONG	(320*16*120)
	LONG	(320*16*160)
	LONG	(320*16*200)
	LONG	(320*16*240)
	LONG	(320*16*280)
	LONG	(320*16*320)
	LONG	(320*16*360)
	LONG	(320*16*400)


;-------------------------------------------
;

REEL1
;	 LONG	 CHERRY
;	 LONG	 LEMON
;	 LONG	 ORANGE
;	 LONG	 PLUMB
;
;	 LONG	 CHERRY
;	 LONG	 BELL
;	 LONG	 LEMON
;	 LONG	 ORANGE
;	 LONG	 PLUMB
;	 LONG	 CHERRY
;	 LONG	 LEMON
;	 LONG	 ORANGE
;	 LONG	 BAR
;	 LONG	 LEMON
;	 LONG	 CHERRY
;	 LONG	 BELL
;	 LONG	 ORANGE
;	 LONG	 PLUMB
;	 LONG	 CHERRY
;	 LONG	 LEMON
;
;	 LONG	 PLUMB	 ;REDO 1ST FOUR OBJECTS IN REVERSE ORDER
;	 LONG	 ORANGE
;	 LONG	 LEMON
;	 LONG	 CHERRY

;----------------------------

	LONG	LEMON
	LONG	LEMON
	LONG	LEMON
	LONG	LEMON

	LONG	ORANGE
	LONG	LEMON
	LONG	LEMON
	LONG	ORANGE
	LONG	LEMON
	LONG	LEMON
	LONG	ORANGE
	LONG	LEMON
	LONG	LEMON
	LONG	ORANGE
	LONG	LEMON
	LONG	LEMON
	LONG	ORANGE
	LONG	LEMON
	LONG	LEMON
	LONG	ORANGE

	LONG	LEMON	;REDO 1ST FOUR OBJECTS IN REVERSE ORDER
	LONG	LEMON
	LONG	LEMON
	LONG	LEMON

;
;-------------------------------------------------------------------


REEL2

;	LONG	LEMON
;	LONG	CHERRY
;	LONG	BELL
;	LONG	PLUMB
;
;	LONG	LEMON
;	LONG	BAR
;	LONG	CHERRY
;	LONG	BELL
;	LONG	ORANGE
;	LONG	LEMON
;	LONG	CHERRY
;	LONG	PLUMB
;	LONG	BAR
;	LONG	ORANGE
;	LONG	BELL
;	LONG	PLUMB
;	LONG	CHERRY
;	LONG	ORANGE
;	LONG	LEMON
;	LONG	CHERRY

;      LONG    PLUMB		  ; REDO 1ST FOUR OBJECTS IN REVERSE
;      LONG    BELL
;      LONG    CHERRY
;      LONG    LEMON

;TEST REEL 2

	LONG	LEMON
	LONG	CHERRY
	LONG	ORANGE
	LONG	LEMON

	LONG	LEMON
	LONG	LEMON
	LONG	CHERRY
	LONG	CHERRY
	LONG	ORANGE
	LONG	LEMON
	LONG	CHERRY
	LONG	ORANGE
	LONG	ORANGE
	LONG	ORANGE
	LONG	LEMON
	LONG	LEMON
	LONG	CHERRY
	LONG	ORANGE
	LONG	LEMON
	LONG	CHERRY

       LONG    LEMON		  ; REDO 1ST FOUR OBJECTS IN REVERSE
       LONG    ORANGE
       LONG    CHERRY
       LONG    LEMON

;
;-------------------------------------------------------------------

REEL3
       LONG    CHERRY
       LONG    BAR
       LONG    ORANGE
       LONG    CHERRY

       LONG    PLUMB
       LONG    ORANGE
       LONG    LEMON
       LONG    BELL
       LONG    PLUMB
       LONG    CHERRY
       LONG    LEMON
       LONG    ORANGE
       LONG    BAR
       LONG    PLUMB
       LONG    LEMON
       LONG    ORANGE
       LONG    BELL
       LONG    BAR
       LONG    CHERRY
       LONG    PLUMB

       LONG    CHERRY		 ; REDO 1ST FOUR OBJECTS IN REVERSE ORDER
       LONG    ORANGE
       LONG    BAR
       LONG    CHERRY


;-----------------------------------
;  COLOR TABLE FOR REELS
;-----------------------------------

;REELCLR
;	 DEFB 16,19,22,25,27
;	 DEFB 29,31,33,34,36
;	 DEFB 37,39,39,41,42
;	 DEFB 43,44,44,45,46
;	 DEFB 47,47,48,48,49
;	 DEFB 50,50,50,51,51
;	 DEFB 51,52,52,52,52
;	 DEFB 52,52,52,52,52
;	 DEFB 52,52,52,52,52
;	 DEFB 52,51,51,51,51
;	 DEFB 50,50,49


GETADR				;D0=Y D1=X
	MULU	#(16*320),D0	;MULTIPLY Y BY ADDRESS OFFSET
	MOVE.L	#$40000000,D2
	ADD.L	D0,D2		;D2 HAS SCREEN ADDRESS AT X=0 AND Y
	MULU	#16,D1
	ADD.L	D1,D2		; RETURN SCREEN ADDRESS AT X,Y IN D2
	RTS

;----------------------------------------------------------------------
;  COPY OBJECT TO ADDRESS IN READ/WRITE POINTER

CPY
	MOVE	#(CCPY+$100),D0
	BSR	SENDIT
	MOVE.W	(A0)+,D0	;GET DATA FROM TABLE
	BSR	SENDIT
	MOVE.W	(A0),D0 	;GET DATA FROM TABLE
	BSR	SENDIT

	MOVE	#37,D0		; OBJW / 2
	BSR	SENDIT
	MOVE	#-OBJH,D0	  ; - OBJH
	BSR	SENDIT
	RTS

;----------------------------------------------------------------------
;  COPY OBJECT TO ADDRESS IN READ/WRITE POINTER
;  SPECIAL VERSION FOR CLIPPING

CPY2
	MOVE	#(CCPY+$100),D0
	BSR	SENDIT
;-----------------
	MOVE.W	D6,D1		; PUT LOW INTO D1
	SWAP	D6
	AND.L	#$FFFF,D3	; PUT HIGH INTO D3

	MOVE.W	D6,D0		; OBJECT ADDRESS HIGH
	BSR	SENDIT

	MOVE.W	D1,D0		; OBJECT ADDRESS LO
	BSR	SENDIT
;----------------------------

	MOVE	#37,D0		; OBJW / 2
	BSR	SENDIT
	MOVE.W	D4,D0		; - OBJH
	BSR	SENDIT
	RTS


;----------------------------------------------------------------------
; SETUP THE READ/WRITE POINTER

RWPNTR				; SET UP READ WRITE POINTER ADDRESS
				; WHERE TO PUT OBJECT
	MOVE.W	D2,D1		; PUT LOW INTO D1
	SWAP	D2
	AND.L	#$FFFF,D2	; PUT HIGH INTO D2

	WPR	$0C,D2		; (WHERE TO PUT THE OBJECT USING CPY)
	WPR	$0D,D1

	RTS

	END

