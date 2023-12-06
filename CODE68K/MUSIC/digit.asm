

        RELATIVE
        ORG $80600
;
;-------------------------------------
;
;
; SuperStar Slot Music routines
; Applied Computer Technology
; 1701 W. Charleston Blvd  #540
; Las Vegas, NV   89102
; 702-366-1226
;
; Programmer: Francis Styck
; December 3, 1988
;
;
; A0 -
; A1 -
; A2 -
; A3 -
; A4 -
; A5 -
; A6 -
; A7 -
;
; D0 -
; D1 -
; D2 -
; D3 -
; D4 -
; D5 -
; D6 -
; D7 -
;
;-----------------------------------------------------------

SNDDAT  EQU     $100000         ; SOUND DATA REGISTER
SNDADD  EQU     $100002         ; SOUND ADDRESS REGISTER

;-----------------------------------------------------------
; OFFSETS INTO CHIP REGISTERS
;-----------------------------------------------------------

VOL0    EQU     0       ; VOLUME REGISTERS
VOL1    EQU     1
VOL2    EQU     2
VOL3    EQU     3
VOL4    EQU     4
VOL5    EQU     5
;-----------------------------------------------------------

NOTE0   EQU     8       ; FREQUENCY REGISTERS
NOTE1   EQU     9
NOTE2   EQU     $A
NOTE3   EQU     $B
NOTE4   EQU     $C
NOTE5   EQU     $D
;-----------------------------------------------------------

OCTV0   EQU     $10     ; OCTAVE REGISTERS
OCTV1   EQU     $10
OCTV2   EQU     $11
OCTV3   EQU     $11
OCTV4   EQU     $12
OCTV5   EQU     $12
;-----------------------------------------------------------

FENABLE EQU     $14             ; FREQUENCY ENABLE
NENBLE0 EQU     $15             ; NOISE ENABLE 0
NENBLE1 EQU     $16             ; NOISE ENABLE 1

ENVLP0  EQU     $18             ; ENVELOPE GENERATOR 0
ENVLP1  EQU     $19             ; ENVELOPE GENERATOR 1

SNDENBL EQU     $1C             ; SOUND ENABLE

;-----------------------------------------------------------
; START OF MAIN CODE
;-----------------------------------------------------------

        BSR     ZEROVOL                 ; ZERO ALL VOLUMES

        MOVE.B  #SNDENBL,SNDADD         ; ENABLE SOUND
        MOVE.B  #$01,SNDDAT

        MOVE.B  #NENBLE0,SNDADD  ; DISABLE NOISE
        MOVE.B  #$00,SNDDAT
        MOVE.B  #NENBLE1,SNDADD
        MOVE.B  #$00,SNDDAT

        MOVE.B  #ENVLP1,SNDADD          ; NO ENVELOPE CONTROL
        MOVE.B  #$00,SNDDAT
        MOVE.B  #ENVLP0,SNDADD          ; $84 - SINGLE DECAY
        MOVE.B  #$00,SNDDAT             ; $86 - REPETITIVE DECAY
                                        ; $9D - SINGLE ATTACK
                                        ; $02 - CONTINUOUSE

        MOVE.B  #NOTE1,SNDADD           ; SET NOTE
        MOVE.B  #$21,SNDDAT
        MOVE.B  #NOTE2,SNDADD
        MOVE.B  #$21,SNDDAT
        MOVE.B  #NOTE3,SNDADD
        MOVE.B  #$21,SNDDAT

        MOVE.B  #OCTV0,SNDADD           ; SET OCTAVES
        MOVE.B  #$11,SNDDAT
        MOVE.B  #OCTV2,SNDADD
        MOVE.B  #$11,SNDDAT

        MOVE.B  #FENABLE,SNDADD         ; ENABLE FREQUENCY
        MOVE.B  #$07,SNDDAT

;-----------------------------------------------------------


replay
;       move.l  4(sp),sample            ; DATA
;       move.l  8(sp),length            ; LENGTH
;       move.l  12(sp),freqncy          ; FREQ


;       move.l  freqncy,d0     ;set initial frequency

        move.l  #$81000,a6     ;start
        move.l  A6,d6          ;+ length   MOVE.L A6,D6
        add.l   #$1000,d6       ;= end      ADD.L  LENGTH,D6

        lea     snd_out,a3      look up tables

        st      inuse          ;Signal replay in use

WAIT
        bsr     ireplay
        BSR     DELAY
        tst.b   inuse           sample finished ?
        bne.s   WAIT            br. if not

;-----------------------------------------------------------
; ALL DONE, DISABLE SOUND
;-----------------------------------------------------------

        MOVE.B  #SNDENBL,SNDADD ; DISABLE SOUND, WE ARE FINISHED
        MOVE.B  #$00,SNDDAT

        RTS



****************************************
*   the interrupt service routines     *
****************************************
*
*       a6 = pointer to base of replay ram
*       a5 = output routine addr
*       a4 = int. sound reg / ext. port addr
*       a3 = look up table address
*       a2 = variable offset reg (Nil)
*       a1 = unused
*       a0 = unused
*       d7 = byte from port /  out to port
*       d6 = pointer to end of replay ram
*       d5 = sound chip data
*       d4 = sound chip data
*       d3 = unused
*       d2 = unused
*       d1 = unused
*       d0 = reserved for main prog.
*
****************************************
*       replay from memory             *
****************************************

ireplay move.b  (a6)+,d5       ;read from ram
        cmp.l   d6,a6          ;exceded end stop
        bgt.s   haltrep        ;branch if so
        jmp     INTOUTP        ;else output it

haltrep
        sf      inuse
        RTS

****************************************
*       the output routines            *
****************************************
*
INTOUTP
        MOVE.L  #$00,D4
        MOVE.L  #$00,D3

        and.w   #$00ff,d5       ; mask off rubbish
        add.b   #$80,d5         ; sign value
        lsl.w   #3,d5           ; double long word offset
        move.B  0(a3,d5.w),d4   ; get data #1       GET REGISTER TO CHANGE
        move.B  1(a3,d5.w),d3   ; get data #2       GET DATA
        SUB.B   #$08,D4         ; FIX FOR OUR CHIP
        AND.W   #$00FF,D4
        AND.W   #$00FF,D3
;       movep.l d4,0(a4)        ; play #1           REGISTER TO CHANGE
;       movep.w d3,0(a4)        ; play #2           DATA TO GIVE TO REGISTER


        MOVE.B   D4,SNDADD
        MOVE.B   D3,SNDDAT

        RTS

;-----------------------------------------------------------
;  ZERO VOLUME ON ALL VOICES
;-----------------------------------------------------------

ZEROVOL
        MOVE.B  #VOL0,SNDADD    ; SET ALL VOLUMES TO ZERO SINCE USING
        MOVE.B  #$00,SNDDAT     ; VSTAT TO ENABLE THE FREQUENCY DOES NOT
        MOVE.B  #VOL1,SNDADD    ; WORK CORRECTLY. WE END UP ENABLING
        MOVE.B  #$00,SNDDAT     ; VOICES WE ARE NOT USING.  THIS HAPPENS
        MOVE.B  #VOL2,SNDADD    ; WHEN LOOPING THROUGH THE VOICES THE 1ST
        MOVE.B  #$00,SNDDAT     ; TIME.  SINCE THE VOICES THAT HAVENT BEEN
        MOVE.B  #VOL3,SNDADD    ; DISABLE YET ARE STILL ACTIVE EVEN THOUGH
        MOVE.B  #$00,SNDDAT     ; THEY ARE NOT USED.
        MOVE.B  #VOL4,SNDADD
        MOVE.B  #$00,SNDDAT
        MOVE.B  #VOL5,SNDADD
        MOVE.B  #$00,SNDDAT
        RTS

;-----------------------------------------------------------
DELAY
        MOVE.L  #$FF,D2
DLUP
        DBRA    D2,DLUP
        RTS
;-----------------------------------------------------------

;           REG/DATA

snd_out dc.w    $80c,$90b,$a09,0,$80c,$90b,$a09,0
        dc.w    $80d,$908,$a08,0,$80b,$90b,$a0b,0
        dc.w    $80d,$909,$a05,0,$80c,$90b,$a08,0
        dc.w    $80d,$909,$a02,0,$80d,$908,$a06,0
        dc.w    $80c,$90b,$a07,0,$80d,$907,$a07,0
        dc.w    $80c,$90b,$a06,0,$80c,$90a,$a09,0
        dc.w    $80b,$90b,$a0a,0,$80c,$90b,$a02,0
        dc.w    $80c,$90b,$a00,0,$80c,$90a,$a08,0

        dc.w    $80d,$906,$a04,0,$80d,$905,$a05,0
        dc.w    $80d,$905,$a04,0,$80c,$909,$a09,0
        dc.w    $80d,$904,$a03,0,$80b,$90b,$a09,0
        dc.w    $80c,$90a,$a05,0,$80b,$90a,$a0a,0
        dc.w    $80c,$909,$a08,0,$80b,$90b,$a08,0
        dc.w    $80c,$90a,$a00,0,$80c,$90a,$a00,0
        dc.w    $80c,$909,$a07,0,$80b,$90b,$a07,0
        dc.w    $80c,$909,$a06,0,$80b,$90b,$a06,0

        dc.w    $80b,$90a,$a09,0,$80b,$90b,$a05,0
        dc.w    $80a,$90a,$a0a,0,$80b,$90b,$a02,0
        dc.w    $80b,$90a,$a08,0,$80c,$907,$a07,0
        dc.w    $80c,$908,$a04,0,$80c,$907,$a06,0
        dc.w    $80b,$909,$a09,0,$80c,$906,$a06,0
        dc.w    $80a,$90a,$a09,0,$80c,$907,$a03,0
        dc.w    $80b,$90a,$a05,0,$80b,$909,$a08,0
        dc.w    $80b,$90a,$a03,0,$80a,$90a,$a08,0

        dc.w    $80b,$90a,$a00,0,$80b,$909,$a07,0
        dc.w    $80b,$908,$a08,0,$80a,$90a,$a07,0
        dc.w    $80a,$909,$a09,0,$80c,$901,$a01,0
        dc.w    $80a,$90a,$a06,0,$80b,$908,$a07,0
        dc.w    $80a,$90a,$a05,0,$80a,$909,$a08,0
        dc.w    $80a,$90a,$a02,0,$80a,$90a,$a01,0
        dc.w    $80a,$90a,$a00,0,$809,$909,$a09,0
        dc.w    $80a,$908,$a08,0,$80b,$908,$a01,0

        dc.w    $80a,$909,$a06,0,$80b,$907,$a04,0
        dc.w    $80a,$909,$a05,0,$809,$909,$a08,0
        dc.w    $80a,$909,$a03,0,$80a,$908,$a06,0
        dc.w    $80a,$909,$a00,0,$809,$909,$a07,0
        dc.w    $809,$908,$a08,0,$80a,$908,$a04,0
        dc.w    $809,$909,$a06,0,$80a,$908,$a01,0
        dc.w    $809,$909,$a05,0,$809,$908,$a07,0
        dc.w    $808,$908,$a08,0,$809,$909,$a02,0

        dc.w    $809,$908,$a06,0,$809,$909,$a00,0
        dc.w    $809,$907,$a07,0,$808,$908,$a07,0
        dc.w    $809,$907,$a06,0,$809,$908,$a02,0
        dc.w    $808,$908,$a06,0,$809,$906,$a06,0
        dc.w    $808,$907,$a07,0,$808,$908,$a04,0
        dc.w    $808,$907,$a06,0,$808,$908,$a02,0
        dc.w    $807,$907,$a07,0,$808,$906,$a06,0
        dc.w    $808,$907,$a04,0,$807,$907,$a06,0

        dc.w    $808,$906,$a05,0,$808,$906,$a04,0
        dc.w    $807,$906,$a06,0,$807,$907,$a04,0
        dc.w    $808,$905,$a04,0,$806,$906,$a06,0
        dc.w    $807,$906,$a04,0,$807,$905,$a05,0
        dc.w    $806,$906,$a05,0,$806,$906,$a04,0
        dc.w    $806,$905,$a05,0,$806,$906,$a02,0
        dc.w    $806,$905,$a04,0,$805,$905,$a05,0
        dc.w    $806,$905,$a02,0,$805,$905,$a04,0

        dc.w    $805,$904,$a04,0,$805,$905,$a02,0
        dc.w    $804,$904,$a04,0,$804,$904,$a03,0
        dc.w    $804,$904,$a02,0,$804,$903,$a03,0
        dc.w    $803,$903,$a03,0,$803,$903,$a02,0
        dc.w    $803,$902,$a02,0,$802,$902,$a02,0
        dc.w    $802,$902,$a01,0,$801,$901,$a01,0
        dc.w    $802,$901,$a00,0,$801,$901,$a00,0
        dc.w    $801,$900,$a00,0,$800,$900,$a00,0

        dc.w    $80e,$90d,$a0c,0,$80f,$903,$a00,0
        dc.w    $80f,$903,$a00,0,$80f,$903,$a00,0
        dc.w    $80f,$903,$a00,0,$80f,$903,$a00,0
        dc.w    $80f,$903,$a00,0,$80e,$90d,$a0b,0
        dc.w    $80e,$90d,$a0b,0,$80e,$90d,$a0b,0
        dc.w    $80e,$90d,$a0b,0,$80e,$90d,$a0b,0
        dc.w    $80e,$90d,$a0b,0,$80e,$90d,$a0b,0
        dc.w    $80e,$90d,$a0a,0,$80e,$90d,$a0a,0

        dc.w    $80e,$90d,$a0a,0,$80e,$90d,$a0a,0
        dc.w    $80e,$90c,$a0c,0,$80e,$90d,$a00,0
        dc.w    $80d,$90d,$a0d,0,$80d,$90d,$a0d,0
        dc.w    $80d,$90d,$a0d,0,$80d,$90d,$a0d,0
        dc.w    $80d,$90d,$a0d,0,$80d,$90d,$a0d,0
        dc.w    $80e,$90c,$a0b,0,$80e,$90c,$a0b,0
        dc.w    $80e,$90c,$a0b,0,$80e,$90c,$a0b,0
        dc.w    $80e,$90c,$a0b,0,$80e,$90c,$a0b,0

        dc.w    $80e,$90c,$a0b,0,$80e,$90c,$a0b,0
        dc.w    $80e,$90c,$a0a,0,$80e,$90c,$a0a,0
        dc.w    $80e,$90c,$a0a,0,$80e,$90c,$a0a,0
        dc.w    $80d,$90d,$a0c,0,$80d,$90d,$a0c,0
        dc.w    $80e,$90c,$a09,0,$80e,$90c,$a09,0
        dc.w    $80e,$90c,$a05,0,$80e,$90c,$a00,0
        dc.w    $80e,$90c,$a00,0,$80e,$90b,$a0b,0
        dc.w    $80e,$90b,$a0b,0,$80e,$90b,$a0b,0

        dc.w    $80e,$90b,$a0b,0,$80e,$90b,$a0a,0
        dc.w    $80e,$90b,$a0a,0,$80e,$90b,$a0a,0
        dc.w    $80d,$90d,$a0b,0,$80d,$90d,$a0b,0
        dc.w    $80d,$90d,$a0b,0,$80e,$90b,$a09,0
        dc.w    $80e,$90b,$a09,0,$80e,$90b,$a09,0
        dc.w    $80d,$90c,$a0c,0,$80d,$90d,$a0a,0
        dc.w    $80e,$90b,$a07,0,$80e,$90b,$a00,0
        dc.w    $80e,$90b,$a00,0,$80d,$90d,$a09,0

        dc.w    $80d,$90d,$a09,0,$80e,$90a,$a09,0
        dc.w    $80d,$90d,$a08,0,$80d,$90d,$a07,0
        dc.w    $80d,$90d,$a04,0,$80d,$90d,$a00,0
        dc.w    $80e,$90a,$a04,0,$80e,$909,$a09,0
        dc.w    $80e,$909,$a09,0,$80d,$90c,$a0b,0
        dc.w    $80e,$909,$a08,0,$80e,$909,$a08,0
        dc.w    $80e,$909,$a07,0,$80e,$908,$a08,0
        dc.w    $80e,$909,$a01,0,$80c,$90c,$a0c,0

        dc.w    $80d,$90c,$a0a,0,$80e,$908,$a06,0
        dc.w    $80e,$907,$a07,0,$80e,$908,$a00,0
        dc.w    $80e,$907,$a05,0,$80e,$906,$a06,0
        dc.w    $80d,$90c,$a09,0,$80e,$905,$a05,0
        dc.w    $80e,$904,$a04,0,$80d,$90c,$a08,0
        dc.w    $80d,$90b,$a0b,0,$80e,$900,$a00,0
        dc.w    $80d,$90c,$a06,0,$80d,$90c,$a05,0
        dc.w    $80d,$90c,$a02,0,$80c,$90c,$a0b,0

        dc.w    $80c,$90c,$a0b,0,$80d,$90b,$a0a,0
        dc.w    $80d,$90b,$a0a,0,$80d,$90b,$a0a,0
        dc.w    $80d,$90b,$a0a,0,$80c,$90c,$a0a,0
        dc.w    $80c,$90c,$a0a,0,$80c,$90c,$a0a,0
        dc.w    $80d,$90b,$a09,0,$80d,$90b,$a09,0
        dc.w    $80d,$90a,$a0a,0,$80d,$90a,$a0a,0
        dc.w    $80d,$90a,$a0a,0,$80c,$90c,$a09,0
        dc.w    $80c,$90c,$a09,0,$80c,$90c,$a09,0

        dc.w    $80d,$90b,$a06,0,$80c,$90b,$a0b,0
        dc.w    $80c,$90c,$a08,0,$80d,$90b,$a00,0
        dc.w    $80d,$90b,$a00,0,$80c,$90c,$a07,0
        dc.w    $80c,$90c,$a06,0,$80c,$90c,$a05,0
        dc.w    $80c,$90c,$a03,0,$80c,$90c,$a01,0
        dc.w    $80c,$90b,$a0a,0,$80d,$90a,$a05,0
        dc.w    $80d,$90a,$a04,0,$80d,$90a,$a02,0
        dc.w    $80d,$909,$a08,0,$80d,$909,$a08,0



;-----------------------------------------------------------

xternal DEFB    1      ;$ff = external o/p selected
inuse   DEFB    1      ;interrupt in use flag
option  DEFB    1      ;int. option  $ff = sample
freqnum DEFB    1      ;frequency selected
status  DEFB    1      ;status register
mfpmem  DEFB    8      ;saved mfp data
sample  DEFB    1
length  DEFB    1
freqncy DEFB    1
stack   DEFB    1

        end
