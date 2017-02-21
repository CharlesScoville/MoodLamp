;***********************************************************************************;
;                                                                         			;
;    Filename:         18F13K50.asm                                      			;
;    Date:             Sunday, April 29, 2012                                		;
;    File Version:     v 1.0                                                 		;
;    Author:           Charles Scoville. AKA: Oblivion                       		;
;    Company:          Meh...                                               		;
;	 Font:			   Any monospaced font								 			;
;	 Purpose:		   Mood lamp using tri-color LEDs. A LFSR based RNG is used. 	;
;                                                                             		;
; Notes:
; For a 120Hz refresh rate the period is ~8.33ms.
; At 8M cycles per second for ~8.3ms is ~66k cycles
; 2^16 (65,536) cycles, as done by timer0, is damn close to this.
; 0x0000 -> 0xffff at FOSC/4 = 8.192ms  (122.07Hz)
;***********************************************************************************;
;                                                                             		;
;   Files Required: P18F13K50.INC                                             		;
;                                                                             		;
;***********************************************************************************;
; Part and project pinout.
;                              ____   ____
;                             | o  \_/    |
;         VDD - 5V power     [| 1       20|]    Vss - Ground
;                             |           |
;                            [| 2       19|]    ICSP-DAT
;                             |           |
;                            [| 3       18|]    ICSP-CLK
;                             |           |
;     VPP (MCLR internal)    [| 4       17|]    Vusb 3.3v reg (bypass with cap)
;                             |           |
; 		       RC5 as R_4    [| 5       16|]    RC0 as R_1
;                             |           |
; 			   RC4 as G_4    [| 6       15|]    RC1 as G_1
;                             |           |
; 			   RC3 as B_4    [| 7       14|]    RC2 as B_1
;                             |           |
; 		 	   RC6 as R_3    [| 8       13|]    RB4 as R_2
;                             |           |
; 			   RC7 as G_3    [| 9       12|]    RB5 as G_2
;                             |           |
;              RB7 as B_3    [|10       11|]    RB6 as B_2
;                             |___________|
;
;
;____________________________________________________________________________________
; PROCESSOR DECLARATION
;____________________________________________________________________________________

     LIST      P=PIC18F13K50          ; list directive to define processor
     #INCLUDE <P18F13K50.INC>         ; processor specific variable definitions

;____________________________________________________________________________________
; Definitions and Declarations
;____________________________________________________________________________________
;;{

						   	   		 ; V PIN numbers V
		#define	R_1		PWM_PINS+0,0 ; 16
		#define	G_1		PWM_PINS+0,1 ; 15
		#define	B_1		PWM_PINS+0,2 ; 14

		#define	R_2		PWM_PINS+1,4 ; 13
		#define	G_2		PWM_PINS+1,5 ; 12
		#define	B_2 	PWM_PINS+1,6 ; 11

		#define	R_3 	PWM_PINS+0,6 ; 8
		#define	G_3 	PWM_PINS+0,7 ; 9
		#define	B_3 	PWM_PINS+1,7 ; 10

		#define	R_4 	PWM_PINS+0,5 ; 5
		#define	G_4 	PWM_PINS+0,4 ; 6
		#define	B_4 	PWM_PINS+0,3 ; 7

		#define TRUE 	1
		#define FALSE 	-1
		#define YES 	1
		#define NO 		0
		#define SUCCESS	1
		#define FAILURE	-1

		#define PWM_RLD	FLAGS,0

		#define EERDWT 	FLAGS,1

		#define RBS		FLAGS,2					
		#define GBS		FLAGS,3   	; Ring buffer Selectors
		#define BBS		FLAGS,4		; *TODO* these aren't actually used
;;}
;____________________________________________________________________________________

;____________________________________________________________________________________
; CONFIGURATION WORD SETUP
;____________________________________________________________________________________
;;{
     CONFIG CPUDIV 	= NOCLKDIV	; CPU runs at full 48Mhz clock speed
	 CONFIG USBDIV 	= OFF		; USB runs at full 48Mhz clock speed
	 CONFIG FOSC 	= IRC		; High Speed Xtal in use, so high drive needed
	 CONFIG PLLEN 	= ON		; 4x PLL is on. (12Mhz x 4 = 48Mhz)
     CONFIG PCLKEN 	= ON		; Primary clock is on, (not software control)
	 CONFIG FCMEN 	= OFF		; Fail safe clock monitor is OFF
	 CONFIG IESO 	= OFF		; Switching the clock is DISABLED
	 CONFIG PWRTEN 	= OFF		; Powerup timer ON, CPU waits until power is stable
	 CONFIG BOREN 	= OFF		; Brown out reset DISABLED
     CONFIG BORV 	= 30		; 3.0v; Highest Brown out voltage possible
	 CONFIG WDTEN 	= OFF		; Watch dog timer DISABLED
	 CONFIG WDTPS 	= 1			; WDT post scaler, 1:1 (don't matter)
	 CONFIG MCLRE 	= OFF		; Master clear/reset is internal. RA3 is GPIO
	 CONFIG HFOFST 	= OFF		; System is held in reset untill clock is stable
     CONFIG STVREN 	= OFF		; Hardware stack over/under flow disabled
	 CONFIG LVP 	= OFF		; Low voltage programming is OFF
	 CONFIG BBSIZ 	= OFF		; Boot block size is 512 words. (don't matter)
	 CONFIG XINST 	= OFF		; Extended C language instruction set is OFF

	 CONFIG DEBUG   = OFF		; Internal debugging hardware dissabled.

	 CONFIG CP0 	= OFF		;
     CONFIG CP1 	= OFF		;
	 CONFIG CPB 	= OFF		;
	 CONFIG CPD 	= OFF		;
	 CONFIG WRT0 	= OFF		;
	 CONFIG WRTB 	= OFF		;  ALL FORMS OF CODE PROTECTION ARE OFF
     CONFIG WRTC 	= OFF		;
	 CONFIG WRTD 	= OFF		;
	 CONFIG EBTR0 	= OFF		;
	 CONFIG EBTR1 	= OFF		;
	 CONFIG EBTRB 	= OFF		;
;;}
;____________________________________________________________________________________

;____________________________________________________________________________________
; Variables
;____________________________________________________________________________________
;;{
GPR_VAR        UDATA
;INT_VAR        UDATA_ACS

; ISR shadow for important registers 
W_TEMP		res	1
STATUS_TEMP	res	1
BSR_TEMP	res	1

FLAGS	res	1; Flags, for Yes/No things

; 8 bit PWM timers/Counters
R1_TIME	res	1
G1_TIME	res	1
B1_TIME	res	1

R2_TIME	res	1
G2_TIME	res	1
B2_TIME	res	1

R3_TIME	res	1
G3_TIME	res	1
B3_TIME	res	1

R4_TIME	res	1
G4_TIME	res	1
B4_TIME	res	1

DUMMY_TIME	res	1; DUMMY_TIME is always 255, and sets the pace

PWM_PINS 	res 2	; This is the pin mask, used to change all pins at once.

; LFSR registars for PRNG
LFSR_01	res	1
LFSR_02	res	1
LFSR_03	res	1
LFSR_04	res	1
LFSR_05	res	1
RAND	res	1 ; Final 8 bit Random number

; EEPROM engine arguments
;WREG		; Ram target address
;(bit)EERDWT; *TODO* Read/Write operation
EE_ADDRESS	res	1 ; EEPROM target address
EE_LENGTH	res	1 ; Length of EEPROM data

; 24 bit Intermediate Hermite Products
C0xP0	res 3
C1xP1	res	3
C2xP2	res	3
C3xP3	res	3

; Temp storage for 16 bit Hermite coefficients, table look up
c0 res	2
c1 res	2
c2 res	2
c3 res	2

; Spline starting points. Filled with Random data, see "Fill_Buffer" sub
p0	res	1
p1	res	1
p2	res	1
p3	res	1

R_p0	res	1
R_p1	res	1
R_p2	res	1
R_p3	res	1

G_p0	res	1
G_p1	res	1
G_p2	res	1
G_p3	res	1

B_p0	res	1
B_p1	res	1
B_p2	res	1
B_p3	res	1

; Ring buffer variables
_CHAR		res	1
_COEF_POINT	res	1
_COUNT		res	1
_OUT_POINT	res	1
_RINGBUFF_P	res	1

PWM_COUNT		res	1; Number of B ring buffer bytes used 
PWM_IN_POINT	res	1; Pointing to input address of ring buffer, the "head"
PWM_OUT_POINT	res	1; Pointing to output address of ring buffer, the "tail"
PWM_RINGBUFF	res .24	; Actual ring buffer, 24 bytes long.

R_COEF_POINT	res	1
R_COUNT			res	1 ; Number of R ring buffer bytes used
R_IN_POINT		res	1 ; Pointing to input address of ring buffer, the "head"
R_OUT_POINT		res	1 ; Pointing to output address of ring buffer, the "tail"
R_RINGBUFF		res	.16	; Actual ring buffer, 16 bytes long.

G_COEF_POINT	res	1
G_COUNT			res	1; Number of G ring buffer bytes used
G_IN_POINT		res	1; Pointing to input address of ring buffer, the "head"
G_OUT_POINT		res	1; Pointing to output address of ring buffer, the "tail"
G_RINGBUFF		res	.16	; Actual ring buffer, 16 bytes long.

B_COEF_POINT	res	1
B_COUNT			res	1; Number of B ring buffer bytes used 
B_IN_POINT		res	1; Pointing to input address of ring buffer, the "head"
B_OUT_POINT		res	1; Pointing to output address of ring buffer, the "tail"
B_RINGBUFF		res	.16	; Actual ring buffer, 16 bytes long.
;;}
;____________________________________________________________________________________

;____________________________________________________________________________________
; EEPROM PRE-INITIALIZATION
; The 18F13K50 has non-volatile memory (EEPROM) starting at 0xF00000
;____________________________________________________________________________________
;;{
DATAEE    	ORG  0xF00000 ; Starting address for EEPROM for 18F13K50

	; Place seed for RNG in EEPROM
    DE    	"Ëì£©ÙÚ"  ; 6 bytes

; List of other seeds you could choose from. (generated with KeePass 2.34)
;
; "¸J/ªàr" ";û3Îú5" "Ëì£©ÙÚ" "Fgõá2¨" "¤¢Áo#s" "/8ê.F<" "Ïãñ{r®",
; "Eúý°%?" "&ÍFUØe" "Á¨~·¬¡" "ø]q<õn" "ÉADÁqà" "MÃÚ2ÚP" "y$Ô/wu",
; "e½ß°~ã" "Qoõo:}" ">ºÎó¬$" "Tô¦MJÐ" "~V-þ&Î" "²~VÔ%ð" "2ªüCò[",
; "Ô§4Æx¦" ")ÐBÈþú" "Ö ý~¥!" "ÄËDáËþ" "Ø_ÞD,÷" "ï¨ðXKj" "ëv+.®.",
;;}
;____________________________________________________________________________________

;____________________________________________________________________________________
; RESET VECTOR
;____________________________________________________________________________________

RES_VECT  	ORG     0x0000            ; processor reset vector
           	GOTO    START             ; go to beginning of program

;____________________________________________________________________________________
; INTERRUPT VECTORS
;____________________________________________________________________________________
;;{
ISRH      	ORG     0x0008

          	; Run the low Priority Interrupt Service Routine
			GOTO    LOW_ISR
;************************************************************************************
; Note: When priority interrupt is disabled, all int-vectors remap to 0x0008.
;************************************************************************************
ISRL      	ORG     0x0018

          	; Run the low Priority Interrupt Service Routine
          	GOTO    LOW_ISR 
;;}
;____________________________________________________________________________________

;____________________________________________________________________________________
; INTERRUPT SERVICE ROUTINES
;____________________________________________________________________________________
;;{
LOW_ISR
          	; Context Saving for Low ISR
         	MOVWF   W_TEMP              ; save W register
          	MOVFF   STATUS, STATUS_TEMP ; save status register
         	MOVFF   BSR, BSR_TEMP       ; save bankselect register

			BTFSS	INTCON,TMR0IF		; Test to see if Timer0 is what caused
			BRA		END_INT				; this interupt. If so handle it.

;------------------------------------------------------------------------------------
; Timer0 interrupt service
;
; The only thing that should be done here is loading the new delay and changing pins
;
; *TODO* these full reads are probably actually excessive. Yet another buffer for
; each of these would probably be better performing. Then it could just be 3 MOVFF's

			RCALL	READ_BUFFER_PWM		; First byte in buffer is delay
			MOVWF	TMR0H				; until next change in output.

			RCALL	READ_BUFFER_PWM		; Next two bytes are the pin masks
			ANDWF	LATC				; 
			RCALL	READ_BUFFER_PWM		; Note that this is ANDed, so preserves
			ANDWF	LATB				; the state of bits not 0 in the mask.

			CLRF	TMR0L		; <--- This is the exact point Timer0 gets updated
;------------------------------------------------------------------------------------

			BCF		INTCON, TMR0IF		; Reset Timer0 interupt flag

END_INT    ; Context Saving for Low ISR
          	MOVFF   BSR_TEMP, BSR       ; restore bankselect register
          	MOVF    W_TEMP, W           ; restore W register
          	MOVFF   STATUS_TEMP, STATUS ; restore status register
	RETFIE ;
;;}
;____________________________________________________________________________________

;____________________________________________________________________________________
; INITIALIZE SYSTEM
;____________________________________________________________________________________
;;{
;************************************************************************************
; First some general setup to make all the pins behave as they are supposed to.
;************************************************************************************
START		
			; Initialize GPRs _________________________________________
			LFSR    FSR0, 000h 	 ; 
	    	CLRF    POSTINC0   	 ; Clear INDF register then inc pointer
			BTFSS   FSR0H, 1     ; All done with Bank1?
			BRA     $ - 4        ; NO, clear next | YES, continue
			;__________________________________________________________

			; Initialize Ring buffers _________________________________
			MOVLW	R_RINGBUFF	 ; Initilize the ring buffer
			MOVWF	R_IN_POINT	 ; to known good state.
			MOVWF	R_OUT_POINT	 ; (sort of... it still could have data)

			MOVLW	G_RINGBUFF	 ; Initilize the ring buffer
			MOVWF	G_IN_POINT	 ; to known good state.
			MOVWF	G_OUT_POINT	 ; (sort of... it still could have data)

			MOVLW	B_RINGBUFF	 ; Initilize the ring buffer
			MOVWF	B_IN_POINT	 ; to known good state.
			MOVWF	B_OUT_POINT	 ; (sort of... it still could have data) 

			MOVLW	PWM_RINGBUFF ; Initilize the ring buffer
			MOVWF	PWM_IN_POINT ; to known good state.
			MOVWF	PWM_OUT_POINT; (sort of... it still could have data)
			;__________________________________________________________

			; Initialize PRNG ________________________________________
			;CLRF	EE_ADDRESS	 ; Load the first EE address (0x00).
	
			MOVLW	.6		 	 ; We're getting 6 bytes
			MOVWF	EE_LENGTH	 ; 

			MOVLW	LFSR_01		 ; The target RAM is the LFSR
			CALL	EE_READ	     ; 
			;__________________________________________________________

			SETF	DUMMY_TIME	 ; Set PWM loop to known state, make sure
			BSF		PWM_RLD		 ; it knows the data is invalid though

			;RCALL 	Fill_Buffer ; Generate some random points

;------------------------------------------------------------------------------------
; Processor specific setup. 
; If you're porting to a different PIC, or changing the circuit, this needs changed
;------------------------------------------------------------------------------------
			CLRF 	TMR0L
			CLRF	TMR0H

; *TODO* Prescaler is a convient way to control rate of change for colors.
			MOVLW	b'10001000'
;					  ||||||||__					
;					  |||||||___\ __ T0PS0:2		Prescaler.
;					  ||||||____/ 
;					  |||||_________ PSA			1 = Timer0 Prescaler bypassed
;					  ||||
;					  ||||__________ T0SE			Edge select. 0 = L2H
;					  |||
;					  |||___________ T0CS			0 = Internal clock
;					  ||
;					  ||____________ T0 8BIT/16bit	0 = 16bit mode
;					  |
;					  |_____________ TMR0ON  		1 = ON, 0 = OFF
			MOVWF	T0CON

			BSF		INTCON, PEIE   ; Enable peripheral interupt

			BSF		INTCON, TMR0IE ; Enable Timer0 interupt

			BCF		ADCON0, ADON   ; Turn off the ADC when not in use.

			MOVLW	b'00000000'	   ; Some port pins are multiplexed with analog  
			MOVWF	ANSEL		   ; functions. Clearing an ANSELx bit enables
			MOVLW	b'00000000'	   ; digital functionality.
			MOVWF	ANSELH		   ; *** DON'T CLEAR IF ANALOG SIGNAL IS PRESENT ***

			CLRF	TRISC		   ; Make PORTC all outputs

			MOVLW	b'00001111'	   ; Make most the significant
			ANDWF	TRISB		   ; nyble of PORTB outputs.

			BSF		INTCON, GIE	   ; Enable global interupts last
;;}
;____________________________________________________________________________________

;____________________________________________________________________________________
; MAIN PROGRAM LOOP
;____________________________________________________________________________________
MAIN

;====================================================================================
; Determine lighting mode (Human input, default mode)
;;{
; *TODO* All of this
;;}
;====================================================================================


;====================================================================================
; Compute color data and load buffers
;;{
; Check to see if R channel's ring buffer is full.
				MOVLW	.16
				CPFSLT	R_COUNT
				BRA		_Fill_G

; Load channel related variables for passing to Cubic Hermite routine
				MOVFF	R_p0, p0
				MOVFF	R_p1, p1
				MOVFF	R_p2, p2
				MOVFF	R_p3, p3
				MOVFF	R_COEF_POINT, _COEF_POINT
				MOVFF	R_COUNT, _COUNT
				MOVFF	R_IN_POINT, FSR0L
				MOVLW	R_RINGBUFF
				MOVWF	_RINGBUFF_P

; This does as much Cubic Hermite on the loaded channel as is possible. (<16 bytes)
					RCALL	Cubic_Hermite

; Save off this channels variables so we can move to the next.
				MOVFF	p0, R_p0
				MOVFF	p1, R_p1
				MOVFF	p2, R_p2
				MOVFF	p3, R_p3
				MOVFF	_COEF_POINT, R_COEF_POINT
				MOVFF	_COUNT, R_COUNT
				MOVFF	FSR0L, R_IN_POINT

_Fill_G
				MOVLW	.16
				CPFSLT	G_COUNT
				BRA		_Fill_B

				MOVFF	G_p0, p0
				MOVFF	G_p1, p1
				MOVFF	G_p2, p2
				MOVFF	G_p3, p3
				MOVFF	G_COEF_POINT, _COEF_POINT
				MOVFF	G_COUNT, _COUNT
				MOVFF	G_IN_POINT, FSR0L
				MOVLW	G_RINGBUFF
				MOVWF	_RINGBUFF_P

					RCALL	Cubic_Hermite

				MOVFF	p0, G_p0
				MOVFF	p1, G_p1
				MOVFF	p2, G_p2
				MOVFF	p3, G_p3
				MOVFF	_COEF_POINT, G_COEF_POINT
				MOVFF	_COUNT, G_COUNT
				MOVFF	FSR0L, G_IN_POINT

_Fill_B
				MOVLW	.16
				CPFSLT	B_COUNT
				BRA		_LOAD_TIMERS

				MOVFF	B_p0, p0
				MOVFF	B_p1, p1
				MOVFF	B_p2, p2
				MOVFF	B_p3, p3
				MOVFF	B_COEF_POINT, _COEF_POINT
				MOVFF	B_COUNT, _COUNT
				MOVFF	B_IN_POINT, FSR0L
				MOVLW	B_RINGBUFF
				MOVWF	_RINGBUFF_P

					RCALL	Cubic_Hermite

				MOVFF	p0, B_p0
				MOVFF	p1, B_p1
				MOVFF	p2, B_p2
				MOVFF	p3, B_p3
				MOVFF	_COEF_POINT, B_COEF_POINT
				MOVFF	_COUNT, B_COUNT
				MOVFF	FSR0L, B_IN_POINT


_LOAD_TIMERS
; Once we have interpolated on our randomly generated points, we finally have 
; some timeing data to load. This simple routing fills the delays with that data.
; This area is where you would modify the loop to get different effects.
				BTFSS	PWM_RLD
				BRA		_FILL_PWM

				RCALL	READ_BUFFER_R
				MOVWF	R1_TIME
				MOVWF	R2_TIME
				MOVWF	R3_TIME
				MOVWF	R4_TIME

				RCALL	READ_BUFFER_G
				MOVWF	G1_TIME
				MOVWF	G2_TIME
				MOVWF	G3_TIME
				MOVWF	G4_TIME

				RCALL	READ_BUFFER_B
				MOVWF	B1_TIME
				MOVWF	B2_TIME
				MOVWF	B3_TIME
				MOVWF	B4_TIME

				BCF		PWM_RLD

_FILL_PWM
				BTFSC	PWM_RLD
				BRA		_LOAD_TIMERS	

				MOVLW	.22
				CPFSLT	PWM_COUNT
				BRA		MAIN

				MOVFF	PWM_COUNT, _COUNT
				MOVFF	PWM_IN_POINT, FSR0L
				MOVLW	PWM_RINGBUFF
				MOVWF	_RINGBUFF_P

				RCALL	TIME_DOWN
				
				MOVFF	_COUNT, PWM_COUNT
				MOVFF	FSR0L, PWM_IN_POINT

				BRA		_FILL_PWM
;;}
;====================================================================================

;    BRA 	MAIN        ; loop program to beginning

;____________________________________________________________________________________
;                                       Subroutines
;____________________________________________________________________________________

;-----------------------------------------;
; Decrement timers and buffer bit changes ;
;____________________________________________________________________________________
;;{
TIME_DOWN
;	Find the smallest delay, move it to working.
			MOVF	R1_time,W
			CPFSGT	G1_time
			MOVF 	G1_time,W
			CPFSGT	B1_time
			MOVF	B1_time,W

			CPFSGT	R2_time
			MOVF	R2_time,W
			CPFSGT	G2_time
			MOVF	G2_time,W
			CPFSGT	B2_time
			MOVF	B2_time,W

			CPFSGT	R3_time
			MOVF	R3_time,W
			CPFSGT	G3_time
			MOVF	G3_time,W
			CPFSGT	B3_time
			MOVF	B3_time,W

			CPFSGT	R4_time
			MOVF	R4_time,W
			CPFSGT	G4_time
			MOVF	G4_time,W
			CPFSGT	B4_time
			MOVF	B4_time,W

			CPFSGT	DUMMY_TIME
			MOVF	DUMMY_TIME, W

; WREG now contains the smallest delay, now subtract that from all the delays.
 
	        SUBWF	DUMMY_TIME,F	; If we go over 255, our PWM period
			BZ		TIME_UP			; has been reached, so issue a reset

			INCF	WREG			; Inc so we can get a carry out

; This next part is kinda trick actually.
;
; When a delay overflows, it's associated pin needs a state change. The naive
; aproach would be to simply test for zero, then set/clear a bit. That takes
; 3 instructions per bit. We can do better though ;) The subtract instruction 
; has a TRUE/FALSE result, the carry bit, which we CAN just shift into some
; other buffer. After shifting every bit, we end up with a mask that can simply
; be copied to the Latch register as is. The only intricacy is that we have to 
; do it in the proper order for the resulting mask to match the pinout.

; Use this as a reference for the order the mask needs to be created
;		#define	R_1		LATC,0 ; 16
;		#define	G_1		LATC,1 ; 15
;		#define	B_1		LATC,2 ; 14
;		#define	B_4 	LATC,3 ; 7
;		#define	G_4 	LATC,4 ; 6
;		#define	R_4 	LATC,5 ; 5
;		#define	R_3 	LATC,6 ; 8
;		#define	G_3 	LATC,7 ; 9

;		#define	R_2		LATB,4 ; 13
;		#define	G_2		LATB,5 ; 12
;		#define	B_2 	LATB,6 ; 11
;		#define	B_3 	LATB,7 ; 10

			SUBWF	G3_time,F
			RLCF	PWM_PINS+0,F
			SUBWF	R3_time,F
			RLCF	PWM_PINS+0,F
			SUBWF	R4_time,F
			RLCF	PWM_PINS+0,F
			SUBWF	G4_time,F
			RLCF	PWM_PINS+0,F
			SUBWF	B4_time,F
			RLCF	PWM_PINS+0,F
			SUBWF	B1_time,F
			RLCF	PWM_PINS+0,F
			SUBWF	G1_time,F
			RLCF	PWM_PINS+0,F
			SUBWF	R1_time,F
			RLCF	PWM_PINS+0,F

			SETF	PWM_PINS+1

			SUBWF	B3_time,F
			RLCF	PWM_PINS+1,F
			SUBWF	B2_time,F
			RLCF	PWM_PINS+1,F
			SUBWF	G2_time,F
			RLCF	PWM_PINS+1,F
			SUBWF	R2_time,F
			RLCF	PWM_PINS+1,F

; WREG still has the lowest delay. Let's buffer it. 

			DECF	WREG
			RCALL	WRITE_PWM_BUFFER

; Also output the mask for the pins that will switch next.

			MOVF	PWM_PINS+0,W
			RCALL	WRITE_PWM_BUFFER

			MOVF	PWM_PINS+1,W
			RCALL	WRITE_PWM_BUFFER

	RETLW	SUCCESS

TIME_UP
			RCALL	WRITE_PWM_BUFFER

			DECF	DUMMY_TIME

			CLRF	PWM_PINS+0
			MOVF	PWM_PINS+0, W
			RCALL	WRITE_PWM_BUFFER

			MOVLW	b'11110000'			; Need to leave the top pins alone.
			MOVWF	PWM_PINS+1			;

			MOVF	PWM_PINS+1, W
			RCALL	WRITE_PWM_BUFFER

			BSF		PWM_RLD
	RETLW	FAILURE
;;}
;____________________________________________________________________________________

;--------------------------------------------------;
; Fill the starting point buffers with random data ;
;____________________________________________________________________________________
;;{
Fill_Buffer
			LFSR    FSR0, R_P0 	 	; Load pointer to the interpolant data points.
			
GEN_LOOP		RCALL	GEN_RANDOM		; Generate a new random number from the LFSR

				MOVFF	RAND, POSTINC0	; Mov RAND to *FSR

				MOVLW	B_P3			; 
				CPFSGT	FSR0L			; if interpolant pointer > last point
				BRA		GEN_LOOP		; move on.
	RETURN
;;}
;____________________________________________________________________________________

;----------------------------------------------------------;
; Cubic Hermite Interpolation, using precomputed constants ;
;____________________________________________________________________________________
;;{
;************************************************************************************
; Big thanks to Robert bristow-johnson, and Olli Niemitalo from signal processing 
; Stack Exchange. Without these two, I never would have understood how to do this.
; Here is a (split) URL to my question, and their response, for more info.
;
; http://dsp.stackexchange.com/questions/36250/
; algorithm-for-1d-spline-interpolation-suitable-for-8-bit-microcontroler
;
;************************************************************************************
;
; There are (at least) two ways to do this calculation with valid order of operations
;
; 	(1): (C1*P1 + C2*P2)-(C0*P0 + C3*P3)
; 	(2): (((C1*P1 + C2*P2)- C0*P0) - C3*P3)
; 
; The addition rutine has a single bit overflow, using it twice would compound the
; issue. The subtraction can handle it by assuming a borrow was an addition overflow.
; So the number 2 case is the prefered way to do this.
;____________________________________________________________________________________

Cubic_Hermite
			RCALL	GET_COEF		; Load the coefficents for our fractional step

			INCFSZ	WREG			; Sub returns FAILURE status when the
			BRA		ITTERATE		; fraction is 0, meaning output = P1

; Cycle points
;------------------------------------------------------------------------------------
			MOVFF	P1,P0			; To keep the curvy line smooth and 
			MOVFF	P2,P1			; break free, we "slide" the control
			MOVFF	P3,P2			; points back down, and load one more
									; random byte on the top 
			
			RCALL	GEN_RANDOM		; Generate a new random number from the LFSR

			MOVFF	RAND, P3		; Load our adjusted random number
;------------------------------------------------------------------------------------

			MOVF	P1,W			; Since we are starting from 0, output = P1

WRITE_BUFFER
			RCALL	WRITE_RING_BUFFER

			INCFSZ	WREG
			BRA		Cubic_Hermite
	RETURN

;------------------------------------------------------------------------------------
;	16x8 Bit Unsigned Fixed Point Multiply 16 x 08 -> 24
;
;	Input:  16 bit unsigned fixed point multiplicand in Cn+0 and Cn+1
;			8 bit unsigned fixed point multiplier in Pn
;
;	Output: 24 bit unsigned fixed point product in CnxPn+0, CnxPn+1, CnxPn+2
;------------------------------------------------------------------------------------

ITTERATE
; C1*P1
			MOVF	P0, W
			MULWF	C0+1
			MOVFF	PRODH, C0xP0+2
			MOVFF	PRODL, C0xP0+1
			MULWF	C0+0
			MOVFF	PRODL, C0xP0+0
			MOVF	PRODH, W
			ADDWF	C0xP0+1, F
			BNC		$ + 4
			INCF	C0xP0+2
; C2*P2
			MOVF	P1, W
			MULWF	C1+1
			MOVFF	PRODH, C1xP1+2
			MOVFF	PRODL, C1xP1+1
			MULWF	C1+0
			MOVFF	PRODL, C1xP1+0
			MOVF	PRODH, W
			ADDWF	C1xP1+1, F
			BNC		$ + 4
			INCF	C1xP1+2
; C0*P0
			MOVF	P2, W
			MULWF	C2+1
			MOVFF	PRODH, C2xP2+2
			MOVFF	PRODL, C2xP2+1
			MULWF	C2+0
			MOVFF	PRODL, C2xP2+0
			MOVF	PRODH, W
			ADDWF	C2xP2+1, F
			BNC		$ + 4
			INCF	C2xP2+2
; C3*P3
			MOVF	P3, W
			MULWF	C3+1
			MOVFF	PRODH, C3xP3+2
			MOVFF	PRODL, C3xP3+1
			MULWF	C3+0
			MOVFF	PRODL, C3xP3+0
			MOVF	PRODH, W
			ADDWF	C3xP3+1, F
			BNC		$ + 4
			INCF	C3xP3+2
;
; 24 bit addition with carry through.
; Operation: C2xP2 + C1xP1 => C1xP1
;
        	MOVF    C2xP2+0,W		; Get low byte
        	ADDWF   C1xP1+0,F		; Add to destination
        	MOVF    C2xP2+1,W   	; Get high byte
        	ADDWFC  C1xP1+1,F		; Add high byte + carry
			MOVF    C2xP2+2,W		;
        	ADDWFC  C1xP1+2,F		; Add high byte + carry

;-----------------------------------------------------------------------------------
; There is an edge case where this last ADDWFC instruction results in a carry. 
; This ignored here because it's handled when the subtraction results in borrow.
;-----------------------------------------------------------------------------------
;
; 24 bit subtraction: C1xP1 - C0xP0 => C1xP1
; Carry is preserved.
;
	        MOVF    C0xP0+0,W		; 
	        SUBWF   C1xP1+0,F		; 
	        MOVF    C0xP0+1,W		; Chain of subtractions with borrow
	        SUBWFB	C1xP1+1,F		; 
	        MOVF    C0xP0+2,W		; 
	        SUBWFB	C1xP1+2,F		; 

			BC		$ + .8			; 
			SETF	WREG			; For the edge case where we borrow on  
			ADDWF	C1xP1+2,F		; the high byte, add 255+1 (256) to it.
			INCF	C1xP1+2,F		; (There could only have been 1 carry bit)
;
; 24 bit subtraction: C1xP1 - C3xP3 => C1xP1
; Carry is preserved.
;
	        MOVF    C3xP3+0,W		; 
	        SUBWF   C1xP1+0,F		; 
	        MOVF    C3xP3+1,W		; Chain of subtractions with borrow
	        SUBWFB	C1xP1+1,F		; 
	        MOVF	C3xP3+2,W		; 
	        SUBWFB	C1xP1+2,F		; 

			BC		$ + .8			; 
			SETF	WREG			; For the edge case where we borrow on
			ADDWF	C1xP1+2,F		; the high byte, add 255+1 (256) to it.
			INCF	C1xP1+2,F		;(There could only have been 1 carry bit)
;
; Round by adding 0.5 (128) to the mid byte. Low byte is so insignificant
; that we don't need to bother rounding through it; just save the cycles.
;
        	MOVLW	.128			; 
        	ADDWF   C1xP1+1,F		; If there is a carry here, then the fraction 
        	BTFSC   STATUS,C		; (C1xP1-mid) is higher than half, or 0.5
       	 	INCF  	C1xP1+2,W		; So the whole part (C1xP1-High) rounds up 1.
;
; Output byte to the buffer.
;
			MOVF	C1xP1+2,W		; Dropping the lowest two bytes is
									; an effective divide by 2^16

			; WREG now contains answer

			BRA		WRITE_BUFFER	; Start it up again.
;;}
;____________________________________________________________________________________

;--------------------------------------;
; Get coefficients (8 Byte table read) ;
;____________________________________________________________________________________
;;{
GET_COEF  
			TSTFSZ	_COEF_POINT
			BRA		$ + .8

			MOVLW	.8				; Manually increment pointer to coefficient
			ADDWF	_COEF_POINT,F	; data (in multiples of 8 (2-byte x 4-byte))

	RETLW	FAILURE					; First set is constant answer, so just return

			MOVFF	  _COEF_POINT, TBLPTRL
			CLRF      TBLPTRU		; 
			MOVLW     0x08			; Load TBLPTR with the base address
			MOVWF     TBLPTRH 		; 

			TBLRD*+            		; read into TABLAT and increment
			MOVF      TABLAT, W		; get data
			MOVWF     c0+0
			TBLRD*+					; read into TABLAT and increment
			MOVF      TABLAT, W		; get data
			MOVWF     c0+1
			TBLRD*+					; read into TABLAT and increment
			MOVF      TABLAT, W		; get data
			MOVWF     c1+0
			TBLRD*+					; read into TABLAT and increment
			MOVF      TABLAT, W		; get data
			MOVWF	  c1+1
			TBLRD*+            		; read into TABLAT and increment
			MOVF      TABLAT, W		; get data
			MOVWF     c2+0
			TBLRD*+					; read into TABLAT and increment
			MOVF      TABLAT, W		; get data
			MOVWF     c2+1
			TBLRD*+					; read into TABLAT and increment
			MOVF      TABLAT, W		; get data
			MOVWF     c3+0
			TBLRD*+					; read into TABLAT and increment
			MOVF      TABLAT, W		; get data
			MOVWF	  c3+1

			MOVFF	TBLPTRL, _COEF_POINT ; This automatically makes the pointer right

			MOVLW	0x80			; 
			CPFSLT	_COEF_POINT,W	; If we're past the end of the table,
			CLRF	_COEF_POINT		; need to go back to the start (0x00)

	RETLW	SUCCESS
;;}
;____________________________________________________________________________________

;-------------------;
; Write ring buffer ;
;____________________________________________________________________________________
;;{

; *TODOs* 
; (1) consolidate this all into one sub that will work for any ring buffer.
; (2) Use the FLAGS reg to signal to other parts of the system the state of a buffer

WRITE_RING_BUFFER
			MOVWF 	_CHAR

			MOVLW	.16
			CPFSLT	_COUNT
			BRA		CANT_WRITE
				CLRF	FSR0H
				MOVFF	_CHAR, POSTINC0
				INCF	_COUNT
				MOVLW	.16
				SUBWF	FSR0L,W
				CPFSGT	_RINGBUFF_P
					MOVWF	FSR0L

	RETLW	SUCCESS
CANT_WRITE							
	RETLW	FAILURE
;------------------------------------------------------------------------------------
WRITE_PWM_BUFFER
			MOVWF 	_CHAR

			MOVLW	.24
			CPFSLT	_COUNT
			BRA		CANT_WRITE_PWM
				CLRF	FSR0H
				MOVFF	_CHAR, POSTINC0
				INCF	_COUNT
				MOVLW	.24
				SUBWF	FSR0L,W
				CPFSGT	_RINGBUFF_P
					MOVWF	FSR0L

	RETLW	SUCCESS
CANT_WRITE_PWM							
	RETLW	FAILURE
;;}
;____________________________________________________________________________________

;------------------;
; Read ring buffer ;
;____________________________________________________________________________________
;;{
READ_BUFFER_PWM
			MOVF	PWM_COUNT,W			; 
			BNZ		$ + .4				;  if (count > max)
		BRA		READ_PWM_ERROR			; {
			CLRF	FSR0H				; 
			MOVFF	PWM_OUT_POINT, FSR0L	; FSR = output_pointer;
			MOVFF 	INDF0, _CHAR		; character = *FSR;
			INCF	PWM_OUT_POINT			; output_pointer++;
			DECF	PWM_COUNT				; count--;
			MOVLW	PWM_RINGBUFF+.23		; 
			CPFSGT	PWM_OUT_POINT			; if (output_pointer > end_of_buffer)
			BRA		FINISH_READ_PWM		; 	{
				MOVLW	PWM_RINGBUFF		; 	output_pointer = start_of_buffer;
				MOVWF	PWM_OUT_POINT		; 	}
FINISH_READ_PWM							; }
			MOVF	_CHAR, W
	RETURN
READ_PWM_ERROR
	RETLW FAILURE		; *TODO* Should do something else here
;------------------------------------------------------------------------------------
READ_BUFFER_R
			MOVF	R_COUNT,W			; 
			BNZ		$ + .4				;  if (count > max)
		BRA		READ_R_ERROR			; {
			CLRF	FSR0H				; 
			MOVFF	R_OUT_POINT, FSR0L	; FSR = output_pointer;
			MOVFF 	INDF0, _CHAR		; character = *FSR;
			INCF	R_OUT_POINT			; output_pointer++;
			DECF	R_COUNT				; count--;
			MOVLW	R_RINGBUFF+.15		; 
			CPFSGT	R_OUT_POINT			; if (output_pointer > end_of_buffer)
			BRA		FINISH_READ_R		; 	{
				MOVLW	R_RINGBUFF		; 	output_pointer = start_of_buffer;
				MOVWF	R_OUT_POINT		; 	}
FINISH_READ_R							; }
			MOVF	_CHAR, W
	RETURN
READ_R_ERROR
	RETLW FAILURE		; *TODO* Should do something else here
;------------------------------------------------------------------------------------
READ_BUFFER_G
			MOVF	G_COUNT,W			; 
			BNZ		$ + .4				;  if (count > max)
		BRA		READ_G_ERROR			; {
			CLRF	FSR0H				; 
			MOVFF	G_OUT_POINT, FSR0L	; FSR = output_pointer;
			MOVFF 	INDF0, _CHAR		; character = *FSR;
			INCF	G_OUT_POINT			; output_pointer++;
			DECF	G_COUNT				; count--;
			MOVLW	G_RINGBUFF+.15		; 
			CPFSGT	G_OUT_POINT			; if (output_pointer > end_of_buffer)
			BRA		FINISH_READ_G		; 	{
				MOVLW	G_RINGBUFF		; 	output_pointer = start_of_buffer;
				MOVWF	G_OUT_POINT		; 	}
FINISH_READ_G							; }
			MOVF	_CHAR, W
	RETURN
READ_G_ERROR
	RETLW FAILURE		; *TODO* Should do something else here
;------------------------------------------------------------------------------------
READ_BUFFER_B
			MOVF	B_COUNT,W			; 
			BNZ		$ + .4				;  if (count > max)
		BRA		READ_B_ERROR		; {
			CLRF	FSR0H				; 
			MOVFF	B_OUT_POINT, FSR0L	; FSR = output_pointer;
			MOVFF 	INDF0, _CHAR		; character = *FSR;
			INCF	B_OUT_POINT			; output_pointer++;
			DECF	B_COUNT				; count--;
			MOVLW	B_RINGBUFF+.15		; 
			CPFSGT	B_OUT_POINT			; if (output_pointer > end_of_buffer)
			BRA		FINISH_READ_B		; 	{
				MOVLW	B_RINGBUFF		; 	output_pointer = start_of_buffer;
				MOVWF	B_OUT_POINT		; 	}
FINISH_READ_B							; }
			MOVF	_CHAR, W
	RETURN
READ_B_ERROR
	RETLW FAILURE		; *TODO* Should do something else here
;;}
;____________________________________________________________________________________

;----------------------;
; Read from the EEPROM ;
;____________________________________________________________________________________
;;{
; This subroutine reads a segment of data from the EEPROM to RAM. The parameters are.
;
; EE_ADDRESS = The 8-bit address of EEPROM to read.
; EE_LENGTH  = The length of data to be read.
; <RAM TARGET> WREG = The address in ram to move the string too.
;
; It's called as follows.
;-------------------------------------
; MOVLW	<EE address you want to read>
; MOVWF EE_ADDRESS
;
; MOVLW	<length of string, in Hex>
; MOVWF	EE_LENGTH
;
; MOVLW	<name of a variable, or buffer address>
;
; CALL EE_READ
;-------------------------------------
; You of course must have the two variables declared in your main ASM file
;____________________________________________________________________________________							
EE_READ
			MOVWF	FSR0L			; Load the indirect address pointer with the
			CLRF	FSR0H			; address of the first byte of our RAM buffer 

			BCF 	EECON1, EEPGD	; Target is EEPROM, not program memory
			BCF 	EECON1, CFGS	; Target is NOT Configuration memory
;BRA $ - .14 destination		
			MOVF 	EE_ADDRESS, W	; Load the EEPROM engine with 
			MOVWF 	EEADR			; the address for our EE data

			BSF 	EECON1, RD		; Begin the EEPROM read operation

			MOVFF EEDATA, POSTINC0	; Move EE data to RAM via pointer. pointer++

			INCF	EE_ADDRESS		; Increase the EE address by one.
			DECFSZ	EE_LENGTH, F	; Decrement the counter.
			BRA		$ - .14			; If not overflow, loop again.
	RETURN
;;}
;____________________________________________________________________________________

;-------------------------------;
; psudo-random number generator ;
;____________________________________________________________________________________
;;{
GEN_RANDOM
			RCALL	_48BIT_LFSR
			RCALL	_48BIT_LFSR
			RCALL	_48BIT_LFSR
			RCALL	_48BIT_LFSR
			RCALL	_48BIT_LFSR
			RCALL	_48BIT_LFSR
			RCALL	_48BIT_LFSR
			RCALL	_48BIT_LFSR	

			MOVLW	.16				;
			CPFSGT	RAND			;
			MOVWF	RAND			; Keep random number in a +16-
			MOVLW	.255-.16		; range to prevent overshoot
			CPFSLT	RAND			;
			MOVWF	RAND			;
	RETURN
;;}
;____________________________________________________________________________________

;-----------------------------------------;
;  LFSR "Linear feedback shift register"  ;
;____________________________________________________________________________________
;;{
; Note: An even number of bytes is the most memory efficient length for an LFSR.  
; However, as a general rule, even length LFSRs take more operations to implement 
; maximal period, so are slower to execute. The best compromise for this is an even 
; number of bytes -1 bit (though -3 bits is also good). This general rule does not 
; apply to 1 or 2 byte LFSRs, which are special cases. The larger the LFSR the less 
; important this detail becomes as the shifts will dominate the time taken.
;____________________________________________________________________________________
_48BIT_LFSR
			BCF		STATUS, C	; Clear unknown bit out of carry

			RRCF	LFSR_01, F	;
			RRCF	LFSR_02, F	;
			RRCF	LFSR_03, F	; Rotate (shift) registers through the carry.
			RRCF	LFSR_04, F	;
			RRCF	LFSR_05, F	;
			RRCF	RAND, F		;

			BNC		$ +	.10		; Test the output bit. (lsb)
								; If it is 0, do nothing and just move on.
								; If it is 1, then we XOR in our bit mask.

			MOVLW  	b'10001001' ; Bits 48, 44, 41
			XORWF  	LFSR_01, F	; 
			MOVLW  	b'01000000'	; Bits 39
			XORWF  	LFSR_02, F	; 
	RETURN
;;}
;____________________________________________________________________________________

;------------------------;
;  LUT (Look Up Tables)  ;
;____________________________________________________________________________________
;;{
; 4x4 cubic Hermite spline coefficients (bugged)
; 			*TODO* First one was bugged.
; 16x4 .(2^16) cubic Hermite spline coefficients
_16x4_table		
				ORG 0x0800
				DATA	.0,		.0,		.0,		.0
				DATA	.1800,	.64920,	.2536,	.120
				DATA	.3136,	.63168,	.5952,	.448
				DATA	.4056,	.60424,	.10104,	.936
				DATA	.4608,	.56832,	.14848,	.1536
				DATA	.4840,	.52536,	.20040,	.2200
				DATA	.4800,	.47680,	.25536,	.2880
				DATA	.4536,	.42408,	.31192,	.3528
				DATA	.4096,	.36864,	.36864,	.4096
				DATA	.3528,	.31192,	.42408,	.4536
				DATA	.2880,	.25536,	.47680,	.4800
				DATA	.2200,	.20040,	.52536,	.4840
				DATA	.1536,	.14848,	.56832,	.4608
				DATA	.936,	.10104,	.60424,	.4056
				DATA	.448,	.5952,	.63168,	.3136
				DATA	.0120,	.2536,	.64920,	.1800
; 8x4 .(2^16) cubic Hermite spline coefficients
_8x4_16bit_table
				;ORG 0x0800
				DATA	.0,		.0,		.0,		.0
				DATA	.3136,	.63168,	.5952,	.448
				DATA	.4608,	.56832,	.14848,	.1536
				DATA	.4800,	.47680,	.25536,	.2880
				DATA	.4096,	.36864,	.36864,	.4096
				DATA	.2880,	.25536,	.47680,	.4800
				DATA	.1536,	.14848,	.56832,	.4608
				DATA	.448,	.5952,	.63168,	.3136
; 8x4 .(2^8) cubic Hermite spline coefficients (Rounded)
_8x4_8bit_table
				;ORG 0x0800
				DB		.0,		.0,		.0,		.0
				DB		.12,	.247,	.23,	.2
				DB		.18,	.222,	.58,	.6
				DB		.19,	.186,	.100,	.11
				DB		.16,	.144,	.144,	.16
				DB		.11,	.100,	.186,	.19
				DB		.6,		.58,	.222,	.18
				DB		.2,		.23,	.247,	.12
_table_end		;ORG 0x0800
;;}
;____________________________________________________________________________________

    END