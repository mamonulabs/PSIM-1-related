'OPEN SOURCE FOREVER
'====================================================
' PSIM-1 (Programmable Synthesizer Interface Module)
'
' Module: PSIM-1 REV1A
' Processor Type: Basic Micro - Basic Atom Pro24M
'
'
'Basic Program originated by dr.mabuse 26 Jan 2004 
'for The Modern Implement Company 
'
'Badpotsim2 (Bad Potetiometer Simulator):
' description ( a dance about architecture)
' 
'input: any CV between 0 & 5 V 
'output: whenever the CV on input 1 changes , 
'a square pulse scaled to the magnitude and direction of the change is squirted out of output 1
'a slewed pluse , with the direction of the slew set by the direction of the change is squirted out of output 2 
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
	
	DIFF         VAR SWORD
	DUR          VAR WORD
	CHUNK        VAR WORD
	VAL1         VAR WORD
	VAL2         VAR WORD
	J            VAR WORD
	UDFLAG       VAR BIT
	

    '*****************************************************
	'Initialize Module

 DIRS = %1111110000000000 ' Configure Pins    1=input  0=output
 OUTS = %1111111111111111 ' Configure State   1=low    0=high
	'*****************************************************

LOW STOPLED
HIGH RUNLED


MAINLOOP:
	GOSUB SCANADC;  get CVs
	VAL1 = ADC1V ; snapshot NOW!
	FOR J = 1 TO 1000; catch window duration,wait....
	NEXT 
	GOSUB SCANADC
	VAL2 = ADC1V; and then NOW!
	IF VAL1 <> VAL2 THEN GOSUB BANG; if the CV changed then get busy
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
	
	
BANG:
    DIFF = (VAL1 - VAL2); how much did the CV change - DIFF is used to determine shape & dimensions of the output pulse
    IF DIFF < 0 THEN 
       UDFLAG = 0; if it DEcreased then use downgoing slew
       DUR = 100 - (DIFF * 2); sets duration of pulse
      ELSE
       UDFLAG = 1; if it INcreased use upgoing slew
       DUR = 100 + (DIFF * 2); sets duration of pulse
      ENDIF 
    DIFF = ABS(DIFF) * 750 ; sets amplitude of pulse
    CHUNK = 1 + (DIFF/DUR); scale slew divisor to the amplitude
    DAC1V = 0
    DAC2V = 0
    GOSUB LOADALLDACS; always start pulse at zero
    IF UDFLAG = 0 THEN 
           DAC2V = DIFF; ch 2 slew going DOWN
           FOR J = 1 TO DUR; output pulse width
                    DAC1V = DIFF; ch1 is always square
                    DAC2V = DAC2V - CHUNK; ch2 is always slewed
                    GOSUB LOADALLDACS
           NEXT
         ELSE
           DAC2V = 0; ch 2 slew going up
           FOR J = 1 TO DUR; output pulse width
                    DAC1V = DIFF; ch1 is always square
                    DAC2V = DAC2V + CHUNK; ch2 is always slewed
                    GOSUB LOADALLDACS
           NEXT
        ENDIF     
    DAC1V = 0
    DAC2V = 0
    GOSUB LOADALLDACS; always finish pulse at zero
    RETURN	