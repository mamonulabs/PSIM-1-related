'====================================================
'OPEN SOURCE FOREVER / PUBLIC DOMAIN
'====================================================
'*****************************************************************
' NOTE: See the RUN routine for the table lookup based sequencer.
'
'*****************************************************************
' Module: PSIM-1 REV1b
' Processor Type: Basic Micro - Basic Atom Pro24M
' Description:	Table Sequencer Using MIDI Note Numbers.
'             	Press the Start Button to begin. 
'			    MIDI Number to Note Table at bottom of this program.
'				Outputs same value on all 4 Outputs.
'				Note: Tune VCO to 440 Hz for best results.
' Developed by Brice D. Hornback - bdh@cyberbound.net
' Web site: http://www.SynthModules.com
' Special Thanks to Grant Richter for his assistance.
' Revision Date:  2004/01/24  1:04 AM
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
OFFSET		CON	1152
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
MIDI		VAR	BYTE	' MIDI Numbers 0-127


'************************************************************************
DIRS = %1111110000000000	' Configure Pins    1=input  0=output
OUTS = %1111111111111111	' Configure State   1=low    0=high

TONE=440
BPM=240
TEMPO=60000/BPM

GOSUB INIT

'************************************************************************
' Simply change the MIDI numbers in the LOOKUP table to get different notes.
'************************************************************************

RUN:
HIGH RUNLED
LOW STOPLED
FOR I = 0 TO 15 ' Number of steps in sequence - start at 0 (16 steps)
 IF IN5 = 1 THEN ENDPROGRAM
    LOOKUP I,[24,36,48.60,72,84,96,108,120,108,96,84,72,60,48],MIDI ' Use MIDI Note Values
              'DEMO: All Notes are C.
    NOTE=(MIDI*32)-OFFSET   ' NOTE: OFFSET sets Middle C at 2V.  
    DAC1V=NOTE  
    DAC2V=NOTE 
    DAC3V=NOTE 
    DAC4V=NOTE
    TOGGLE AUX  '5V Out used as a Gate/Trigger
    GOSUB LOADALLDACS
    PAUSE TEMPO
    LOW AUX
    NEXT
GOTO RUN


'************************************************************************
' SUBROUTINES - DO NOT MODIFY!
'************************************************************************

INIT:' by Brice D. Hornback - http://www.SynthModules.com
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
		FREQOUT AUX,1000,TONE ' sends tone to the AUX jack for 5 seconds
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

ENDPROGRAM:' by Brice D. Hornback - http://www.SynthModules.com
	LOW RUNLED
	HIGH STOPLED
	GOSUB RESETDAC
	GOTO INIT

'************************************************************************
'	MIDI 	NOTE
'************************************************************************
'	0		C
'	1		C#
'	2		D
'	3		D#
'	4		E
'	5		F
'	6		F#
'	7		G
'	8		G#
'	9		A
'	10		A#
'	11		B
'	12		C
'	13		C#
'	14		D
'	15		D#
'	16		E
'	17		F
'	18		F#
'	19		G
'	20		G#
'	21		A	(Low Piano A)
'	22		A#
'	23		B
'	24		C
'	25		C#
'	26		D
'	27		D#
'	28		E
'	29		F
'	30		F#
'	31		G
'	32		G#
'	33		A
'	34		A#
'	35		B
'	36		C
'	37		C#
'	38		D
'	39		D#
'	40		E
'	41		F
'	42		F#
'	43		G
'	44		G#
'	45		A
'	46		A#
'	47		B
'	48		C
'	49		C#
'	50		D
'	51		D#
'	52		E
'	53		F
'	54		F#
'	55		G
'	56		G#
'	57		A
'	58		A#
'	59		B
'	60		C	(Middle C)
'	61		C#
'	62		D
'	63		D#
'	64		E
'	65		F
'	66		F#
'	67		G
'	68		G#
'	69		A
'	70		A#
'	71		B
'	72		C
'	73		C#
'	74		D
'	75		D#
'	76		E
'	77		F
'	78		F#
'	79		G
'	80		G#
'	81		A
'	82		A#
'	83		B
'	84		C
'	85		C#
'	86		D
'	87		D#
'	88		E
'	89		F
'	90		F#
'	91		G
'	92		G#
'	93		A
'	94		A#
'	95		B
'	96		C
'	97		C#
'	98		D
'	99		D#
'	100		E
'	101		F
'	102		F#
'	103		G
'	104		G#
'	105		A
'	106		A#
'	107		B
'	108		C
'	109		C#
'	110		D
'	111		D#
'	112		E
'	113		F
'	114		F#
'	115		G
'	116		G#
'	117		A
'	118		A#
'	119		B
'	120		C
'	121		C#
'	122		D
'	123		D#
'	124		E
'	125		F
'	126		F#
'	127		G
	