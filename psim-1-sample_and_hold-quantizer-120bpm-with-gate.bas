'---------------------------------------------
'PUBLIC DOMAIN 
'---------------------------------------------
'
'*****************************************************************
' Module: PSIM-1 REV1b
' Processor Type: Basic Micro - Basic Atom Pro24M
' Description:  Chromatic Quantized Sample and Hold on all 4 DAC channels
' Developed by Brice D. Hornback - bdh@cyberbound.net
' Web site: http://www.SynthModules.com
' Special Thanks to Grant Richter for his assistance.
' Revision Date:  2004/01/26  3:47 AM
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
TEMPO		VAR	WORD	' TEMPO=1 Is Equal to 0.5ms ??? (Value 0 to 254)
BPM			VAR	BYTE	' Beats Per Minute (Value 0 to 254)
TONE		VAR WORD	' Frequency in Hertz
FREQ		VAR WORD	' Temporary Frequency Counter
GATEON		VAR WORD    ' GATE ON Time
GATEOFF		VAR WORD    ' GATE OFF Time
NOTE		VAR	WORD	' Note to Play
WORK 		VAR BYTE	' Workspace for BUTTON instruction.

'************************************************************************
'Initialize Module

DIRS = %1111110000000000	' Configure Pins    1=input  0=output
OUTS = %1111111111111111	' Configure State   1=low    0=high

WORK=0
TONE=440 ' Change this to frequency in Hz. to output from the AUX jack.
         ' This can be used as a tuning frequency to beat your VCO's 
         ' against.

BPM=120 ' Change this to how ever many Beats Per Minute you want.
TEMPO=60000/BPM ' Do not change

GOSUB INIT

'************************************************************************

RUN:
	IF IN5 = 1 THEN ENDPROGRAM ' Pressing Stop button resets program
	LOW STOPLED
	HIGH RUNLED
	GOSUB SCANADC
	DAC1V=(ADC1V/16)*32
	DAC2V=(ADC2V/16)*32
	DAC3V=(ADC3V/16)*32
	DAC4V=(ADC3V/16)*32
	TOGGLE AUX  ' Outputs 5V on AUX port to use as a Gate/Trigger
	GOSUB LOADALLDACS
	PAUSE TEMPO ' This pauses based on the BPM setting above.
	GOTO RUN
		
'************************************************************************
' SUBROUTINES - DO NOT MODIFY!
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
	
PLAYFREQ:' by Brice D. Hornback - http://www.SynthModules.com
	'Plays a tone (Variable FREQ) on the AUX jack until Stop button is pressed.
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
	