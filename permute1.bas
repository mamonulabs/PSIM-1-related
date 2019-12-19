'OPEN SOURCE FOREVER/PUBLIC DOMAIN
'====================================================
' PSIM-1 (Programmable Synthesizer Interface Module)
'
' Module: PSIM-1 REV1A
' Processor Type: Basic Micro - Basic Atom Pro24M
'
'
'Basic Program originated by dr.mabuse 2 Feb 2004 
'for The Modern Implement Company
'
'description
'plays a major scale over & over
'CVin1 determines likelyhood that pitch order will vary
'CVin2 determines likelyhood that rhythm (durations) will vary
'CVout1 sequence going forward
'CVout2 sequence going backward (retrograde)
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
	
	BPM          VAR WORD
	RSEED        VAR WORD
	RCHANCE      VAR WORD
	PCHANCE      VAR WORD
	RDEX1        VAR WORD
	RDEX2        VAR WORD
	RFACT        VAR WORD
	RDEX         VAR WORD
	RVAL         VAR WORD(32)
	VAL          VAR WORD(32)
	RDIV         VAR NIB(5)
	VAL1         VAR WORD
	VAL2         VAR WORD
	J            VAR WORD
	JJ           VAR WORD
	TEMPO        VAR WORD
	COIN         VAR WORD

    '*****************************************************
	'Initialize Module

 DIRS = %1111110000000000 ' Configure Pins    1=input  0=output
 OUTS = %1111111111111111 ' Configure State   1=low    0=high
	'*****************************************************
BPM=360			' Base tempo.
TEMPO=60000/BPM ' DO NOT CHANGE (Note: BPM is approximate. Your timing may vary.)
RSEED = 17	

;2 4 & 8 are the possible multiplication or division factos for the rhythmic variations
RDIV(0) = 1;placeholder never used
RDIV(1) = 2
RDIV(2) = 4
RDIV(3) = 8
RDIV(4) = 1;placeholder never used

'initialize array to diatonic major scale (do re mi ...etc...)
VAL(0) = 0
VAL(1) = 64
VAL(2) = 128
VAL(3) = 160
VAL(4) = 224
VAL(5) = 288
VAL(6) = 352
VAL(7) = 384  
VAL(8) = 448
VAL(9) = 512
VAL(10) = 544
VAL(11) = 608
VAL(12) = 672
VAL(13) = 736
VAL(14) = 768
VAL(15) = 832  
LOW RUNLED
LOW STOPLED

MAINLOOP:
HIGH RUNLED 
GOSUB SCANADC     
FOR J = 0 TO 15
    JJ = 15 - J; backwards counter for retrograde
    DAC1V = VAL(J)
    DAC2V = VAL(JJ); retrograde output
    GOSUB LOADALLDACS
    TEMPO=60000/BPM ; re-establish tempo as function of BPM
'
'probablility knob - as CV in goes up chances increase that event will happen
'
  PCHANCE = (ADC2V/256)+1;quantize CVin2 to 1 thru 4
  PCHANCE = 5 - PCHANCE; invert CV in value
  IF PCHANCE = 4 THEN NORCHG; if CV is OFF then don't vary rhythm
  RSEED = RANDOM RSEED; cast the dice
  RSEED = RSEED + 1; preclude division by zero
  RCHANCE = RSEED/(65535/PCHANCE);scale random number to current range of CVin2
  RCHANCE = RCHANCE+1
  IF RCHANCE = PCHANCE THEN  
       RSEED = RANDOM RSEED; flip a coin to determine if the rhythm variation will be + or -
       COIN = RSEED/32768
         IF COIN > 0 THEN 
          TEMPO = TEMPO * RDIV(RCHANCE)
         ELSE 
          TEMPO = TEMPO / RDIV(RCHANCE)
       ENDIF
   ENDIF
   NORCHG:
   PAUSE TEMPO
NEXT
'
'probablility knob - as CV in goes up chances increase that event will happen
'
  PCHANCE = (ADC1V/128)+1;quantize Cv in 1 to 1 thru 8
  PCHANCE = 9 - PCHANCE; invert CV in value
  IF PCHANCE = 8 THEN NOPCHG; if CV is OFF then don't vary pitch
  IF PCHANCE = 2 THEN
      GOSUB SWAPNOTES
      GOTO MAINLOOP
     ENDIF ; if CV if full on then ALWAYS vary the pitch
  RSEED = RANDOM RSEED; cast the dice
  RSEED = RSEED + 1; preclude division by zero
  RCHANCE = RSEED/(65535/PCHANCE);scale random number to current range of CVin1
  RCHANCE = RCHANCE+1
  IF PCHANCE = RCHANCE THEN
    GOSUB SWAPNOTES
   ENDIF 
  NOPCHG: 
LOW RUNLED
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
	

	
SWAPNOTES:
RFACT = 65535/16;'sets scale of random number to size of array
HIGH STOPLED
PAUSE 50
'two array elements exchange places
	   
	    RSEED = RANDOM RSEED; cast dice
	    RDEX1 = RSEED/RFACT; YIELDS RANGE OF 0 THRU 16
	    ROLLEDDOUBLES: 
	    RSEED = RANDOM RSEED; cast dice 
	    RDEX2 = RSEED/RFACT; YIELDS RANGE OF 0 THRU 16 
	    IF RDEX2 = RDEX1 THEN ROLLEDDOUBLES; no good to exchance same array element with same - do over!
	    VAL1 = VAL(RDEX1);>>>>>>>>>>>
	    VAL(RDEX1) = VAL(RDEX2);>>>>>
	    VAL(RDEX2) = VAL1;>>>>>>>>>>> exchange the element @ RDEX1 with the one @ RDEX2
LOW STOPLED
	
RETURN	