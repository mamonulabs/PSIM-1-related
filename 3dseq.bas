'PUBLIC DOMAIN ... OPEN SOURCE FOREVER
'===========   3DSEQ =========
'=========== 25 Feb 2004=========
'      (happy B'day Maureen!)
'by Dr. Mabuse for the Modern Implement Company
'
'---------REVISED 15 April 2004--------
'to accomodate the peccadilloes of compiler version 7.2.0.1
'--------------------------------------
' LOADALLDACS & SCANADC
' by Prof. Grant Richter
' all hail his sublime woggleness   
'
'description:
'
' a sequencer that outputs:
'
' a complex CV from CVout1
' a variable Attack/Release envelope from CVout2
' a trigger at the start of each event from CVout3
' a vibrato-only output from CVout4 (that follows the vibrato on CVout1)
' 
'Each step has:
'a pitch: PITCH
'a duration: DUR
'a slew flag; SLEW 1 = slew to the NEXT pitch in steps scaled to the duration of THIS step; THIS TAKES PRECEDENCE OVER THE VIBRATO FLAG
'a Vibrato flag; VIBF 1 = apply vibrato (to pitch) at a rate scaled to the duration and die out over that duration
'a Break point; BKPT this defines an envelope that is output from CVout2. The breakpoint must be <= DUR, if DOR = 1000 the a BKPT of 1 would output a downgoing ramp, a BKPT of 1000 would output an upgoing ramp, a BKPT of 500 would output a triangle 
'
'inputs:
'Cvin1 determines the probablility that the sequenence steps will be reordered 0=no chance, >8v = reordered after every cycle, then 1 to 7 out of 8 chances in-between
'CVin2 < 3v=do not randomize the envelopes. >3v = randomize the envelopes after every cycle. 
'Start Button (IN4) reset all envelope breakpoints  to their original values (established by the BKPT array)
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

J         VAR WORD
FJ        VAR FLOAT	
STARTAT   VAR SBYTE
ENDAT     VAR SBYTE
DEST      VAR SWORD
FDEST     VAR FLOAT
WORKVAR   VAR FLOAT
STEPSIZE  VAR FLOAT
AMPLITUDE VAR FLOAT
CPTS      VAR FLOAT
ICPTS     VAR WORD
UPDN      VAR BIT
EVOTHR    VAR BYTE
REPCT     VAR WORD
REPS      VAR WORD
FDUR      VAR FLOAT
SUBX      VAR FLOAT
ISUBX     VAR WORD
OFFSET    VAR SWORD
PITCHCTR  VAR WORD
PCV       VAR WORD
PCV1      VAR WORD
NOW       VAR BYTE
NXT       VAR BYTE
DIFF      VAR SWORD
CHUNK     VAR WORD
VIBCTR    VAR WORD
ITMP      VAR WORD
ISTART    VAR WORD
IEND      VAR WORD
IAMP      VAR WORD

PITCH     VAR WORD(16)
DUR       VAR WORD(16)
BKPT      VAR WORD(16)
ENVP      VAR WORD(16)
SLEW      VAR BIT(16)
VIBF      VAR BIT(16)
VALW1     VAR WORD
VALB1     VAR BIT

	
BPM       VAR WORD
RSEED     VAR WORD
RCHANCE   VAR WORD
PCHANCE   VAR WORD
RDEX1     VAR WORD
RDEX2     VAR WORD
RFACT     VAR WORD
RDEX      VAR WORD
COIN      VAR WORD

EOUT      VAR SWORD
ECTR      VAR SWORD
EOFF      VAR SWORD
FEOFF     VAR FLOAT
FENVP     VAR FLOAT
ESTEPSZ   VAR FLOAT





    '*****************************************************
	'Initialize Module

 DIRS = %1111110000000000 ' Configure Pins    1=input  0=output
 OUTS = %1111111111111111 ' Configure State   1=low    0=high
'   *****************************************************
LOW STOPLED
LOW RUNLED

VIBCTR = 200; center frequency of vibrato-only output (dac4v)

RSEED = 17

'seed ARRAYs that define the sequence
PITCH( 1) = 40
  DUR( 1) = 500
 SLEW( 1) = 0
 VIBF( 1) = 0
 BKPT( 1) = 250
PITCH( 2) = 64
  DUR( 2) = 500
 SLEW( 2) = 1
 VIBF( 2) = 0
 BKPT( 2) = 1
PITCH( 3) = 128
  DUR( 3) = 500
 SLEW( 3) = 0
 VIBF( 3) = 0
 BKPT( 3) = 499 
PITCH( 4) = 256
  DUR( 4) = 100
 SLEW( 4) = 0
 VIBF( 4) = 0
 BKPT( 4) = 50
PITCH( 5) = 1024
  DUR( 5) = 500
 SLEW( 5) = 0
 VIBF( 5) = 0
 BKPT( 5) = 1
PITCH( 6) = 40
  DUR( 6) = 500
 SLEW( 6) = 0
 VIBF( 6) = 0
 BKPT( 6) = 250 
PITCH( 7) = 256
  DUR( 7) = 2000
 SLEW( 7) = 0
 VIBF( 7) = 0
 BKPT( 7) = 1 
PITCH( 8) = 320
  DUR( 8) = 500
 SLEW( 8) = 0
 VIBF( 8) = 1
 BKPT( 8) = 1 
PITCH( 9) = 1588
  DUR( 9) = 100
 SLEW( 9) = 0
 VIBF( 9) = 0
 BKPT( 9) = 1 
PITCH(10) = 1492
  DUR(10) = 500
 SLEW(10) = 1
 VIBF(10) = 0
 BKPT(10) = 1  
PITCH(11) = 64
  DUR(11) = 500
 SLEW(11) = 0
 VIBF(11) = 0
 BKPT(11) = 1 
PITCH(12) = 256
  DUR(12) = 1140
 SLEW(12) = 0
 VIBF(12) = 1
 BKPT(12) = 1140 
PITCH(13) = 3000
  DUR(13) = 500
 SLEW(13) = 0
 VIBF(13) = 0
 BKPT(13) = 1
PITCH(14) = 332
  DUR(14) = 500
 SLEW(14) = 1
 VIBF(14) = 0
 BKPT(14) = 1
PITCH(15) = 870
  DUR(15) = 100
 SLEW(15) = 0
 VIBF(15) = 0
 BKPT(15) = 1 
PITCH(16) = 1087
  DUR(16) = 500
 SLEW(16) = 0
 VIBF(16) = 1
 BKPT(16) = 1 
 
GOSUB RESTORENV 
 
NOW=0 






 
MAINLOOP:

GOSUB SCANADC

DAC4V = VIBCTR; output vibrato-only center frequency
DAC3V = 0
GOSUB LOADALLDACS; start TRIGGER ouput on CVout3
DAC3V = 4095
GOSUB LOADALLDACS; leading/rising edge of TRIGGER ouput on CVout3
'
' this is the 'homemade' 1 thru 16 loop counter- it is circular, ie when NOW = 16, NXT = 1...forever
NOW = NOW + 1
IF NOW >= (16+1) THEN
   NOW = 1
  ENDIF
IF NOW = 16 THEN
   NXT = 1
  ELSE
   NXT = NOW + 1
ENDIF
'
'probablility knob - as CV in goes up chances increase that event will happen
'
  PCHANCE = (ADC1V/128)+1;quantize Cv in 1 to 1 thru 8
  IF PCHANCE <= 1 THEN 
        HIGH RUNLED
        GOTO NOPCHG; if CV is OFF then don't swap events
      ENDIF
  IF PCHANCE >= 8 THEN
       GOSUB SWAPEVENTS
       GOTO NOPCHG
     ENDIF ; if CV if full on then ALWAYS swap events
  PCHANCE = 9- PCHANCE; invert pchance so that 8 increases the chances that something will happen 
  RSEED = RANDOM RSEED; cast the dice
  RSEED = RSEED + 1; preclude division by zero
  RCHANCE = RSEED/(65535/PCHANCE);scale random number to current range of CVin1
  RCHANCE = RCHANCE+1
  IF PCHANCE = RCHANCE THEN
    GOSUB SWAPEVENTS
   ENDIF 
NOPCHG:;exit point

IF ADC2V > 300 THEN;if CUin2 is high then randomize all the envelope breakpoints
   GOSUB RANDENV
  ENDIF
  
IF IN4 THEN;restore all envelope breakpoints to their orginal values - in the BKPT array
    GOSUB RESTORENV
  ENDIF    


DAC3V = 0
GOSUB LOADALLDACS; trailing edge of TRIGGER ouput on CVout3
     
IF (PITCH(NXT) <> PITCH(NOW)) AND (SLEW(NOW) > 0) THEN; a SLEW event
    PCV1 = PITCH(NOW)
    ECTR = 0; initialize loop counter for envelopre generator ENVGEN
    DAC2V = 0
    GOSUB LOADALLDACS; force envelope ouput on CVout2 to start @ 0	
    DIFF = (PITCH(NXT) - PITCH(NOW) )
    DIFF = ABS(DIFF)
    CHUNK = (DIFF/DUR(NOW))
    IF CHUNK < 1 THEN 
       CHUNK = 1
      ENDIF
 	IF PITCH(NXT) > PITCH(NOW) THEN 
       GOINGUP:
       ECTR = ECTR + CHUNK; increment loop counter for envelope generator ENVGEN 	   
	   PCV1 = PCV1 + CHUNK 
	   IF PCV1 >= PITCH(NXT) THEN
	      DAC2V = 0
          GOSUB LOADALLDACS; force envelope ouput on CVout2 to end @ 0	 
	      GOTO ENDMAINLOOP
	     ENDIF
	   DAC1V = PCV1
       GOSUB ENVGEN; also outputs DAC1V to LOADALLDACS
	   GOTO GOINGUP    
	  
	  ELSE 
 
	   GOINGDOWN: 
	   ECTR = ECTR + CHUNK; increment loop counter for envelope generator ENVGEN 	   
	   PCV1 = PCV1 - CHUNK
	   IF PCV1 <= PITCH(NXT) THEN
	   	  DAC2V = 0
          GOSUB LOADALLDACS; force envelope ouput on CVout2 to end @ 0	 
	      GOTO ENDMAINLOOP
	     ENDIF
	   DAC1V = PCV1
	   GOSUB ENVGEN; also outputs DAC1V to LOADALLDACS
	   GOTO GOINGDOWN     
	ENDIF
ELSE; NOT a slew event ....either plain or vibrato
    PCV1 = PITCH(NOW)
  	IF VIBF(NOW) THEN
	      GOSUB VIBRATO; it's......VIBRATO TIME!!!!!
	   ELSE; PLAIN VANILLA EVENT NO SLEW , NO VIBRATO
	   DAC2V = 0
       GOSUB LOADALLDACS; force envelope ouput on CVout2 to start @ 0		   
	   J=0
       FOR J = 1 TO DUR(NOW)
           DAC1V = PCV1
           ECTR = J
           GOSUB ENVGEN; also outputs DAC1V to LOADALLDACS
       NEXT
       DAC2V = 0
       GOSUB LOADALLDACS; force envelope ouput on CVout2 to end @ 0	                       	
	ENDIF 
ENDIF

ENDMAINLOOP:
GOTO MAINLOOP


'*******************************************************************
'************************** SUBROUTINES ****************************
'*******************************************************************
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


VIBRATO:


'setup overall variables for the event:

REPS = DUR(NOW)/32;set a constant vibrato freq at 1/32 of the overall event duration
'the 32 is also a factor in the overal amplitude of the vibrato the max will be 32/2 = 16 = an approximate quarter-tone
REPCT = REPS; initialize the state of the repetition counter
ICPTS = REPS/2; the change point - CPTS is the half point of the triangle wave - the interval after which each change occurs
UPDN = 1; 1 = AWAY from center freq. , 0 = TOWARD center frequency
STARTAT=0
ENDAT=0
EVOTHR=0; counter to indicate EVERY OTHER change point
DEST=ICPTS; DEST = Destination = it's time to change direction or cross zero
DAC2V = 0
GOSUB LOADALLDACS; force envelope ouput on CVout2 to start @ 0		
'
'loop thru the vibrato event.......
'
'
'
'this first section builds the vibrato by establishing the endpoints (STARTAT & ENDAT) of lines that zig-zag across the center frequency
'
FOR J = 1 TO DUR(NOW)
        FJ = TOFLOAT(J)
	    IF J = DEST THEN;it's time to change direction or cross zero
	       ISUBX=J; store subtractor for later use in scaling the 'backwards counter'
	       DEST = DEST + ICPTS; establish the NEXT change point
	       EVOTHR = EVOTHR + 1
	       IF EVOTHR = 2 THEN;EVERY OTHER change point: toggle the polarity of the wave
	          EVOTHR=0; reset the every other counter
	          STARTAT=ENDAT
	          ENDAT=0
	          IF UPDN = 1 THEN
	             UPDN = 0
	            ELSE
	             UPDN = 1
	            ENDIF
	         ELSE; at the peak (midpoint) of the wave, simply reverse its direction
	           IF 32 - (REPS-REPCT) >= 0 THEN
	              STARTAT = ENDAT
	              ENDAT = 32 - (REPS-REPCT)
	              IF UPDN = 0 THEN
	                 ENDAT = -ENDAT
	                ENDIF
	              REPCT = REPCT - 1
	             ELSE
	              STARTAT = ENDAT
	              ENDAT = 0
	            ENDIF
	         ENDIF
	      ENDIF
	'      
	'this second section calulates the interpolation function (rise/run) between STARTAT & ENDAT for each integer value of J
	'      
    ' setup variables for interpolation and convert integers to floating point where necessary
   CPTS = TOFLOAT(ICPTS)
   FDEST = TOFLOAT(DEST)
   SUBX = TOFLOAT(ISUBX)
   IAMP = ABS( ABS(STARTAT) - ABS(ENDAT) )
   AMPLITUDE = TOFLOAT(IAMP)
   STEPSIZE = 0.00
   AMPLITUDE = AMPLITUDE /  2.00
   CPTS = TOFLOAT(ICPTS)
   'now do a different interpolation for every type of line segment defined by STARTAT & ENDAT 
   IF STARTAT = 0 AND ENDAT > 0 THEN;slope from 0 to +peak
       ITMP = TOINT(WORKVAR); required for first time thru this section only
       WORKVAR = TOFLOAT(ITMP)
       WORKVAR= ((FDEST-(FDEST-FJ))-SUBX); condition J to rise from 0
       STEPSIZE = AMPLITUDE / CPTS; calculate a term proportional to the  distance already traveled toward ENDAT
       WORKVAR = WORKVAR * STEPSIZE; combine rise/run-point for each J
       OFFSET=TOINT(WORKVAR);round, and reconcile variable type for export to DAC
      ENDIF           
   IF STARTAT > 0 AND ENDAT = 0 THEN;slope from +peak to 0
       ITMP = TOINT(WORKVAR); required for first time thru this section only
       WORKVAR = TOFLOAT(ITMP)
       WORKVAR= (FDEST-FJ); condition J to fall toward 0
       STEPSIZE = AMPLITUDE / CPTS; calculate a term proportional to the  distance already traveled toward ENDAT
       WORKVAR = WORKVAR * STEPSIZE; combine rise/run-point for each J
       OFFSET=TOINT(WORKVAR);round, and reconcile variable type for export to DAC
      ENDIF           
   IF STARTAT = 0 AND ENDAT < 0 THEN;slope from 0 to -peak
       ITMP = TOINT(WORKVAR); required for first time thru this section only
       WORKVAR = TOFLOAT(ITMP)
       WORKVAR= ((FDEST-(FDEST-FJ))-SUBX); condition J to fall from 0
       STEPSIZE = AMPLITUDE / CPTS; calculate a term proportional to the  distance already traveled toward ENDAT
       WORKVAR = WORKVAR * STEPSIZE; combine rise/run-point for each J
       OFFSET = TOINT(WORKVAR); load variable to be summed with center frequency
      ENDIF   
   IF STARTAT < 0 AND ENDAT = 0 THEN;slope from -peak to 0
       ITMP = TOINT(WORKVAR); required for first time thru this section only
       WORKVAR = TOFLOAT(ITMP)
       WORKVAR= (FDEST-FJ); condition J to rise toward 0
       STEPSIZE = AMPLITUDE / CPTS; calculate a term proportional to the  distance already traveled toward ENDAT
       WORKVAR = WORKVAR * STEPSIZE; combine rise/run-point for each J
       OFFSET = TOINT(WORKVAR); load variable to be summed with center frequency 
      ENDIF
ICPTS=TOINT(CPTS)
'Add OFFSET to center frequency and load it into the DAC
PCV = PCV1 + OFFSET
DAC1V = PCV
DAC4V =VIBCTR + (OFFSET * 4); setup the vibrato only output
ECTR = J
GOSUB ENVGEN; also outputs DAC1V to LOADALLDACS
NEXT
DAC2V = 0
GOSUB LOADALLDACS; force envelope ouput on CVout2 to end @ 0	            
RETURN	                	                   


	
SWAPEVENTS:
HIGH STOPLED     
RSEED = RANDOM RSEED; flip a coin to determine if vibrato flag gets toggled
COIN = RSEED/32768
IF COIN > 0 THEN; Toggle vibrato flag
          IF VIBF(NOW) = 1 THEN 
             VIBF(NOW) = 0
            ELSE 
             VIBF(NOW) = 1
            ENDIF       
ENDIF
      
RFACT = 65535/16;'sets scale of random number to size of array
'two array elements exchange places
	    RSEED = RANDOM RSEED; cast dice
	    RDEX1 = RSEED/RFACT; YIELDS RANGE OF 0 THRU 16
	    ROLLEDDOUBLES: 
	    RSEED = RANDOM RSEED; cast dice 
	    RDEX2 = RSEED/RFACT; YIELDS RANGE OF 0 THRU 16 
	    IF RDEX2 = RDEX1 THEN ROLLEDDOUBLES; no good to exchance same array element with same - do over!
	    
	    VALW1 = PITCH(RDEX1);>>>>>>>>>>>
	    PITCH(RDEX1) = PITCH(RDEX2);>>>>>
	    PITCH(RDEX2) = VALW1;>>>>>>>>>>> exchange the PITCH @ RDEX1 with the one @ RDEX2
	    
	    VALW1 = DUR(RDEX1);>>>>>>>>>>>
	    DUR(RDEX1) = DUR(RDEX2);>>>>>
	    DUR(RDEX2) = VALW1;>>>>>>>>>>> exchange the PITCH @ RDEX1 with the one @ RDEX2
	    
	    VALW1 = ENVP(RDEX1);>>>>>>>>>>>
	    ENVP(RDEX1) = ENVP(RDEX2);>>>>>
	    ENVP(RDEX2) = VALW1;>>>>>>>>>>> exchange the ENVELOPE BREAKPOINT @ RDEX1 with the one @ RDEX2
	    
	    VALB1 = SLEW(RDEX1);>>>>>>>>>>>
	    SLEW(RDEX1) = SLEW(RDEX2);>>>>>
	    SLEW(RDEX2) = VALB1;>>>>>>>>>>> exchange the SLEWFLAG @ RDEX1 with the one @ RDEX2
	    
	    VALB1 = VIBF(RDEX1);>>>>>>>>>>>
	    VIBF(RDEX1) = VIBF(RDEX2);>>>>>
	    VIBF(RDEX2) = VALB1;>>>>>>>>>>> exchange the VIBRATO FLAG @ RDEX1 with the one @ RDEX2
LOW STOPLED	    
RETURN	


ENVGEN:
IF ECTR <= ENVP(NOW) THEN
   EOFF = ENVP(NOW) - (ENVP(NOW) - ECTR )
   FEOFF = TOFLOAT(EOFF)
   FENVP = TOFLOAT(ENVP(NOW))
   ESTEPSZ = 4095.00 / FENVP
   FEOFF = FEOFF * ESTEPSZ
   EOUT = TOINT(FEOFF)
   DAC2V = EOUT
   GOSUB LOADALLDACS
  ELSE
   EOFF = ENVP(NOW) - ECTR
   FEOFF = TOFLOAT(EOFF)
   FENVP = TOFLOAT(ENVP(NOW))
   FDUR = TOFLOAT(DUR(NOW))
   ESTEPSZ = FDUR - FENVP
   ESTEPSZ = 4095.00 / ESTEPSZ
   FEOFF = FEOFF * ESTEPSZ
   EOUT = TOINT(FEOFF)
   EOUT = 4095 + EOUT
   IF EOUT < 0 THEN 
      EOUT = 0
     ENDIF
   DAC2V = EOUT
   GOSUB LOADALLDACS
ENDIF
RETURN

RESTORENV:
FOR J = 1 TO 16
    ENVP(J) = BKPT(J)
NEXT
RETURN

RANDENV:
FOR J = 1 TO 16
    RFACT = 65535/DUR(J);'sets scale of random number to duration of event
    RSEED = RANDOM RSEED; cast dice
    ENVP(J) = RSEED/RFACT; yields range with duration
    IF ENVP(J) = 0 THEN
       ENVP(J) = 1
      ENDIF
NEXT
RETURN
    

