'====================================================
'OPEN SOURCE FOREVER / PUBLIC DOMAIN
'====================================================
'*****************************************************************
' Module: PSIM-1
' Processor Type: Basic Micro - Basic Atom Pro24M
' Description:  Sweeps all four DAC outputs from 0 to 4095 and repeats.
' Developed by Brice D. Hornback - http://www.SynthModules.com
' Special Thanks to Grant Richter of the Wiard Synthesizer Company
' Special Thanks to dr.mabuse of the Modern Implement Company
' Revision Date:  2004/02/01 7:35 AM 
' Status: ACTIVE
'*****************************************************************

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

'*****************************************************
'Define Variables

LOADDACS	CON 11  ' Pin OUT to DAC LOADDACS
SERDATA		CON 12  ' Pin OUT Serial Data to DAC (16-bit)
CLOCK		CON 13  ' Pin OUT to Clock DAC
STOPLED		CON 9   ' Red LED
RUNLED		CON 10  ' Green LED
BSTART		CON 5   ' Start Button
BSTOP		CON 4   ' Stop  Button
AUX			CON 8	' AUX Jack (unbuffered)

DAC1  CON %1100  ' DAC Channel 1 (First two bits set channel, second two are unused.)
DAC2  CON %1000  ' DAC Channel 2 (First two bits set channel, second two are unused.)
DAC3  CON %0100  ' DAC Channel 3 (First two bits set channel, second two are unused.)
DAC4  CON %0000  ' DAC Channel 4 (First two bits set channel, second two are unused.)

DAC1V  VAR WORD  ' DAC Value to be Sent to DAC Channel
DAC2V  VAR WORD  ' DAC Value to be Sent to DAC Channel
DAC3V  VAR WORD  ' DAC Value to be Sent to DAC Channel
DAC4V  VAR WORD  ' DAC Value to be Sent to DAC Channel

MINFREQ	CON 0   ' DAC - Sets to 0 VDC
MAXFREQ	CON 4095  ' Maximum value for 12-bit DAC is 4096 (or 0 TO 4095)
FREQ  	VAR WORD  ' TEST DAC Value
TONE	VAR WORD  ' Frequency in Hertz
WORK	VAR BYTE  ' Workspace for BUTTON instruction.
I		VAR WORD   ' Misc Counting Variable
TEMPO	VAR BYTE  ' TEMPO=1 Is Equal to 1ms (Value 0 to 254ms)

'*****************************************************
'Initialize Module

 DIRS = %1111110000000000 ' Configure Pins    1=input  0=output
 OUTS = %1111111111111111 ' Configure State   1=low    0=high
'*****************************************************

WORK=0
FREQ=1000
TEMPO=250 'milliseconds
TONE=440 ' MIDI Note 69 (A)

FREQOUT AUX,5000,TONE ' sends tone to the AUX jack for 5 seconds
 
GOSUB INIT

START:
	TOGGLE STOPLED
	PAUSE TEMPO
	IF IN4 = 1 THEN RUN
 	IF IN5 = 1 THEN ENDPROGRAM
 	GOTO START
 
'*****************************************************



RUN:
	LOW STOPLED
	HIGH RUNLED

 	FOR FREQ=MINFREQ TO MAXFREQ STEP 1
 		DAC1V=FREQ
 		DAC2V=FREQ
 		DAC3V=FREQ
 		DAC4V=FREQ
 		GOSUB DAC
		IF IN5 = 1 THEN ENDPROGRAM
 		'PAUSE TEMPO
 	NEXT
 
 	FOR FREQ=MAXFREQ TO MINFREQ STEP -1
 		DAC1V=FREQ
 		DAC2V=FREQ
 		DAC3V=FREQ
 		DAC4V=FREQ
 		GOSUB DAC
		IF IN5 = 1 THEN ENDPROGRAM
 		'PAUSE TEMPO
 	NEXT
 
 	GOTO RUN
 
'*****************************************************
' SUBROUTINES - DO NOT MODIFY!
'*****************************************************
DAC:
	SHIFTOUT SERDATA,CLOCK,0,[DAC1\4,DAC1V\12]
 	PULSOUT LOADDACS,1 
 	SHIFTOUT SERDATA,CLOCK,0,[DAC2\4,DAC2V\12]
 	PULSOUT LOADDACS,1 
 	SHIFTOUT SERDATA,CLOCK,0,[DAC3\4,DAC3V\12]
 	PULSOUT LOADDACS,1
 	SHIFTOUT SERDATA,CLOCK,0,[DAC4\4,DAC4V\12]
 	PULSOUT LOADDACS,1
 	RETURN
 
RESETDAC:
	DAC1V=0
	DAC2V=0 
	DAC3V=0
	DAC4V=0
	GOSUB DAC
	RETURN
 
INIT:
	LOW RUNLED
	DAC1V=0
	DAC2V=0 
	DAC3V=0
	DAC4V=0
	GOSUB DAC
	FOR I=1 TO 12
	TOGGLE RUNLED
	PAUSE 50
	TOGGLE STOPLED
	PAUSE 50
 	NEXT
	RETURN
 
ENDPROGRAM:
	LOW RUNLED
	HIGH STOPLED
	DAC1V = 0 
	DAC2V = 0
	DAC3V = 0
	DAC4V = 0
	GOSUB DAC
 	GOTO START

END


