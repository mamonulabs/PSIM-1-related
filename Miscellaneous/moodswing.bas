'OPEN SOURCE FOREVER
'====================================================
' PSIM-1 (Programmable Synthesizer Interface Module)
'
' Module: PSIM-1 REV1A
' Processor Type: Basic Micro - Basic Atom Pro24M
'
'
'Basic Program originated by dr.mabuse 23 Jan 2004 
'for The Modern Implement Company 
'
'Mood Swing:
' description ( a dance about architecture)
' 
'input: any CV between 0 & 5 V - there is a threshold a threshold...
'output: a triangle wave CV that changes direction everytime the CV passes through the threshold 
'if the CV stays below the threshold a simple triangle wave results
'if the CV stays above the threshold the CV remains wherever it's at at the time it crossed the threshold 
'
'this is the prototype single channel (1) version
'----------------------------------------------------

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

LOADDACS CON 11  ' Pin OUT to DAC LOADDACS
SERDATA CON 12  ' Pin OUT Serial Data to DAC (16-bit)
CLOCK CON 13  ' Pin OUT to Clock DAC
STOPLED CON 9   ' Red LED
RUNLED CON 10  ' Green LED
BSTART CON 5   ' Start Button
BSTOP CON 4   ' Stop  Button
AUX CON 8 ' AUX Jack (unbuffered)

RAWDAC1  VAR WORD  ' RAW DAC DATA 1 
RAWDAC2  VAR WORD  ' RAW DAC DATA 2 
RAWDAC3  VAR WORD  ' RAW DAC DATA 3 
RAWDAC4  VAR WORD  ' RAW DAC DATA 4 

DAC1V  VAR WORD  ' DAC Value to be Sent to DAC Channel
DAC2V  VAR WORD  ' DAC Value to be Sent to DAC Channel
DAC3V  VAR WORD  ' DAC Value to be Sent to DAC Channel
DAC4V  VAR WORD  ' DAC Value to be Sent to DAC Channel

ADC1 CON 0
ADC2 CON 1
ADC3 CON 2
ADC4 CON 3

ADC1V VAR WORD 'INPUT A/D BUFFER CH. 1
ADC2V VAR WORD 'INPUT A/D BUFFER CH. 2
ADC3V VAR WORD 'INPUT A/D BUFFER CH. 3
ADC4V VAR WORD 'INPUT A/D BUFFER CH. 4


UP1DN        VAR BIT 
UP2DN        VAR BIT 
UP3DN        VAR BIT 
UP4DN        VAR BIT  


    '*****************************************************
'Initialize Module

 DIRS = %1111110000000000 ' Configure Pins    1=input  0=output
 OUTS = %1111111111111111 ' Configure State   1=low    0=high
'*****************************************************

LOW STOPLED
HIGH RUNLED

DAC1V = 0
UP1DN = 1

MAINLOOP:
GOSUB SCANADC;  get CV
IF ADC1V > 2 THEN ; is it above the trigger threshold voltage!
   IF UP1DN = 0 THEN; If so, then..........      
        UP1DN = 1 
    ELSE      
        UP1DN = 0
   ENDIF
  ENDIF  ;............Toggle the up / down flag 
IF UP1DN = 1 THEN 
        DAC1V = DAC1V + 1; if the flag is 1 then rise
      ELSE 
       DAC1V = DAC1V - 1; if the flag is 0 then fall
      ENDIF
IF DAC1V > 4095 THEN ; if you're at the top of the range then go down
   UP1DN = 0
   DAC1V = 4095
ENDIF
IF DAC1V < 1 THEN ; if you're at the bottom of the range then go up
    UP1DN = 1 
    DAC1V = 0
ENDIF
' Copy the above, declare new vars to add channels HERE
GOSUB LOADALLDACS

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