'PUBLIC DOMAIN ... OPEN SOURCE FOREVER
'=========== SYNCABLE example =========
'===========   4 March 2004  =========
'by dr. Mabuse & Grant Richter
'
'
'description:
'
' listens for 2 button presses on IN4 (start button)
'the limit of how long it can wait between presses is 65.534 seconds
' 
' outputs a variable PERIOD that represents the time in milliecs betwwen those button presses

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
	

	
	MSEX	VAR	WORD
    INK     VAR WORD
    TOGL    VAR NIB
    PERIOD  VAR WORD
    BJ      VAR WORD
    JAVG    VAR NIB
    AVG     VAR WORD
    PTOT    VAR WORD

	'*****************************************************
	'Initialize Module

	 DIRS = %0111110000000000 ' Configure Pins    1=output  0=input
	 OUTS = %0111111111111111 ' Configure State   1=high    0=low
	 
	 SCR3 = %00000000 'setup SCI3 for bytewise MIDI transmit
	 SMR = %00000000
	 BRR = 15
	 PAUSEUS 100
	 SCR3 = %00100000
	 PMR1 = %00001110
	 
	 'setup timer w for 1 millisecond interupts
	 
	 TMRW = %10001000 'note set CTS to 1 to run
	 TCRW = %10110000 'set CCLR to 1 for free run /8 internal clock
	 TIERW = %01110000
	 TSRW = %01110000
	 TIOR0 = %10001000
	 TIOR1 = %10001000
	 GRA = 2000 'clock is 16 MHz/8 = 2 MHz divide by 2000 for 1 millisecond
	 
	'*****************************************************

	LOW STOPLED
	LOW RUNLED
	MSEX = 0
	INK = 0
    TOGL = 0

'*******************************************************************
'*************** APPLICATION CODE START ****************************
'*******************************************************************

ONINTERRUPT TIMERWINT_IMIEA, CALCTIME; sacred millisecond timer interrupt...om mani padme hum... 
ENABLE TIMERWINT_IMIEA 


 TAPLOOP:
     BUTTON 4,1,0,0,BJ,1,BANG; Creates ONE bang out of each button press irregardless of length
 GOTO TAPLOOP

 BANG:
   TOGL = TOGL + 1
   IF TOGL = 1 THEN ; FIRST button press
      MSEX = 0; Zero the millisecs counter
      GOTO TAPLOOP
     ENDIF
   IF TOGL >= 2 THEN; SECOND button press
      PERIOD = MSEX; how many millisecs since MSEX was zeroed in the operation above
      TOGL=0
      GOTO GOTTAP; now we've got a period let's move on, and never come back
     ENDIF
 GOTO TAPLOOP; safety only, should never get here       

GOTTAP: 'infinite loop to flash the red LED to demo PERIOD
 HIGH STOPLED
 PAUSE PERIOD
 LOW STOPLED
 PAUSE PERIOD
GOTO GOTTAP
	
'*******************************************************************
'************************** SUBROUTINES ****************************
'*******************************************************************


DISABLE TIMERWINT_IMIEA 

CALCTIME:
	MSEX = MSEX + 1	
	INK = INK + 1
	IF INK = 1000 THEN
	    INK = 0
	    HIGH RUNLED
	    PAUSE 10
	    LOW RUNLED
	    PAUSE 10
	   ENDIF
	IF MSEX = 65534 THEN
    	MSEX = 0
	  ENDIF
RESUME	