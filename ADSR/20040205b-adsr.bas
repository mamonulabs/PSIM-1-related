'====================================================
'OPEN SOURCE FOREVER / PUBLIC DOMAIN
'====================================================
'*****************************************************************
' Module: PSIM-1
' Processor Type: Basic Micro - Basic Atom Pro24M
' Description:  QUAD CV Controlled ADSR
' Developed by Brice D. Hornback - SynthModules.com
' Based on code by dr.mabuse of the Modern Implement Company.
' Special Thanks to Grant Richter for his assistance.
' Revision Date:  2004/02/05  
' Status: DRAFT ONLY
'*****************************************************************
'
' INTRODUCTION
' 
' A CV Programmable QUAD ADSR with the same envelope output on all four outputs.
' Time Base is a variable that can range from 0 to 255 (see below).
' Note... this does NOT do as good a job at being an ADSR as the Blacet EG1! But, 
' it does work and has four outputs.  
'
' Start Button (or short pulse on Start CV) = GATE
' 	Note: holding down the start button will cause SUSTAIN until gate is released.
' CV in 1 = attack time
' CV in 2 = decay time
' CV in 3 = sustain level
' CV in 4 = release time
'
' Yes, you need FOUR CV's to make this function.  I tested using a pair of joystick
' controllers.  Remember, the analog inputs are internally limited 5V MAX.  
'
'--------------------------------------------------
'
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
	
LOADDACS	CON 11		' Pin OUT to DAC LOADDACS
SERDATA		CON 12      ' Pin OUT Serial Data to DAC (16-bit)
CLOCK		CON 13      ' Pin OUT to Clock DAC
STOPLED		CON 9		' Red LED
RUNLED		CON	10		' Green LED
BSTART		CON 5		' Start Button
BSTOP		CON 4		' Stop  Button
AUX			CON 8
ADC1		CON 0
ADC2		CON	1
ADC3		CON 2
ADC4		CON 3
MINFREQ		CON 0		' DAC - Sets to 0 VDC
MAXFREQ		CON 4095	' Maximum value for 12-bit DAC is 4096 (or 0 TO 4095)
						' Note: 4095 is 10.666 VDC for 1V/Octave.

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

ATTACKR		VAR WORD 	' Temp Attack Step Value
DECAYR		VAR WORD 	' Temp Decay Step Value
RELEASER	VAR WORD 	' Temp Release Step Value
TIMEBASE	VAR	BYTE 	' Sets Ramp Speed (0 to 255)
					 	
'*****************************************************
'Initialize Module

DIRS = %1111110000000000 ' Configure Pins    1=input  0=output
OUTS = %1111111111111111 ' Configure State   1=low    0=high
 
TIMEBASE=2 	' Typical value 0 to 10 but can be as high as 255!
			' The higher the number, the slower the timebase.
 
'*****************************************************

RUN: ' START HERE

	LOW STOPLED
	LOW RUNLED
	GOSUB RESETDAC

MAINLOOP:
	LOW RUNLED
	IF IN4 = 1 THEN ADSR ' is there a gate on the START button?
	' a pulse on the Start CV-IN also works the same as pressing the button.
	GOTO MAINLOOP
	
	ADSR:
		GOSUB RESETDAC
		GOSUB SCANADC'  get CVs
		ATTACKR=ADC1V/100 ' the 100 value can also be changed but this works well.
		IF ATTACKR <= 0 THEN 
 			ATTACKR=1
 			ENDIF
		DECAYR=ADC2V/100 ' the 100 value can also be changed but this works well.
		IF DECAYR <= 0 THEN 
 			DECAYR=1
 			ENDIF
 		RELEASER=ADC4V/100 ' the 100 value can also be changed but this works well.
		IF RELEASER <= 0 THEN 
 			RELEASER=1
 			ENDIF
 	HIGH RUNLED
	   	
	ATTACK:' climb up to 10V at the rate set by CV IN-1
		FOR DAC1V = 1 TO MAXFREQ STEP ATTACKR
		DAC2V=DAC1V
		DAC3V=DAC1V
		DAC4V=DAC1V
		GOSUB LOADALLDACS
       	PAUSE TIMEBASE
       	NEXT 'if you're at 10V then start falling down
       
	DECAY:' fall down at the rate set by CV IN-2
 		FOR DAC1V = MAXFREQ TO ADC3V*4 STEP -DECAYR
		DAC2V=DAC1V
		DAC3V=DAC1V
		DAC4V=DAC1V
		GOSUB LOADALLDACS
       	IF DAC1V <= ADC3V*4 THEN SUSTAIN' if you reach the level of CV IN-3 then stay there
       	PAUSE TIMEBASE
       	NEXT
 
	SUSTAIN:' if no gate, then release
       	IF IN4 = 0 THEN RELEASE
		DAC1V = ADC3V*4
		DAC2V=DAC1V
		DAC3V=DAC1V
		DAC4V=DAC1V
		GOSUB LOADALLDACS
       	GOTO SUSTAIN' keep staying
       
	RELEASE:' fall down at the rate set by CV IN-4
 		FOR DAC1V = ADC3V*4 TO 0 STEP -RELEASER
		DAC2V=DAC1V
		DAC3V=DAC1V
		DAC4V=DAC1V
		GOSUB LOADALLDACS
       	IF DAC1V <= 0 THEN MAINLOOP' if you've fallen all the way back to zero - start over
       	PAUSE TIMEBASE
       	NEXT

GOTO RUN
       	
'************************** SUBROUTINES ****************************
	
RESETDAC:'Sets all DAC channels to 0V and refreshes all four DAC channels.
	DAC1V=0
	DAC2V=0	
	DAC3V=0
	DAC4V=0
	GOSUB LOADALLDACS
	RETURN

LOADALLDACS:'Add addresses to values no speed improve with OR over +
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
 	
SCANADC:'load buffers with actual a/d values
	ADIN ADC1, ADC1V
	ADIN ADC2, ADC2V
	ADIN ADC3, ADC3V
	ADIN ADC4, ADC4V
	RETURN

