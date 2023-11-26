;
;
; THIS PROGRAM ALLOWS THE 8751 TO COMMUNICATE WITH BOTH THE 68000
; CPU AND INTERNAL UART OF THE 8751 ACTING AS AN INTELLIGENT UART
; SO THAT THE 68000 CPU MAY USE THE 8751 SERIAL PORT AS TERMINAL
; I/O
;
;
; PROGRAM EQUATES
;
B1200   .EQU    0E8H            ;VALUE FOR TIMER1 FOR 1200 BAUD
B2400   .EQU    0F4H            ;VALUE FOR TIMER1 FOR 2400 BAUD
B4800   .EQU    0FAH            ;VALUE FOR TIMER1 FOR 2400 BAUD
B9600   .EQU    0FDH            ;VALUE FOR TIMER1 FOR 2400 BAUD
;
DUBLB   .EQU    80H             ;ZERO FOR 1/2 BAUD RATE ELSE 80H
SMODE   .EQU    50H             ;SERIAL MODE SETUP PARAMETER

DIP0    .EQU    30H             ;RAM STORAGE FOR DIP SWITCHES
DIP1    .EQU    31H
DIP2    .EQU    32H
DIP3    .EQU    33H
NXTPNT  .EQU    34H             ;POINTER INTO BUFFER FOR NEXT CHAR
BUFPNT  .EQU    35H             ;POINTER INTO BUFFER FOR NEXT REC CHAR
BUFFER  .EQU    36H             ;RECV BUFFER 64 BYTES
PSAVE   .EQU    76H             ;SAVE BYTE FOR PSW
;
; RESET COMES HERE
;
        .ORG    0000H
;
BOOTUP  CLR     P0.6            ;TOGGLE PORT 0 BIT 6 TO
        SETB    P0.6            ;CLEAR DATA INPUT LATCH
        MOV     TMOD,#20H       ;SETUP TIMER1 FOR 8BIT AUTO-RELOAD TIMER
        MOV     TH1,#B9600      ;SETUP TIMER1H WITH 9600 BAUD VALUE
        SETB    TR1             ;START TIMER 1 RUNNING
        MOV     SCON,#SMODE     ;SETUP SERIAL PORT MODE
        SETB    0               ;SET TX OK BIT
        MOV     BUFPNT,#0       ;RESET REC BUFFER PNTR = 0
        MOV     NXTPNT,#0       ;RESET REC COUNT = 0
        SJMP    START

;
; IRQ ROUTINE HANDLES SERIAL PORT I/O
; DESTROYS R5!
;
        .ORG    0023H
;
SIRQ    MOV     B,A             ;SAVE A
        MOV     A,PSW           ;GET PSW
        MOV     PSAVE,A         ;SAVE PSW
        MOV     R5,R0           ;SAVE R0 IN R5
        JNB     TI,NOTI         ;IF NO TI IRQ THEN BRANCH
        CLR     TI              ;ELSE CLEAR IT
        SETB    0               ;SET TX OK BIT
NOTI    JNB     RI,ENDIRQ       ;IF NO RI IRQ THEN END
        CLR     RI              ;ELSE CLEAR IT
        MOV     A,SBUF          ;GET RS-232 CHAR
        MOV     R0,A            ;SAVE IT
        MOV     A,BUFPNT        ;GET BUFFER POINTER
        INC     A               ;ADD 1
        ANL     A,#3FH          ;WRAP AT 63
        MOV     BUFPNT,A        ;SAVE BUFFER POINTER
        ADD     A,#BUFFER       ;ADD BUFFER BEGIN OFFSET
        XCH     A,R0            ;SWAP R0 AND A
        MOV     @R0,A           ;PUT CHAR IN BUFFER
ENDIRQ  MOV     R0,R5           ;RESTORE R0
        MOV     A,PSAVE         ;GET OLD PSW
        MOV     PSW,A           ;RESTORE PSW
        MOV     A,B             ;RESTORE A
        RETI                    ;RETURN FROM IRQ

;
; PROGRAM START
;
;
START   MOV     IE,#90H         ;ENABLE SERIAL PORT INTERRUPTS
        ACALL   GETC            ;GO GET AN RS-232 CHAR
        JNC     START           ;IF NO CHARACTER RECEIVED BRANCH
        MOV     R2,A            ;SAVE ACC IN R2
        ANL     A,#0F0H         ;LEAVE ONLY HI NIBBLE
        XRL     A,#0F0H         ;CHECK IF HI NIBBLE IS F
        JZ      HIBAUD          ;IF SO MUST BE 19.2K BAUD
        MOV     A,R2            ;ELSE RESTORE A
        ANL     A,#7FH          ;STRIP OUT BIT 7
        MOV     R2,A            ;SAVE ACC IN R2
ST0     MOV     R4,#0           ;R4 = 0
        MOV     R1,#4           ;4 BAUD RATES TO CHECK
ST1     MOV     DPTR,#BAUDCR    ;POINT TO BAUD CHECK TABLE
        MOV     A,R4            ;GET OFFSET INTO TABLE
        MOVC    A,@A+DPTR       ;GET TABLE BYTE
        MOV     DPTR,#BAUDTBL   ;POINT TO BAUD RATE TABLE
        XRL     A,R2            ;SEE IF A = R2
        JZ      BAUDOK          ;ELSE BAUD IS OK
        INC     R4              ;POINT TO NEXT OFFSET
        DJNZ    R1,ST1          ;LOOP FOR 4 CHECKS
        AJMP    START           ;AND TRY AGAIN!
;
HIBAUD  MOV     A,#DUBLB        ;SET SMOD BIT IN
        MOV     PCON,A          ;IN PCON REGISTER
        AJMP    NXTBD           ;GO CHECK BAUD RATES
;
BAUDOK  MOV     A,R4            ;GET OFFSET INTO BAUD RATE TABLE
        MOVC    A,@A+DPTR       ;GET BAUD RATE TIME CONSTANT
        MOV     TH1,A           ;SET UP TIMER FOR PROPER BAUD RATE
NXTBD   MOV     DPTR,#OKMESS    ;PRINT OK MESSAGE
        ACALL   PRINTLN         ;GO PRINT MESSAGE
        ACALL   DIPSW           ;GO DISPLAY DIP SWITCH SETTINGS TO USER

;
; HANSHAKE WITH 68000 TO SEE IF IT IS WORKING
;
        MOV     R4,#0           ;ZERO R4
        MOV     R1,#0           ;AND R1 FOR TIMEOUT COUNTERS
HSHAKE  JB      P0.5,HSH1       ;IF XMIT REG FULL THEN BRANCH
        JB      P0.4,HSH2       ;IF 68000 CHAR REC THEN BRANCH
HSH1    DJNZ    R4,HSHAKE       ;ELSE LOOP R4 TIMES
        DJNZ    R1,HSHAKE       ;WITHIN R1 TIMES
        MOV     DPTR,#BADMES    ;GO PRINT ERROR MESSAGE
        ACALL   PRINTLN         ;GO PRINT IT
        SJMP    HSHAKE          ;KEEP TRYING FOREVER
;
HSH2    MOV     A,P0            ;READ P0 INTO A
        CLR     P0.6            ;TOGGLE PORT 0 BIT 6 TO
        SETB    P0.6            ;CLEAR DATA INPUT LATCH
        ORL     A,#0F0H         ;SET UPPER NIBBLE TO F
        MOV     P1,A            ;WRITE DATA IN A TO LATCH
        CLR     P0.7            ;TOGGLE PORT 0 BIT 7 TO
        SETB    P0.7            ;STROBE DATA INTO LATCH
;
HSH3    JNB     P0.5,EMSTRT     ;IF 68000 READ CHAR THEN BRANCH
        DJNZ    R4,HSH3         ;ELSE LOOP R4 TIMES
        DJNZ    R1,HSH3         ;WITHIN R1 TIMES
        MOV     DPTR,#BADMES    ;POINT TO ERROR MESSAGE
        ACALL   PRINTLN         ;GO PRINT IT
        SJMP    HSHAKE          ;KEEP TRYING FOREVER
;
; START UART EMULATION LOOP
;
EMSTRT  MOV     R1,#0           ;CLEAR RECV IN PROGRESS STATUS
EMLOOP  JNB     0,NOXMIT        ;IF XMIT REG FULL THEN BRANCH
        JNB     P0.4,NOXMIT     ;IF NO 68000 CHAR TO SEND THEN BRANCH
        MOV     A,P0            ;GET HIGH BYTE OF CHAR IN A
        CLR     P0.6            ;TOGGLE PORT 0 BIT 6 TO
        SETB    P0.6            ;CLEAR DATA INPUT LATCH
        SWAP    A               ;SWAP NIBBLES
        ORL     A,#0FH          ;MAKE LOWER NIBBLE F
        MOV     R4,A            ;SAVE IN R4
NXTS    JNB     P0.4,NXTS       ;WAIT FOR NEXT NIBBLE TO SEND
        MOV     A,P0            ;GET IT
        CLR     P0.6            ;TOGGLE PORT 0 BIT 6 TO
        SETB    P0.6            ;CLEAR DATA INPUT LATCH
        ORL     A,#0F0H         ;SET UPPER NIBBLE TO F
        ANL     A,R4            ;AND TOP NIBBLE OF R4 INTO A
        ACALL   SENDC           ;SEND BYTE THROUGH RS-232 PORT
;
NOXMIT  MOV     A,R1            ;GET RECV IN PROGRESS STATUS
        RRC     A               ;PUT BIT 0 INTO C
        JC      SNIB1           ;IF SET GO SEND NIBBLE 1
        RRC     A               ;PUT BIT 1 INTO C
        JC      SNIB2           ;IF SET GO SEND NIBBLE 2
        ACALL   GETC            ;GET A CHAR FROM RS-232
        JNC     EMLOOP          ;IF NO CHARACTERS THEN LOOP
        MOV     R2,A            ;SAVE CHAR IN R2
        MOV     R1,#1           ;SET RECV IN PROGRESS STATUS
;
SNIB1   JB      P0.5,EMLOOP     ;IF XMIT REG FULL THEN BRANCH
        MOV     A,R2            ;GET DATA TO SEND
        SWAP    A               ;PUT HIGH NIBBLE INTO LOW
        ORL     A,#0F0H         ;SET UPPER NIBLE TO F
        MOV     P1,A            ;WRITE DATA IN A TO LATCH
        CLR     P0.7            ;TOGGLE PORT 0 BIT 7 TO
        SETB    P0.7            ;STROBE DATA INTO LATCH
        INC     R1              ;UPDATE RECV PROGRESS STATUS
        SJMP    EMLOOP          ;LOOP
;
SNIB2   JB      P0.5,EMLOOP     ;IF XMIT REG FULL THEN BRANCH
        MOV     A,R2            ;GET DATA TO SEND
        ORL     A,#0F0H         ;SET UPPER NIBLE TO F
        MOV     P1,A            ;WRITE DATA IN A TO LATCH
        CLR     P0.7            ;TOGGLE PORT 0 BIT 7 TO
        SETB    P0.7            ;STROBE DATA INTO LATCH
        MOV     R1,#0           ;UPDATE RECV PROGRESS STATUS TO DONE
        SJMP    EMLOOP          ;LOOP

;
; SUBROUTINE PRINLN PRINTS DATA POINTED TO BY DPTR UNTIL IT FINDS
; A ZERO BYTE
;
PRINTLN CLR     A               ;CLEAR ACC
        MOVC    A,@A+DPTR       ;GET BYTE FROM (DPTR)
        JZ      PRINTE          ;IF ZERO END
        ACALL   SENDC           ;GO SEND CHARACTER TO RS232
        INC     DPTR            ;POINT TO NEXT DATA BYTE
        SJMP    PRINTLN         ;LOOP FOR ALL DATA
PRINTE  RET                     ;RETURN TO CALLLER

;
; SUBROUTINE GETS AN RS-232 CHAR
; IF NO CHAR AVAILABLE RETURNS CARRY CLEAR
;
GETC    CLR     C               ;CLEAR CARRY
        MOV     A,NXTPNT        ;GET LAST CHAR POINTER
        XRL     A,BUFPNT        ;SAME AS BUFPNT?
        JZ      GETCE           ;IF SO NO CHARS SO BRANCH
        MOV     A,NXTPNT        ;ELSE GET LAST CHAR POINTER
        INC     A               ;ADD 1
        ANL     A,#3FH          ;WRAP AT 63
        MOV     NXTPNT,A        ;SAVE POINTER
        ADD     A,#BUFFER       ;ADD BUFFER OFFSET
        MOV     R0,A            ;SAVE IN R0
        MOV     A,@R0           ;GET BYTE FROM BUFFER
        SETB    C               ;SET CARRY
GETCE   RET                     ;RETURN TO CALLER

;
; SUBROUTINE SENDS AN RS-232 CHAR
; ENTER WITH CHAR IN ACC
;
SENDC   JNB     0,SENDC         ;WAIT FOR TX OK BIT TO BE 1
        CLR     0               ;NOW CLEAR TX OK BIT
        MOV     SBUF,A          ;SEND CHARACTER OUT
        MOV     R3,A            ;SAVE A
        CLR     P3.7            ;DEACTIVATE DIFF OUTPUT
        MOV     A,DIP3          ;READ DIP 4
        ANL     A,#1            ;LEAVE BIT 0
        JZ      NOEN            ;IF BIT IS OFF DON'T ENABLE DIFF OUT
        SETB    P3.7            ;ELSE ENABLE DIFF OUT
NOEN    MOV     A,DIP3          ;READ DIP 4
        ANL     A,#2            ;LEAVE BIT 1
        JZ      NODIF           ;IF BIT IS OFF DON'T TEST DIFF LINES!
        MOV     A,R3            ;RESTORE A
        ANL     A,#1            ;TEST BIT 0
        JNZ     DIFHI           ;IF HI GO DO
        CLR     P3.4            ;CLEAR CLK
        CLR     P3.6            ;AND DATA
        JNB     P3.5,NODIF      ;BRANCH IF INPUT IS ALSO OK!
        SJMP    DIFER           ;ELSE DO ERROR!
DIFHI   SETB    P3.4            ;SET CLK
        SETB    P3.6            ;AND DATA
        JB      P3.5,NODIF      ;BRANCH IF INPUT IS ALSO OK!
DIFER   JNB     0,DIFER         ;WAIT FOR TX OK BIT TO BE 1
        CLR     0               ;NOW CLEAR TX OK BIT
        MOV     A,#21H          ;A '!'
        MOV     SBUF,A          ;SEND CHARACTER OUT
NODIF   MOV     A,R3            ;RESTORE A
        RET

;
;SUBROUTINE TO SHOW DIP SWITCH SETTINGS TO USER
;
DIPSW   ACALL   RDIPS           ;READ DIPS INTO RAM
        MOV     DPTR,#DIPMES    ;PRINT OK MESSAGE
        ACALL   PRINTLN         ;GO PRINT MESSAGE
        MOV     DPTR,#HEXTAB    ;POINT TO HEX TABLE
        MOV     A,#20H          ;SPACE CHAR
        MOV     R4,#3           ;3 TIMES
SP0     ACALL   SENDC           ;PRINT SPACE
        DJNZ    R4,SP0          ;LOOP
        MOV     A,DIP0          ;GET DIP 0
        SWAP    A               ;GET HI INTO LO
        ANL     A,#0FH          ;LEAVE ONLY LOW NIBBLE
        MOVC    A,@A+DPTR       ;GET HEX BYTE
        ACALL   SENDC           ;SEND IT
        MOV     A,DIP0          ;GET DIP 0
        ANL     A,#0FH          ;LEAVE ONLY LOW NIBBLE
        MOVC    A,@A+DPTR       ;GET HEX BYTE
        ACALL   SENDC           ;SEND IT
;
        MOV     A,#20H          ;SPACE CHAR
        MOV     R4,#6           ;6 TIMES
SP1     ACALL   SENDC           ;PRINT SPACE
        DJNZ    R4,SP1          ;LOOP
        MOV     A,DIP1          ;GET DIP 1
        SWAP    A               ;GET HI INTO LO
        ANL     A,#0FH          ;LEAVE ONLY LOW NIBBLE
        MOVC    A,@A+DPTR       ;GET HEX BYTE
        ACALL   SENDC           ;SEND IT
        MOV     A,DIP1          ;GET DIP 1
        ANL     A,#0FH          ;LEAVE ONLY LOW NIBBLE
        MOVC    A,@A+DPTR       ;GET HEX BYTE
        ACALL   SENDC           ;SEND IT
;
        MOV     A,#20H          ;SPACE CHAR
        MOV     R4,#6           ;6 TIMES
SP2     ACALL   SENDC           ;PRINT SPACE
        DJNZ    R4,SP2          ;LOOP
        MOV     A,DIP2          ;GET DIP 2
        SWAP    A               ;GET HI INTO LO
        ANL     A,#0FH          ;LEAVE ONLY LOW NIBBLE
        MOVC    A,@A+DPTR       ;GET HEX BYTE
        ACALL   SENDC           ;SEND IT
        MOV     A,DIP2          ;GET DIP 2
        ANL     A,#0FH          ;LEAVE ONLY LOW NIBBLE
        MOVC    A,@A+DPTR       ;GET HEX BYTE
        ACALL   SENDC           ;SEND IT
;
        MOV     A,#20H          ;SPACE CHAR
        MOV     R4,#6           ;6 TIMES
SP3     ACALL   SENDC           ;PRINT SPACE
        DJNZ    R4,SP3          ;LOOP
        MOV     A,DIP3          ;GET DIP 3
        SWAP    A               ;GET HI INTO LO
        ANL     A,#0FH          ;LEAVE ONLY LOW NIBBLE
        MOVC    A,@A+DPTR       ;GET HEX BYTE
        ACALL   SENDC           ;SEND IT
        MOV     A,DIP3          ;GET DIP 3
        ANL     A,#0FH          ;LEAVE ONLY LOW NIBBLE
        MOVC    A,@A+DPTR       ;GET HEX BYTE
        ACALL   SENDC           ;SEND IT
        MOV     A,#0DH          ;RETURN
        ACALL   SENDC
        MOV     A,#0AH          ;LF
        ACALL   SENDC
        RET                     ;RETURN TO CALLER

;
; READ DIP SWITCHES INTO RAM VARIABLES
;
RDIPS   MOV     R7,#8           ;READ 8 BITS
        MOV     R6,#0FEH        ;SET BIT FOR SW1 LOW
        ORL     P1,#0C0H        ;SET P1.6 & P1.7
        ORL     P3,#0CH         ;SET P3.2 & P3.3
RDL1    MOV     A,R6            ;GET BIT PATTERN
        MOV     P2,A            ;SET PORT BIT TO READ LOW
        MOV     A,DIP0          ;GET DIP 0
        MOV     C,P3.2          ;READ DIP 0 BIT
        CPL     C               ;INVERT IT
        RRC     A               ;ROTATE INTO RAM DIP
        MOV     DIP0,A          ;SAVE
;
        MOV     A,DIP1          ;GET DIP 1
        MOV     C,P3.3          ;READ DIP 1 BIT
        CPL     C               ;INVERT IT
        RRC     A               ;ROTATE INTO RAM DIP
        MOV     DIP1,A          ;SAVE
;
        MOV     A,DIP2          ;GET DIP 2
        MOV     C,P1.6          ;READ DIP 2 BIT
        CPL     C               ;INVERT IT
        RRC     A               ;ROTATE INTO RAM DIP
        MOV     DIP2,A          ;SAVE
;
        MOV     A,DIP3          ;GET DIP 3
        MOV     C,P1.7          ;READ DIP 3 BIT
        CPL     C               ;INVERT IT
        RRC     A               ;ROTATE INTO RAM DIP
        MOV     DIP3,A          ;SAVE
        MOV     A,R6            ;GET R6
        RL      A               ;MOVE BIT OVER 1
        MOV     R6,A            ;SAVE R6
        DJNZ    R7,RDL1         ;LOOP FOR ALL 8 BITS OF DIPS
        RET


HEXTAB  .DEFB   '0123456789ABCDEF'

BAUDCR  .DEFB   0DH,66H,78H,00H
BAUDTBL .DEFB   B9600,B4800,B2400,B1200
OKMESS  .DEFB   07H,0DH,0AH,'COMMUNICATIONS ESTABLISHED WITH SUPERSTAR'
        .DEFB   0DH,0AH,'ENABLING COMMUNICATIONS WITH 68000 CPU',0DH,0AH,0
BADMES  .DEFB   '68000 CPU TIMEOUT ERROR!',07,0DH,0AH,0
DIPMES  .DEFB   'SWITCH0 SWITCH1 SWITCH2 SWITCH3',0DH,0AH,0
        .END
