'====================================================
'OPEN SOURCE FOREVER / PUBLIC DOMAIN
'====================================================
'*****************************************************************
' Module: PSIM-1 REAV1a / REV1b
' Processor Type: Basic Micro - Basic Atom Pro24M
' Description:  Programmable Sequencer with Forward and Reverse Outputs
' Developed by Brice D. Hornback - SynthModules.com
' Special Thanks to dr.mabuse for the Modern Implement Company
' Special Thanks to Grant Richter for his assistance.
' Revision Date:  2004/01/31 5:02 AM 
' Status: DRAFT ONLY
'*****************************************************************
'
'INTRODUCTION
' 
'SEQUENCED-SAH.BAS is a programmable dual output analog Sample & Hold Sequencer.  
'IN-3 is a control port - if it's LOW then a sequence plays on OUT-1 and OUT-2.  If it's HIGH, then
'the program enters "Program Mode" and stepped entries are input via IN-1 with the START button
'snapshotting each step.  (Note: the number of steps is user definable.)
'After the last step is entered, control jumps back to main to starts playing the sequence automatically.
'
'To start recording, put a HIGH (5V) signal on IN-3.  You might have to wait a 3 to 5 seconds for 
'it to respond to the command.
'
'After recording starts (RED and GREEN LED's alternate), place CV Input 3 back low immediately.
'Press the START button to record each step.
'Once recording all the steps has completed, it automatically begins playing the sequence. Pressing the 
'STOP button will PAUSE the sequencer.
'During sequence playback, the AUX port (output) acts as a Gate/Trigger (0V/5V).
'Playback continues until IN-3 goes HIGH again and the PSIM-1 enters sequence program mode.
'
'The sequence plays forward on OUT-1 and backwards on Out-2 forever ... or until CV 3 goes high again
'to load a new sequence.
'
'-------------------------------------------------
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
' P7 -  I2C/SDL (Reserved) - J3 Pin 2
' P8 -  AUX (Digital I/O - NO INPUT BUFFERING) - USE AT YOUR OWN RISK
' P9 -  STOP LED
' P10 - RUN LED
' P11 - DAC - LOADDACS
' P12 - DAC - SERDATA
' P13 - DAC - CLOCK
' P14 - RXD (Reserved) - J5 Pin 1 (MIDI IN)
' P15 - TXD (Reserved) - J5 Pin 2 (MIDI OUT)
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
I			VAR	WORD 	' Misc Counting Variable
TEMPO		VAR	WORD	' TEMPO=1 Is Equal to 0.5ms ??? (Value 0 to 254)
BPM			VAR	BYTE	' Beats Per Minute (Value 0 to 254)
TONE		VAR WORD	' Frequency in Hertz
FREQ		VAR WORD	' Temporary Frequency Counter
GATEON		VAR WORD    ' GATE ON Time
GATEOFF		VAR WORD    ' GATE OFF Time
NOTE		VAR	WORD	' Note to Play
WORK 		VAR BYTE	' Workspace for BUTTON instruction.
RSEED       VAR WORD
RDEX        VAR WORD
DUR         VAR WORD
VAL         VAR WORD(256)' This defines the number of maximum cells in the array.
VAL1        VAR WORD
VAL2        VAR WORD
J           VAR WORD
JJ          VAR WORD
UDFLAG      VAR BIT
DIAL1       VAR WORD
STEPS		VAR	BYTE ; 0 TO 255 steps
	
	

'*****************************************************
'Initialize Module

DIRS = %1111110000000000 ' Configure Pins    1=input  0=output
OUTS = %1111111111111111 ' Configure State   1=low    0=high
 
STEPS=255		' Change this value to equal steps (0 to 31)
				' This sets the PSIM-1 to a 256-step S&H Sequencer.
				' Remember, values START at ZERO!
 
TONE=440		' Change this to frequency in Hz. to output from the AUX jack.
				' This can be used as a tuning frequency to beat your VCO's against.

BPM=240			' Change this to how ever many Beats Per Minute you want.
TEMPO=60000/BPM ' DO NOT CHANGE (Note: BPM is approximate. Your timing may vary.)
 
'*****************************************************

RUN:

FOR J = 0 TO STEPS
    VAL(J)=0' initialize sequence steps
NEXT    
LOW RUNLED
LOW STOPLED

DIAL1 = 0

MAINLOOP:
   
   GOSUB SCANADC
   
   IF ADC3V >= 500 THEN' if IN-3 is high then load the array
      GOSUB LOADSEQ
     ENDIF 
   
    IF ADC3V < 500 THEN' if IN-3 is low then Play the sequence
       	HIGH RUNLED      
		FOR J = 0 TO STEPS
        IF IN5 = 1 THEN JUSTWAIT ' Pressing Stop button pauses the sequence.
		JJ = STEPS - J
	    DAC1V = VAL(J)	' forwards
	    DAC2V = VAL(JJ)	' backwards
	    TOGGLE AUX  	' Outputs 5V on AUX port to use as a Gate/Trigger
	    GOSUB LOADALLDACS
	    PAUSE TEMPO
	  NEXT
	ENDIF
	LOW RUNLED
GOTO MAINLOOP   

'************************** SUBROUTINES ****************************
'Note: Not all subroutines are used in this program.
'*******************************************************************

INIT:' by Brice D. Hornback - http://www.SynthModules.com
	 ' Resets DAC values, flashes LEDs, then waits for START button.  
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
	'Use the AUX jack at your own risk.  There is no buffering. 
	LOW STOPLED
	HIGH RUNLED
	LOOP0:
		IF IN5 = 1 THEN ENDLOOP0
		FREQOUT AUX,1000,TONE ' This is the command to output the frequency (TONE) for 1 second.
		GOTO LOOP0 ' Continue playing tone until STOP button is pressed.
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

LOADALLDACS:' by Grant Richter of Wiard Synthesizer Company as of 17 Jan 2004
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
	
LOADSEQ:' by Doc & Brice Hornback 30 Jan 2004
    FOR I=1 TO 12 ' Both Red and Green LED's will alternate indicating RECORD MODE.
		TOGGLE RUNLED
		PAUSE 50
		TOGGLE STOPLED
		PAUSE 50
		NEXT
    LOW RUNLED	' green! off while recording
    'AC4V=0' unproven indicator light code
    FOR J = 0 TO STEPS
	   'DAC4V = 4095-((7-STEPS)*(4095/J))' unproven indicator light code
		LOADLOOP:'a forever loop inside the for-next loop
		   	GOSUB SCANADC'  get CVs 
	        DAC1V = ADC1V * 4'>>>
	    	GOSUB LOADALLDACS'>>> pass thru CV so user can hear what the CV1 is doing
	    		IF IN4 = 1 THEN RECORD' wait for START button press or HIGH on Start Jack.
		   		GOTO LOADLOOP
		   	
		   	RECORD: ' When START button is pressed, whatever CV value is on IN-1 will 
		   			' be recorded and the sequencer will move on to the next step.
		   		HIGH STOPLED
	    		VAL(J) = ADC1V * 4' load the current CV at IN-1
	    		PAUSE 300 	' REQUIRED to debounce the START button 
	    		LOW STOPLED
	           	NEXT  
	RETURN ' When all steps have been recorded, playback will begin automatically.
	
JUSTWAIT:	' by Brice D. Hornback - http://www.SynthModules.com
			' Pauses the sequence. Pressing the START button resumes.
	IF IN4 = 1 THEN MAINLOOP
	GOTO JUSTWAIT

ENDPROGRAM:	' by Brice D. Hornback - http://www.SynthModules.com
			' Resets all four DAC channels to 0V and runs INIT subroutine 
	LOW RUNLED
	HIGH STOPLED
	GOSUB RESETDAC
	GOTO INIT
	