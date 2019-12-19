'OPEN SOURCE FOREVER
'====================================================
' PSIM-1 (Programmable Synthesizer Interface Module)
'
' Module: PSIM-1 REV1.0B
' Processor Type: Basic Micro - Basic Atom Pro24M
'
'
'Woody Wall 21 Feb 2004
'
'
'Ramps:
' Generate a descending ramp when a pulse is received at the
' START input. Rates are determined by the value present at the
' channel input. If no input is present on a channel then the
' rate is determined by the channel 1 input multiplied by the
' channel number. STOP LED lights when all ramps reach zero.
' 
'input: any CV between 0 & 5 V 
'----------------------------------------------------

' Basic Micro Atom Pro-24M Configuration
'
' (Note: P0 is I/O 0 and NOT pin 0 on the microprocessor.)
'
' P0 -  Analog IN-1 (0-5 VDC)
' P1 -  Analog IN-2 (0-5 VDC)
' P2 -  Analog IN-3 (0-5 VDC)
' P3 -  Analog IN-4 (0-5 VDC)
' P4 -  START Button (Momentary Normally Open Switch)
' P5 -  STOP  Button (Momentary Normally Open Switch)
' P6 -  I2C/SDA (Reserved) - J3 Pin 1
' P7 -  I2C/SDL (Reserved) -  J3 Pin 2
' P8 -  AUX (Digital I/O - NO BUFFERING)
' P9 -  STOP LED
' P10 - RUN LED
' P11 - DAC - LOADDACS
' P12 - DAC - SERDATA
' P13 - DAC - CLOCK
' P14 - RXD (Reserved) - J5 Pin 1 (Midi)
' P15 - TXD (Reserved) - J5 Pin 2 (Midi)
'-------------------------------------------------------
	'Define Variables
	
	LOADDACS	CON 11  ' Pin OUT to DAC LOADDACS
	SERDATA		CON 12  ' Pin OUT Serial Data to DAC (16-bit)
	CLOCK		CON 13  ' Pin OUT to Clock DAC
	STOPLED		CON 9   ' Red LED
	RUNLED		CON 10  ' Green LED
	BSTART		CON 4   ' Start Button
	BSTOP		CON 5   ' Stop  Button
	AUX			CON 8	' AUX Jack (unbuffered)

	RAWDAC1  	VAR WORD  ' RAW DAC DATA 1 
	RAWDAC2  	VAR WORD  ' RAW DAC DATA 2 
	RAWDAC3  	VAR WORD  ' RAW DAC DATA 3 
	RAWDAC4  	VAR WORD  ' RAW DAC DATA 4 

	DAC1V  		VAR WORD  ' DAC Value to be Sent to DAC Channel
	DAC2V  		VAR WORD  ' DAC Value to be Sent to DAC Channel
	DAC3V  		VAR WORD  ' DAC Value to be Sent to DAC Channel
	DAC4V  		VAR WORD  ' DAC Value to be Sent to DAC Channel
	
	ADC1		CON 0
	ADC2		CON	1
	ADC3		CON 2
	ADC4		CON 3

	ADC1V		VAR WORD	'INPUT A/D BUFFER CH. 1
	ADC2V		VAR WORD	'INPUT A/D BUFFER CH. 2
	ADC3V		VAR WORD	'INPUT A/D BUFFER CH. 3
	ADC4V		VAR WORD	'INPUT A/D BUFFER CH. 4
	

	BVAR		VAR BYTE
	RSTART		CON 4095
	RAMP1		VAR WORD
	RAMP2		VAR WORD
	RAMP3		VAR WORD
	RAMP4		VAR WORD
	INC1		VAR WORD
	INC2		VAR WORD
	INC3		VAR WORD
	INC4		VAR WORD
	
    '*****************************************************
	'Initialize Module

 DIRS = %1111110000000000 ' Configure Pins    1=input  0=output
 OUTS = %1111111111111111 ' Configure State   1=low    0=high
	'*****************************************************

DAC1V = 0
DAC2V = 0
DAC3V = 0
DAC4V = 0
GOSUB LOADALLDACS

LOOP1:	;Quiescent state
	LOW RUNLED
	HIGH STOPLED
	BUTTON BSTART,1,0,0,BVAR,1,LOOPA
	GOTO LOOP1

LOOPA:  ;Initialize ramp values
	RAMP1 = RSTART
	RAMP2 = RSTART
	RAMP3 = RSTART
	RAMP4 = RSTART
	GOSUB SCANADC
	INC1 = ADC1V / 8
	IF INC1 = 0 THEN
		INC1 = 1
	ENDIF
	
	INC2 = ADC2V / 8
	IF ADC2V = 0 THEN
		INC2 = INC1 * 2
	ENDIF
	
	INC3 = ADC3V / 8
	IF INC3 = 0 THEN
		INC3 = INC1 * 3
	ENDIF
	
	INC4 = ADC4V / 8
	IF INC4 = 0 THEN
		INC4 = INC1 * 4
	ENDIF
	
LOOP2:  ;Run the ramps
	HIGH RUNLED
	LOW STOPLED
	DAC1V = RAMP1
	DAC2V = RAMP2
	DAC3V = RAMP3
	DAC4V = RAMP4
	GOSUB LOADALLDACS
	RAMP1 = RAMP1 - INC1
	IF RAMP1 < INC1 THEN
		RAMP1 = INC1
	ENDIF
	RAMP2 = RAMP2 - INC2
	IF RAMP2 < INC2 THEN
		RAMP2 = INC2
	ENDIF
	RAMP3 = RAMP3 - INC3
	IF RAMP3 < INC3 THEN
		RAMP3 = INC3
	ENDIF
	RAMP4 = RAMP4 - INC4
	IF RAMP4 < INC4 THEN
		RAMP4 = INC4
	ENDIF
	IF (RAMP1 > INC1) OR (RAMP2 > INC2) OR (RAMP3 > INC3) OR (RAMP4 > INC4) THEN
		GOTO LOOP2
	ENDIF

	DAC1V = 0
	DAC2V = 0
	DAC3V = 0
	DAC4V = 0
	GOSUB LOADALLDACS
	GOTO LOOP1

END
	
'*******************************************************************
'************************** SUBROUTINES ****************************
' by Grant Richter of Wiard Synthesizer Company as of 17 Jan 2004
'                 ALL FOUR channels are touched 
'*******************************************************************

LOADALLDACS:
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
 	
SCANADC:
	'load buffers with actual a/d values
	ADIN ADC1, ADC1V
	ADIN ADC2, ADC2V
	ADIN ADC3, ADC3V
	ADIN ADC4, ADC4V
	RETURN