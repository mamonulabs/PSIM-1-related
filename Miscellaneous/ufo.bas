'PUBLIC DOMAIN ... OPEN SOURCE FOREVER
'===========  U F O =========
'=========== 9 Mar 2004=========
'by Dr. Mabuse for the Modern Implement Company
'
' LOADALLDACS & SCANADC
' by Prof. Grant Richter
' all hail his sublime woggleness   
'
'description:
'
'CVout1 squirts 2 nested sine waves
'
' This is a demo 
'that demonstrates a quick & dirty method for producting subaudio sine waves using simple FOR/NEXT loops
'it exploits the speed advantages of using MBASIC's 'pre-fab' Cosine Function (COS)

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

    J       VAR WORD
    JJ      VAR WORD
 
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
MAINLOOP:

FOR JJ = 1 TO 126; 1 to 126 produces cosines 67 thru 191 and back again 
    FOR J = 1 TO 126; (it's TRUE!!! go look it up in your high school algebra book)
      DAC1V = COS(J) + COS(JJ)
      GOSUB LOADALLDACS
    NEXT 
  NEXT   
GOTO MAINLOOP
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''' Subroutines '''''''''''''''''''''''''''''''''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'all hail GR!
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
'all hail GR! 	
SCANADC:
	'load buffers with actual a/d values
	ADIN ADC1, ADC1V
	ADIN ADC2, ADC2V
	ADIN ADC3, ADC3V
	ADIN ADC4, ADC4V
	RETURN   
    