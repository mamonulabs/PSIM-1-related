'====================================================
'OPEN SOURCE FOREVER / PUBLIC DOMAIN
'====================================================
'
' Arabesque.bas
'
'*****************************************************************
' Module: PSIM-1 REV1.0c
' Processor Type: Basic Micro - Basic Atom Pro24M
' Compiler Version: 7.2.0.4
'
' Description:	Arabesque melody generator synced to clock on CV1.
'             	Press the Start Button to begin. 
'
' Developed by Mike Marsh, though mostly ripped-off Brice code
' Revision Date:  2004/05/05  2:18 PM
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
BSTART		CON 4		' Start Button 
BSTOP		CON 5		' Stop  Button
AUX			CON 8
ADC1		CON 0
ADC2		CON	1
ADC3		CON 2
ADC4		CON 3
OFFSET		CON	1152
MINFREQ		CON 0		' DAC - Sets to 0 VDC
MAXFREQ		CON 4095	' Maximum value for 12-bit DAC is 4096 (or 0 TO 4095)
OCTAVE		CON 12		' number of semitones in an octave
MAXCNT		CON	128 		' Misc Counting 

' all variables are type LONG because they process faster

RAWDAC1  	VAR LONG	' RAW DAC DATA 1 
RAWDAC2  	VAR LONG	' RAW DAC DATA 2 
RAWDAC3  	VAR LONG	' RAW DAC DATA 3 
RAWDAC4  	VAR LONG	' RAW DAC DATA 4 
DAC1V		VAR LONG	' DAC Value to be Sent to DAC Channel
DAC2V		VAR LONG	' DAC Value to be Sent to DAC Channel
DAC3V		VAR LONG	' DAC Value to be Sent to DAC Channel
DAC4V		VAR LONG	' DAC Value to be Sent to DAC Channel
ADC1V		VAR LONG	' Value of Analog IN-1
ADC2V		VAR LONG	' Value of Analog IN-2
ADC3V		VAR LONG	' Value of Analog IN-3
ADC4V		VAR LONG	' Value of Analog IN-4
I			VAR	LONG 	' Misc Counting Variable
J			VAR	LONG 	' Misc Counting Variable
TEMPO		VAR	LONG	' TEMPO=1 Is Equal to 0.5ms ??? (Value 0 to 254)
BPM			VAR	LONG	' Beats Per Minute (Value 0 to 254)
TONE		VAR LONG	' Frequency in Hertz
FREQ		VAR LONG	' Temporary Frequency Counter
GATEON		VAR LONG    ' GATE ON Time
GATEOFF		VAR LONG    ' GATE OFF Time
NOTE		VAR	LONG	' Note to Play
WORK 		VAR LONG	' Workspace for BUTTON instruction.
MIDI		VAR	LONG	' MIDI Numbers 0-127
RSEED		VAR LONG	' Holds most curentest random number
VAL1		VAR LONG	'VALue at OUT-1
VAL2		VAR LONG	'VALue at OUT-2
VAL3		VAR LONG	'VALue at OUT-3
VAL4		VAR LONG	'VALue at OUT-4

' Tables of Scales
CMajor LongTable 60, 62, 64, 65, 67, 69, 71, 72
CMinor LongTable 60, 62, 63, 65, 67, 68, 70, 72

'************************************************************************
' Begin executable code
'************************************************************************

DIRS = %1111110000000000	' Configure Pins    1=input  0=output
OUTS = %1111111111111111	' Configure State   1=low    0=high

TONE  = 440
BPM   = 140
TEMPO = 60000 / BPM
RSEED = 417

I = 1
J = 1

VAL1 = 0
VAL2 = 0
VAL3 = 0
VAL4 = 0

GOSUB INIT

'************************************************************************
' Generates and plays a random note between MIDI Note number 48 and 72 on
' each clock pulse from CV1.
'************************************************************************

RUN:

	' blinky light stuff
	HIGH RUNLED
	LOW STOPLED

NEXTNOTE:
	
	' press Mr. Stop Button to quit
	IF IN5 = 1 THEN ENDPROGRAM
	
	' calculate the next note (returns new note in NOTE)
	GOSUB CALCNOTE    
  
  	' shift the outputs ('borrowed from the good Dr. Mabuses' code)
	VAL4 = VAL3						
	VAL3 = VAL2
	VAL2 = VAL1
	VAL1 = NOTE

	' output the shifted notes
	DAC1V = VAL1					
	DAC2V = VAL2
	DAC3V = VAL3
	DAC4V = VAL4

' wait for front of gate pulse    
WAITFORHIGH:

	' get the scanned VALue					
	GOSUB SCANADC1
	
	' keep looping while IN-1 is LOW
	IF ADC1V < 3 THEN WAITFORHIGH
	
	' send out CV
	GOSUB LOADALLDACS		

	' send Gate ON
	TOGGLE AUX
	
' wait for gate input to drop
WAITFORLOW:

	' get scanned VALue
	GOSUB SCANADC1
	
	' keep looping while IN-1 is HIGH
	IF ADC1V > 3 THEN WAITFORLOW
	
	' send Gate OFF		
	TOGGLE AUX
	
GOTO NEXTNOTE

'************************************************************************
' NEW SUBROUTINES
'************************************************************************

'************************************************************************
' CALCNOTE
'
' Calculates the next note to play.  
'
' The note will be chosen from a CMajor scale by a formula:
'
' (I * J) MODULO 7
'
' I and J are iterated over MAXCNT, I within J
'
' AUTHOR: Mike Marsh
' DATE: 05-05-2004
'************************************************************************
CALCNOTE:

	' get the next note 'seed'
	RSEED = I * J
	
	' Use modulo to scale number
	MIDI = CMajor(RSEED // 7) - (2 * OCTAVE)
	
	' OFFSET sets Middle C at 2V.
	NOTE = (MIDI * 32) - OFFSET     

	' update counters	
	J = J + 1
	IF J > MAXCNT THEN
		J = 1
		I = I + 1
		IF I > MAXCNT THEN
			I = 1
		ENDIF
	ENDIF
	
	RETURN

'************************************************************************
' LOADDAC1 - Load DAC1 and pulse it to play the note
'            Use when you don't need to output to all DACs
'
' AUTHOR: Mike Marsh
' DATE: 05-05-2004 (¡Viva México!)
'
' Shamelessly ripped off from Grant Richter of Wiard Synthesizer Company 
'************************************************************************
LOADDAC1: 

	'Add addresses to VALues no speed improve with OR over +
	RAWDAC1 = DAC1V + 49152

	'shift out 16 bits mode 4 gotta bang loaddacs pin for each channel
	'skew from ch. 1 to 4 = 400 usecs. Aprox 1 msec execution time for sub.
	SHIFTOUT SERDATA, CLOCK, 4, [RAWDAC1 \ 16]
	PULSOUT LOADDACS, 1 

	RETURN
 
'************************************************************************
' SACANADC1 - Scan ADC1 for its input
'             Use when you don't need to get input from all ADCs
'
' AUTHOR: Mike Marsh
' DATE: 05-05-2004 (¡Viva México!)
'
' Shamelessly ripped off from Grant Richter of Wiard Synthesizer Company
'************************************************************************
SCANADC1:

	'load buffers with actual a/d VALues
	ADIN ADC1, ADC1V

	RETURN
	
'************************************************************************
' RESETDAC1 - Reset DAC1
'             Use when you don't need to reset all DACs
'
' AUTHOR: Mike Marsh
' DATE: 05-05-2004 (¡Viva México!)
'
' Shamelessly ripped off from Brice Hornback
'************************************************************************
RESETDAC1:

	' sets DAC1 channel to 0V and refresh it
	DAC1V=0
	GOSUB LOADDAC1
	
	RETURN
	
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
	'Add addresses to VALues no speed improve with OR over +
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
	'load buffers with actual a/d VALues
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

	