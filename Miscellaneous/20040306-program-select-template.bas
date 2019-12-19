'---------------------------------------------
'PUBLIC DOMAIN 
'---------------------------------------------
'
'*****************************************************************
' Module: PSIM-1
' Processor Type: Basic Micro - BasicATOMPRO
' Description:  Test Program to select one of FOUR programs
' Developed by Brice D. Hornback - bdh@cyberbound.net
' Web site: http://www.SynthModules.com
' Special Thanks to Grant Richter and Dr. Mabuse for their assistance.
' Revision Date:  2004/03/06  
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
' P6 -  (Reserved) - J3 Pin 1
' P7 -  (Reserved) - J3 Pin 2
' P8 -  AUX
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
I			VAR	WORD 	' Misc Counting Variable
BV			VAR	BYTE	' Bytevariable used by Button to store current loop counts
TEMPO		VAR	WORD	' TEMPO=1 Is Equal to 0.5ms ??? (Value 0 to 254)
BPM			VAR	BYTE	' Beats Per Minute (Value 0 to 254)
TONE		VAR WORD	' Frequency in Hertz
FREQ		VAR WORD	' Temporary Frequency Counter
GATEON		VAR WORD    ' GATE ON Time
GATEOFF		VAR WORD    ' GATE OFF Time
NOTE		VAR	WORD	' Note to Play
SELECTN		VAR BYTE	' Selection

'************************************************************************
'Initialize Module

DIRS = %1111110000000000	' Configure Pins    1=input  0=output
OUTS = %1111111111111111	' Configure State   1=low    0=high

GOSUB RESETDAC 

'************************************************************************

RUN:
	SELECTN=0
	FOR I = 1 TO 10 ' Wiggle both lights back and forth to indicate program start
		HIGH RUNLED
		LOW STOPLED
		PAUSE 100
		LOW RUNLED 
		HIGH STOPLED
		PAUSE 100
	NEXT
	LOW STOPLED
	LOW RUNLED

CHECKB:
	FOR I=1 TO SELECTN
		HIGH RUNLED
		PAUSE 100
		LOW RUNLED
		PAUSE 100
	NEXT
	PAUSE 500
	BUTTON 5,1,0,0,BV,1,TAP; Creates ONE increment out of each STOP button press irregardless of length
	BUTTON 4,1,0,0,BV,1,SELECTPROG; If START button is pressed, run selected program
	GOTO CHECKB

TAP:
	SELECTN = SELECTN + 1
	GOTO CHECKB

SELECTPROG:
	IF SELECTN=1 THEN PROGRAM1
	IF SELECTN=2 THEN PROGRAM2
	IF SELECTN=3 THEN PROGRAM3
	IF SELECTN=4 THEN PROGRAM4
	HIGH RUNLED ' PUSHED BUTTON TOO MANY TIMES - START OVER
	HIGH STOPLED
	PAUSE 5000
	GOTO RUN

'************************************************************************
' Copy and paste your favorite programs below.  These are just samples
' to demonstrate how it works.  Variable can be defined at the beginning
' of your program below to save on memory space as they won't tie up
' resources unless that program is running.  Hit the RESET button to 
' start over.
'************************************************************************

PROGRAM1:			'Flashes RUN LED Fast
	BUTTON 5,1,0,0,BV,1,RUN; If STOP button is pressed... start over
	TOGGLE RUNLED
	PAUSE 100
	GOTO PROGRAM1

PROGRAM2:			'Flashes STOP LED Fast
	BUTTON 5,1,0,0,BV,1,RUN; If STOP button is pressed... start over
	TOGGLE STOPLED
	PAUSE 100
	GOTO PROGRAM2
	
PROGRAM3:			'Flashes RUN LED Slow
	BUTTON 5,1,0,0,BV,1,RUN; If STOP button is pressed... start over
	TOGGLE RUNLED
	PAUSE 1000
	GOTO PROGRAM3

PROGRAM4:			'Flashes STOP LED Slow
	BUTTON 5,1,0,0,BV,1,RUN; If STOP button is pressed... start over
	TOGGLE STOPLED
	PAUSE 1000
	GOTO PROGRAM4
		
'************************************************************************
' SUBROUTINES - DO NOT MODIFY!
'************************************************************************

INIT:' Resets DAC values, flashes LEDs, then waits for Start button.  
	LOW RUNLED
	LOW STOPLED
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
	
PLAYFREQ:'Plays a tone (Variable FREQ) on the AUX jack until Stop button is pressed.
	LOW STOPLED
	HIGH RUNLED
	LOOP0:
		IF IN5 = 1 THEN ENDLOOP0
		FREQOUT AUX,1000,TONE ' This is the command to output the frequency (TONE) for 1000 ms.
		GOTO LOOP0
	ENDLOOP0:
		LOW RUNLED 
		HIGH STOPLED
		RETURN
	
RESETDAC:'Sets all DAC channels to 0V and refreshes all four DAC channels.
	DAC1V=0
	DAC2V=0	
	DAC3V=0
	DAC4V=0
	GOSUB LOADALLDACS
	RETURN

LOADALLDACS: 'Add addresses to values no speed improve with OR over +
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
  
SCANADC: 'load buffers with actual a/d values
	ADIN ADC1, ADC1V
	ADIN ADC2, ADC2V
	ADIN ADC3, ADC3V
	ADIN ADC4, ADC4V
	RETURN

ENDPROGRAM:	' Resets all four DAC channels to 0V and runs INIT subroutine 
	LOW RUNLED
	HIGH STOPLED
	GOSUB RESETDAC
	GOTO INIT
	