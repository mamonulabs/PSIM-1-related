'OPEN SOURCE FOREVER / PUBLIC DOMAIN
'==================WigglyMan 1=========================
'====by dr.mabuse for the Modern Implememnt Company====
'
' CALCRAND, LOADALLDACS & SCANADC
' by Prof. Grant Richter
' all hail his sublime woggleness   
'
'
'makes a ramp wave that makes stops to smell the entropic roses an interestingly random points along the way 
'
'CVin1 = time stretch 0=slowest 10=fastest
'CVout1 = slewed/wiggly output
'CVout2 = stepped output
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
	
	STP          VAR SWORD
	DUR          VAR WORD
	CHUNK        VAR WORD
	VAL1         VAR WORD
	VAL2         VAR WORD
	J            VAR WORD
	RSEED        VAR WORD
	RSEED2       VAR WORD
	VAR1         VAR WORD
	VAR2         VAR WORD
	NXTDIV       VAR WORD
	NXTDIV2      VAR WORD
	RNDM         VAR WORD
	LCT          VAR WORD
'	LASTLCT      VAR WORD
	UPDN         VAR BIT  

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
	 
	 'setup timer w for 16 MHz free run
	 
	 TMRW = %10001000 'note set CTS to 1 to run
	 TCRW = %00000000 'set CCLR to 0 for free run direct internal clock
	 TIERW = %01110000
	 TSRW = %01110000
	 TIOR0 = %10001000
	 TIOR1 = %10001000
	 
	'*****************************************************
UPDN=0
LCT = 0


NEWWAVE:

'Get two separate random starting points
'the wave descends weaving between two 'Sets' of  downward-trending random points
GOSUB CALCRAND
RSEED = RNDM;
GOSUB CALCRAND
RSEED2 = RNDM
'create 2 starting divisors	
NXTDIV=65535/4095
NXTDIV2=65535/4095

IF LCT // 2 THEN ; if the last wave took an EVEN number of steps to zero out then make this next wave a UPgoing ramp
   UPDN = 1
   HIGH STOPLED
  ELSE; otherwise... DOWNgoing
   UPDN = 0
   LOW STOPLED
ENDIF


LCT = 0; initialize a counter to identify the very first event in the waveplot and help determine the direction of the next wave


MAINLOOP:


;Get the timestretching factor, (CHUNK) from CVin1
GOSUB SCANADC
CHUNK = ADC1V/10
IF CHUNK = 0 THEN 
    CHUNK = 1
   ENDIF

;SET 1...
RSEED = RANDOM(RSEED); roll the dice
VAR1 = RSEED/NXTDIV; plot a point on the wave
'''DEBUG [DEC VAR1,13]
NXTDIV = 65535/VAR1; NXTDIV will always yield a division into smaller & smaller VAR1's
IF LCT > 0 THEN; don't squirt out VAR1 on the very first pass - just give the next slewing comparison someting to compare
   IF UPDN = 0 THEN
        DAC2V = VAR1
       ELSE
        DAC2V = 4095 - VAR1
      ENDIF  
'   set the step , pos or neg, of the slewing loop basd on the whether the point in Set 1 (VAR1) is higher or lower than the point in Set 2 (VAR2)
   IF VAR2 > VAR1 THEN
      STP = -1 * CHUNK
     ELSE
      STP = 1 * CHUNK
    ENDIF
' Then Slew! up or down    
   FOR J = VAR2 TO VAR1 STEP STP 
       IF UPDN = 0 THEN
              DAC1V = J
           ELSE
              DAC1V = 4095 - J
           ENDIF  
       GOSUB LOADALLDACS
   NEXT
  ENDIF
   
LCT = LCT+1; bump the first-time flag and count the number of steps it took to finish, used to toggle UPDN



'SET 2...  
RSEED2 = RANDOM(RSEED2); roll the dice
VAR2 = RSEED2/NXTDIV2; plot a point on the wave
'''DEBUG [DEC VAR2,13]
NXTDIV2 = 65535/VAR2; NXTDIV will always yield a division into smaller & smaller VAR2's
IF UPDN = 0 THEN
        DAC2V = VAR2
       ELSE
        DAC2V = 4095 - VAR2
      ENDIF  
DAC2V = VAR2; output the stepped CV
'   set the step , pos or neg, of the slewing loop basd on the whether the point in Set 1 (VAR1) is higher or lower than the point in Set 2 (VAR2)
IF VAR1 > VAR2 THEN
      STP = -1 * CHUNK
     ELSE
      STP = 1 * CHUNK
    ENDIF
' Then Slew! up or down   
FOR J = VAR1 TO VAR2 STEP STP
    IF UPDN = 0 THEN
        DAC1V = J
       ELSE
        DAC1V = 4095 - J
      ENDIF  
    GOSUB LOADALLDACS
NEXT

IF VAR1 = 0 AND VAR2 = 0 THEN NEWWAVE;if both SET 1 & SET 2 have bottomed out then start from two new random points


GOTO MAINLOOP ; keep on truckin' until Both Sets have zeroed out    
 
	
'*******************************************************************
'************************** SUBROUTINES ****************************
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

CALCRAND:
	RNDM = RANDOM TCNT
RETURN
