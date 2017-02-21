;*******************************************************************************
;                                                                              *
;    Microchip licenses this software to you solely for use with Microchip     *
;    products. The software is owned by Microchip and/or its licensors, and is *
;    protected under applicable copyright laws.  All rights reserved.          *
;                                                                              *
;    This software and any accompanying information is for suggestion only.    *
;    It shall not be deemed to modify Microchip?s standard warranty for its    *
;    products.  It is your responsibility to ensure that this software meets   *
;    your requirements.                                                        *
;                                                                              *
;    SOFTWARE IS PROVIDED "AS IS".  MICROCHIP AND ITS LICENSORS EXPRESSLY      *
;    DISCLAIM ANY WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING  *
;    BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS    *
;    FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL          *
;    MICROCHIP OR ITS LICENSORS BE LIABLE FOR ANY INCIDENTAL, SPECIAL,         *
;    INDIRECT OR CONSEQUENTIAL DAMAGES, LOST PROFITS OR LOST DATA, HARM TO     *
;    YOUR EQUIPMENT, COST OF PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR    *
;    SERVICES, ANY CLAIMS BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY   *
;    DEFENSE THEREOF), ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER      *
;    SIMILAR COSTS.                                                            *
;                                                                              *
;    To the fullest extend allowed by law, Microchip and its licensors         *
;    liability shall not exceed the amount of fee, if any, that you have paid  *
;    directly to Microchip to use this software.                               *
;                                                                              *
;    MICROCHIP PROVIDES THIS SOFTWARE CONDITIONALLY UPON YOUR ACCEPTANCE OF    *
;    THESE TERMS.                                                              *
;                                                                              *
;*******************************************************************************
;                                                                              *
;    Filename:                                                                 *
;    Date:                                                                     *
;    File Version:                                                             *
;    Author:                                                                   *
;    Company:                                                                  *
;    Description:                                                              *
;                                                                              *
;*******************************************************************************
;                                                                              *
;    Notes: In the MPLAB X Help, refer to the MPASM Assembler documentation    *
;    for information on assembly instructions.                                 *
;                                                                              *
;*******************************************************************************
;                                                                              *
;    Known Issues: This template is designed for relocatable code.  As such,   *
;    build errors such as "Directive only allowed when generating an object    *
;    file" will result when the 'Build in Absolute Mode' checkbox is selected  *
;    in the project properties.  Designing code in absolute mode is            *
;    antiquated - use relocatable mode.                                        *
;                                                                              *
;*******************************************************************************
;                                                                              *
;    Revision History:                                                         *
;                                                                              *
;*******************************************************************************



;*******************************************************************************
; Processor Inclusion
;
; TODO Step #1 Open the task list under Window > Tasks.  Include your
; device .inc file - e.g. #include <device_name>.inc.  Available
; include files are in C:\Program Files\Microchip\MPLABX\mpasmx
; assuming the default installation path for MPLAB X.  You may manually find
; the appropriate include file for your device here and include it, or
; simply copy the include generated by the configuration bits
; generator (see Step #2).
;
;*******************************************************************************

;#INCLUDE <P18F27K40.INC>
#INCLUDE <P18F13K50.INC>

;*******************************************************************************
;
; TODO Step #2 - Configuration Word Setup
;
; The 'CONFIG' directive is used to embed the configuration word within the
; .asm file. MPLAB X requires users to embed their configuration words
; into source code.  See the device datasheet for additional information
; on configuration word settings.  Device configuration bits descriptions
; are in C:\Program Files\Microchip\MPLABX\mpasmx\P<device_name>.inc
; (may change depending on your MPLAB X installation directory).
;
; MPLAB X has a feature which generates configuration bits source code.  Go to
; Window > PIC Memory Views > Configuration Bits.  Configure each field as
; needed and select 'Generate Source Code to Output'.  The resulting code which
; appears in the 'Output Window' > 'Config Bits Source' tab may be copied
; below.
;
;*******************************************************************************
	
    CONFIG CPUDIV   = NOCLKDIV	; CPU runs at full 48Mhz clock speed
    CONFIG USBDIV   = OFF	; USB runs at full 48Mhz clock speed
    CONFIG FOSC	    = IRC	; High Speed Xtal in use, so high drive needed
    CONFIG PLLEN    = ON	; 4x PLL is on. (12Mhz x 4 = 48Mhz)
    CONFIG PCLKEN   = ON	; Primary clock is on, (not software control)
    CONFIG FCMEN    = OFF	; Fail safe clock monitor is OFF
    CONFIG IESO	    = OFF	; Switching the clock is DISABLED
    CONFIG PWRTEN   = OFF	; Powerup timer ON, CPU waits until power is stable
    CONFIG BOREN    = OFF	; Brown out reset DISABLED
    CONFIG BORV	    = 30	; 3.0v; Highest Brown out voltage possible
    CONFIG WDTEN    = OFF	; Watch dog timer DISABLED
    CONFIG WDTPS    = 1		; WDT post scaler, 1:1 (don't matter)
    CONFIG MCLRE    = OFF	; Master clear/reset is internal. RA3 is GPIO
    CONFIG HFOFST   = OFF	; System is held in reset untill clock is stable
    CONFIG STVREN   = OFF	; Hardware stack over/under flow disabled
    CONFIG LVP	    = OFF	; Low voltage programming is OFF
    CONFIG BBSIZ    = OFF	; Boot block size is 512 words. (don't matter)
    CONFIG XINST    = OFF	; Extended C language instruction set is OFF

    CONFIG DEBUG    = OFF	; Internal debugging hardware dissabled.

    CONFIG CP0	    = OFF		;
    CONFIG CP1	    = OFF		;
    CONFIG CPB	    = OFF		;
    CONFIG CPD	    = OFF		;
    CONFIG WRT0	    = OFF		;
    CONFIG WRTB	    = OFF		;  ALL FORMS OF CODE PROTECTION ARE OFF
    CONFIG WRTC	    = OFF		;
    CONFIG WRTD	    = OFF		;
    CONFIG EBTR0    = OFF		;
    CONFIG EBTR1    = OFF		;
    CONFIG EBTRB    = OFF		;

;*******************************************************************************
; Variable Definitions
;*******************************************************************************
;   GPR_VAR        UDATA
;   INT_VAR        UDATA_ACS

    CBLOCK 0x008 ; GPR variable register allocations
; ISR shadow for important registers 
    W_TEMP 		;
    STATUS_TEMP	;
    BSR_TEMP	;

    FLAGS		; Flags, for Yes/No things

; 8 bit PWM timers/Counters
    R1_time
    G1_time
    B1_time

    R2_time
    G2_time
    B2_time

    R3_time
    G3_time
    B3_time

    R4_time
    G4_time
    B4_time

    DUMMY_TIME		; DUMMY_TIME is always 255, and sets the pace

    PWM_PINS 	:.2	; This is the pin mask, used to change all pins at once.

; LFSR registars for PRNG
    LFSR_01
    LFSR_02
    LFSR_03
    LFSR_04
    LFSR_05
    RAND	; Final 8 bit Random number

; EEPROM engine arguments
    ;WREG		; Ram target address
    ;(bit)EERDWT; *TODO* Read/Write operation
    EE_ADDRESS 	; EEPROM target address
    EE_LENGTH	; Length of EEPROM data

; 24 bit Intermediate Hermite Products
    C0xP0	:.3
    C1xP1	:.3
    C2xP2	:.3
    C3xP3	:.3

; Temp storage for 16 bit Hermite coefficients, table look up
    c0 :.2
    c1 :.2
    c2 :.2
    c3 :.2

; Spline starting points. Filled with Random data, see "Fill_Buffer" sub
    p0
    p1
    p2
    p3

    R_p0
    R_p1
    R_p2
    R_p3

    G_p0
    G_p1
    G_p2
    G_p3

    B_p0
    B_p1
    B_p2
    B_p3

; Ring buffer variables
    _CHAR
    _COEF_POINT
    _COUNT
    _OUT_POINT
    _RINGBUFF_P

    PWM_COUNT			; Number of B ring buffer bytes used 
    PWM_IN_POINT		; Pointing to input address of ring buffer, the "head"
    PWM_OUT_POINT		; Pointing to output address of ring buffer, the "tail"
    PWM_RINGBUFF :.24	; Actual ring buffer, 24 bytes long.

    R_COEF_POINT
    R_COUNT			; Number of R ring buffer bytes used
    R_IN_POINT		; Pointing to input address of ring buffer, the "head"
    R_OUT_POINT		; Pointing to output address of ring buffer, the "tail"
    R_RINGBUFF :.16	; Actual ring buffer, 16 bytes long.

    G_COEF_POINT
    G_COUNT			; Number of G ring buffer bytes used
    G_IN_POINT		; Pointing to input address of ring buffer, the "head"
    G_OUT_POINT		; Pointing to output address of ring buffer, the "tail"
    G_RINGBUFF :.16	; Actual ring buffer, 16 bytes long.

    B_COEF_POINT
    B_COUNT			; Number of B ring buffer bytes used 
    B_IN_POINT		; Pointing to input address of ring buffer, the "head"
    B_OUT_POINT		; Pointing to output address of ring buffer, the "tail"
    B_RINGBUFF :.16	; Actual ring buffer, 16 bytes long.
	ENDC

;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
; TODO Step #4 - Interrupt Service Routines
;
; There are a few different ways to structure interrupt routines in the 8
; bit device families.  On PIC18's the high priority and low priority
; interrupts are located at 0x0008 and 0x0018, respectively.  On PIC16's and
; lower the interrupt is at 0x0004.  Between device families there is subtle
; variation in the both the hardware supporting the ISR (for restoring
; interrupt context) as well as the software used to restore the context
; (without corrupting the STATUS bits).
;
; General formats are shown below in relocatible format.
;
;------------------------------PIC16's and below--------------------------------
;
; ISR       CODE    0x0004           ; interrupt vector location
;
;     <Search the device datasheet for 'context' and copy interrupt
;     context saving code here.  Older devices need context saving code,
;     but newer devices like the 16F#### don't need context saving code.>
;
;     RETFIE
;
;----------------------------------PIC18's--------------------------------------
;
; ISRHV     CODE    0x0008
;     GOTO    HIGH_ISR
; ISRLV     CODE    0x0018
;     GOTO    LOW_ISR
;
; ISRH      CODE                     ; let linker place high ISR routine
; HIGH_ISR
;     <Insert High Priority ISR Here - no SW context saving>
;     RETFIE  FAST
;
; ISRL      CODE                     ; let linker place low ISR routine
; LOW_ISR
;       <Search the device datasheet for 'context' and copy interrupt
;       context saving code here>
;     RETFIE
;
;*******************************************************************************

; TODO INSERT ISR HERE

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program

START

    ; TODO Step #5 - Insert Your Program Here

    MOVLW 0x55                      ; your instructions
    GOTO $                          ; loop forever

    END