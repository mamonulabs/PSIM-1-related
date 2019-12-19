'OPEN SOURCE FOREVER
'====================================================
' PSIM-1 (Programmable Synthesizer Interface Module)
'
' Module: PSIM-1 REV1.0B
' Processor Type: Basic Micro - Basic Atom Pro24M
'
'
' Woody Wall 1 Mar 2004
' woody_wall@hotmail.com
'
' Many thanks to Gary Chang for his suggestions on how to
' make this program much more musically useful. Thanks also
' to Grant Richter for explaining the relationship between
' MIDI note values and voltage inputs and outputs. This is
' a complete rewrite of sah-sr-qua.bas
'
'
' DESCRIPTION:
'  sample & hold / shift register / quantizer
'  A pulse on START samples the voltage at IN-1, quantizes it to semi-tones,
'  and stores it in a 16-stage delay line. Four taps are available from the
'  delay line. The taps can be set to any value between 1 and 16.
'  See tap1-tap4 below.
'  The AUX line is pulsed synchronously with the input clock, but needs to
'  be buffered before it will drive some modules.
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
	
'**********************************************************************
'               THESE ARE THE TAPS INTO THE DELAY LINE
'**********************************************************************
' Set these to the clock pulse on which you want each output to appear.

	tap1		con 1
	tap2		con 3
	tap3		con 5
	tap4		con 6

'**********************************************************************

'**********************************************************************
' Program variables
	
	bvar		var byte		'working register for the BUTTON command
	value		var word(16)	'Sampled values to be shifted out
	ptr			var nib(4)		'Pointers to value array for each output
	midinote	var word		'Work variable for sampled analog input
	i			var word
			
'**********************************************************************
'Initialize Module

 DIRS = %1111110000000000 ' Configure Pins    1=input  0=output
 OUTS = %1111111111111111 ' Configure State   1=low    0=high
'*****************************************************

'*****************************************************
' Initialize program values

for i = 0 to 15			; All samples are initially zero.
	value(i) = 0
next

ptr(0) = 16 - tap1
ptr(1) = 16 - tap2
ptr(2) = 16 - tap3
ptr(3) = 16 - tap4

low stopled


'*****************************************************
' MAIN

waithigh:						;Wait for a clock pulse at START input.
	low runled
	low aux
	button bstart,1,0,0,bvar,1,shift
	goto waithigh


shift: 
	high runled
	low stopled
	high aux
	
	for i = 0 to 3				;Increment the shift register pointers
		ptr(i) = ptr(i) + 1
	next

	gosub scanadc				;Get input voltage
	midinote = adc1v / 8		;Quantize input voltage to get "MIDI note number"
	dac1v = midinote * 32		;Scale MIDI note number to DAC output range
	dac2v = value(ptr(1)) * 32
	dac3v = value(ptr(2)) * 32
	dac4v = value(ptr(3)) * 32
	value(ptr(0)) = midinote	;Save it for later
	gosub loadalldacs

waitlow:
	button bstart,1,0,0,bvar,0,waithigh
	goto waitlow

end
	
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
