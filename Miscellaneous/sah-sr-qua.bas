'OPEN SOURCE FOREVER
'====================================================
' PSIM-1 (Programmable Synthesizer Interface Module)
'
' Module: PSIM-1 REV1.0B
' Processor Type: Basic Micro - Basic Atom Pro24M
'
'
' Woody Wall 27 Feb 2004
'
' Heavily modified version of cvqua1.bas
' Basic Program Developed by Grant Richter
' modified by dr manbuse 26 Jan 2004
' Special thanks to Brice for his assistance.
'
' Description:
'  sample & hold / shift register / quantizer
'  A pulse on START samples the voltage at IN-1 and shifts the 
'  outputs from OUT-1 through OUT-4, one step per pulse. Voltage 
'  at IN-2 controls the quantization.
' 
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
	
	bvar		var byte	'working register for the BUTTON command
	val1		var word	'value at OUT-1
	val2		var word	'value at OUT-2
	val3		var word	'value at OUT-3
	val4		var word	'value at OUT-4
	divisor		var word	'quantization
		
    '*****************************************************
	'Initialize Module

 DIRS = %1111110000000000 ' Configure Pins    1=input  0=output
 OUTS = %1111111111111111 ' Configure State   1=low    0=high
	'*****************************************************

val1 = 0
val2 = 0
val3 = 0
val4 = 0
low stopled

LOOP1:	;Wait for a clock pulse at START input.
	LOW RUNLED
	BUTTON BSTART,1,0,0,BVAR,1,LOOPA
	GOTO LOOP1

loopa: 
	high runled
	low stopled
	
	gosub scanadc
	DIVISOR = (ADC2V + 1 ) / 64		;Get the quantization.
	if DIVISOR < 1 then				;Prevent division by zero.
		DIVISOR = 1
	endif
	val4 = val3						;Shift the outputs.
	val3 = val2
	val2 = val1
	val1 = (ADC1V / DIVISOR) * 32	;Quantize the new sample.

	DAC1V = val1					;Output the new values.
	DAC2V = val2
	DAC3V = val3
	DAC4V = val4
	gosub loadalldacs

goto loop1

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