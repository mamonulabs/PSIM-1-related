'OPEN SOURCE FOREVER
'====================================================
' PSIM-1 (Programmable Synthesizer Interface Module)
'
' Module: PSIM-1 REV1A
' Processor Type: Basic Micro - Basic Atom Pro24M
'
'
'Basic Program originated by dr.mabuse 23 Jan 2004 
'for The Modern Implement Company 
'
'SLEW:
' description ( a dance about architecture)
' 
'template for a voltage controlled (@CVin1) linear slew rate
'the critical elements are:
'ST=start point
'ND=end point
'SR=linear slew rate
'POINT' is just an array of points for testing 
'any two numbers assigned  to ST & ND will do

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
	BSTART		CON 5   ' Start Button
	BSTOP		CON 4   ' Stop  Button
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
	
	
	UP1DN        VAR BIT 
	UP2DN        VAR BIT 
	UP3DN        VAR BIT 
	UP4DN        VAR BIT  
	
	POINT        VAR WORD(5)
	J            VAR NIB
'these vars are need for the slew routine	
    SR           VAR SWORD
    ST           VAR WORD
    ND           VAR WORD
    SLEW         VAR WORD
    '*****************************************************
	'Initialize Module

 DIRS = %1111110000000000 ' Configure Pins    1=input  0=output
 OUTS = %1111111111111111 ' Configure State   1=low    0=high
	'*****************************************************

LOW STOPLED
HIGH RUNLED

POINT(1)=0
POINT(2)=4095
POINT(3)=0
POINT(4)=1000
POINT(5)=353

DAC1V = 0

MAINLOOP:
	GOSUB SCANADC;  get CVs
	ADC1V = 1024 - ADC1V; invert knob so low = fast, high = slow
	SR=(ADC1V/10)+1; slew rate time - scale range to appx 1 to 11
	
	FOR J = 1 TO 5
      IF J < 5 THEN
      
	    SLEWROUTINE:
	    ST = POINT(J); starting point
	    ND = POINT(J+1); ending point
	    IF ST = ND THEN; can't slew if start & end points are the same
	       DAC1V = ST
	       GOSUB LOADALLDACS
	       GOTO SKIPIT; skip the slewing
	      ENDIF
	    IF ST > ND THEN; if you're falling...
	       SR = -SR; use a negative step
	      ENDIF;otherwise leave the step positive
	    FOR SLEW = ST TO ND STEP SR;loop from start to end stepping at the rate set by the knob
            DAC1V = SLEW
            GOSUB LOADALLDACS
           NEXT 	       
	      SKIPIT:
	      
       ENDIF
    NEXT
PAUSE 2000    
GOTO MAINLOOP

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