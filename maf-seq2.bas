'
'*****************************************************************
' Module: PSIM-1 REV1b
' Processor Type: Basic Micro - Basic Atom Pro24M
' Description: random walk through tone row
'   Syncs to gate on IN-1
'   Generates a gate on AUX so you don't have to mult the original
'
' Input and Output patching:
'  * OUT-1 = voltage notes output (to VCO 1v/oct input)
'  * OUT-2 = forth up from OUT-1
'  * OUT-3 = fifth up from OUT-1
'  * OUT-4 = octive up from OUT-1
'  * AUX = gate output (to envelope gate input)
'  * IN-1 = gate input for stepping through tone row
'
' Don't forget to press START button on PSIM-1
'
' Developed by Michael A. Firman
' Revision Date:  4/7/2004
'*****************************************************************

' Basic Micro Atom Pro-24M Configuration
'
'	(Note: P0 is I/O 0 and NOT pin 0 on the microprocessor.)
'
' P0 -  Analog IN-1 (0-5 VDC)
' P1 -  Analog IN-2 (0-5 VDC)
' P2 -  Analog IN-3 (0-5 VDC)
' P3 -  Analog IN-4 (0-5 VDC)
' P4 -  START Button (Momentary Normally Open Switch)
' P5 -  STOP  Button (Momentary Normally Open Switch)
' P6 -  I2C/SDA (Reserved) - J3 Pin 1
' P7 -  I2C/SDL (Reserved) - J3 Pin 2
' P8 -  AUX (Digital I/O - NO BUFFERING)
' P9 -  STOP LED
' P10 - RUN LED
' P11 - DAC - LOADDACS
' P12 - DAC - SERDATA
' P13 - DAC - CLOCK
' P14 - RXD (Reserved) - J5 Pin 1
' P15 - TXD (Reserved) - J5 Pin 2

'************************************************************************
'Define Variables

LOADDACS	CON 11		' Pin OUT to DAC LOADDACS
SERDATA		CON 12      	' Pin OUT Serial Data to DAC (16-bit)
CLOCK		CON 13      	' Pin OUT to Clock DAC
STOPLED		CON 9		' Red LED
RUNLED		CON 10		' Green LED
BSTART		CON 5		' Start Button
BSTOP		CON 4		' Stop  Button
AUX		CON 8
ADC1		CON 0
ADC2		CON 1
ADC3		CON 2
ADC4		CON 3
MINFREQ		CON 0		' DAC - Sets to 0 VDC
MAXFREQ		CON 4095	' Maximum value for 12-bit DAC is 4096 (or 0 TO 4095)
OFFSET		CON 1152
MAXRAND		CON 65535
SEQLEN		CON 8

SEQ		VAR WORD(SEQLEN)' Stores currently playing voltage/note values
SEQWORK		VAR WORD
I		VAR WORD 	' Index for the tone row array
RTEMP		VAR WORD
VAL1		VAR LONG
VAL2		VAR LONG
VAL3		VAR LONG

RAWDAC1  	VAR WORD	' RAW DAC DATA 1 
RAWDAC2  	VAR WORD	' RAW DAC DATA 2 
RAWDAC3  	VAR WORD	' RAW DAC DATA 3 
RAWDAC4  	VAR WORD	' RAW DAC DATA 4 
DAC1V		VAR WORD	' DAC Value to be Sent to DAC Channel
DAC2V		VAR WORD	' DAC Value to be Sent to DAC Channel
DAC3V		VAR WORD	' DAC Value to be Sent to DAC Channel
DAC4V		VAR WORD	' DAC Value to be Sent to DAC Channel
ADC1V		VAR WORD	' Value of Analog IN-1
ADC2V		VAR WORD	' Value of Analog IN-2
ADC3V		VAR WORD	' Value of Analog IN-3
ADC4V		VAR WORD	' Value of Analog IN-4

'************************************************************************
'Initialize Module

DIRS = %1111110000000000	' Configure Pins    1=input  0=output
OUTS = %1111111111111111	' Configure State   1=low    0=high

GOSUB INIT

'************************************************************************

RUN:
	RTEMP=425				' Some random starting seed
	VAL2 = FLOAT (SEQLEN - 1)
	VAL3 = FLOAT (MAXRAND)

	SEQ(0) = 65				' Load Tone Row 
	SEQ(1) = 66
	SEQ(2) = 68
	SEQ(3) = 69
	SEQ(4) = 71
	SEQ(5) = 72
	SEQ(6) = 74
	SEQ(7) = 75

ONESTEP:
	RTEMP = RANDOM RTEMP
	VAL1 = FLOAT RTEMP
	I = INT (VAL2 fmul (VAL1 fdiv VAL3))
	SEQWORK = SEQ(I)
	DAC1V= (SEQWORK * 32) - OFFSET		' Get note CV into DAC1
	DAC2V= ((SEQWORK + 5) * 32) - OFFSET	' A Forth up into DAC2
	DAC3V= ((SEQWORK + 7) * 32) - OFFSET	' A Fifth up into DAC3
	DAC4V= ((SEQWORK + 12) * 32) - OFFSET	' An Octive into DAC4

WAITFORHIGH:					' Wait for front of gate pulse
	GOSUB SCANADC
	IF ADC1V < 3 THEN WAITFORHIGH		' Keep looping while IN-1 is LOW
	TOGGLE AUX				' Send Gate ON
	GOSUB LOADALLDACS			' Send out CV

WAITFORLOW:					' Wait for gate input to drop
	GOSUB SCANADC
	IF ADC1V > 3 THEN WAITFORLOW		' Keep looping while IN-1 is HIGH
	TOGGLE AUX				' Send Gate OFF

	GOTO ONESTEP				' Advance to next step of sequence

'************************************************************************
' SUBROUTINES
'************************************************************************

INIT:' by Brice D. Hornback - http://www.SynthModules.com
	 ' Resets DAC values, flashes LEDs, then waits for Start button.  
	LOW RUNLED
	GOSUB RESETDAC

	FOR I=1 TO 12
		TOGGLE RUNLED
		PAUSE 50
		TOGGLE STOPLED
		PAUSE 50
		NEXT
	LOOP1:
		TOGGLE STOPLED
		PAUSE 100
		IF IN4 = 1 THEN RUN
		IF IN5 = 1 THEN ENDLOOP1
		GOTO LOOP1
	ENDLOOP1:
	RETURN
	
RESETDAC:' by Brice D. Hornback - http://www.SynthModules.com
	'Sets all DAC channels to 0V and refreshes all four DAC channels.
	DAC1V=0
	DAC2V=0	
	DAC3V=0
	DAC4V=0
	GOSUB LOADALLDACS
	RETURN

LOADALLDACS: ' by Grant Richter of Wiard Synthesizer Company as of 17 Jan 2004
	'Add addresses to values no speed improve with OR over +
	RAWDAC1=DAC1V+49152
	RAWDAC2=DAC2V+32768
	RAWDAC3=DAC3V+16384
	RAWDAC4=DAC4V
	'shift out 16 bits mode 4 gotta bang loaddacs pin for each channel
	'skew from ch. 1 to 4 = 400 usecs. Aprox 1 msec execution time for sub.
	SHIFTOUT SERDATA,CLOCK,4,[RAWDAC1\16]
	PULSOUT LOADDACS,1 
	SHIFTOUT SERDATA,CLOCK,4,[RAWDAC2\16]
	PULSOUT LOADDACS,1 
	SHIFTOUT SERDATA,CLOCK,4,[RAWDAC3\16]
	PULSOUT LOADDACS,1
	SHIFTOUT SERDATA,CLOCK,4,[RAWDAC4\16]
	PULSOUT LOADDACS,1
	RETURN

SCANADC:' by Grant Richter of Wiard Synthesizer Company as of 17 Jan 2004
	'load buffers with actual a/d values
	ADIN ADC1, ADC1V
	ADIN ADC2, ADC2V
	ADIN ADC3, ADC3V
	ADIN ADC4, ADC4V
	RETURN

ENDPROGRAM:	' by Brice D. Hornback - http://www.SynthModules.com
		' Resets all four DAC channels to 0V and runs INIT subroutine 
	LOW RUNLED
	HIGH STOPLED
	GOSUB RESETDAC
	GOTO INIT

