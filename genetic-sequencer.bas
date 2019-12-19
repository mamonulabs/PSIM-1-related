'OPEN SOURCE FOREVER
'====================================================
' PSIM-1 (Programmable Synthesizer Interface Module)
'
' Module: PSIM-1 REV1.0B
' Processor Type: Basic Micro - Basic Atom Pro24M
'
'
' Woody Wall 29 May 2005
' woody.wall@gmail.com
'
'
'****************************************************
'              genetic-sequencer.bas 
'****************************************************
'
'
' DESCRIPTION:
'	Generates a random gate and voltage patterns between one and
'	sixteen steps long. Controls are provided to control the
'	probability and degree of change, and the sequence length.
'
'
' CONTROLS:
'
'	AUX: An output; goes high on the first step of a pattern.
'
'	START: Starts playing from step one.
'
'	STOP: Stops playing.
'
'	IN-1: Clock input.
'
'	IN-2: Controls the probability of pattern mutation. The higher the
'		voltage the higher the probability that the pattern will change
'		when the current pattern ends. The STOP LED flashes at the clock
'		rate whenever a new pattern is to be generated.
'
'	IN-3: Controls the degree to which the pattern changes. Zero volts
'	    gives small changes; ten volts changes the pattern completely.
'
'	IN-4: Controls the length of the pattern currently playing. Zero
'		volts gives 16 steps and higher voltages give progressivly
'		shorter patterns. The START LED flashes on the first step
'		of the pattern.
'
'	OUT-1: Gate output for pattern 1.
'
'	OUT-2: Pattern 1 voltage sequence which changes when OUT-1 goes high.
'
'	OUT-3: Gate output for pattern 2.
'
'	OUT-4: Pattern 2 voltage sequence which changes when OUT-3 goes high.
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
	
	LOADDACS	CON 11  ' Pin OUT to DAC LOADDACS
	SERDATA		CON 12  ' Pin OUT Serial Data to DAC (16-bit)
	CLOCK		CON 13  ' Pin OUT to Clock DAC
	STOPLED		CON 9   ' Red LED
	RUNLED		CON 10  ' Green LED
	BSTART		CON 4   ' Start Button
	BSTOP		CON 5   ' Stop  Button
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

	i			var word
	n			var word
	n1			var	word
	n2			var word
	n3			var word
	n4			var word
	rand		var word
	bvar		var word
	val1		var word(16)
	val2		var word(16)
	pat1		var word
	pat2		var word
	vol1		var word
	vol2		var word
	stp			var	word
	trig		var word
	stpmax		var word
	patchg		var bit
	vcount		var word
	vpoint		var word
	patbit		var word
	pmutate		var word
	pmseed		var word
	rndm		var	word
			
'**********************************************************************
'Initialize Module

 DIRS = %1111110000000000 ' Configure Pins    1=input  0=output
 OUTS = %1111111111111111 ' Configure State   1=low    0=high

 'setup timer w for 16 MHz free run
	 
 TMRW = %10001000 'note set CTS to 1 to run
 TCRW = %00000000 'set CCLR to 0 for free run direct internal clock
 TIERW = %01110000
 TSRW = %01110000
 TIOR0 = %10001000
 TIOR1 = %10001000

	 
'*****************************************************
' MAIN

low runled
gosub resetdac

;Wait for one input clock pulse before sampling the timer
;and setting the random number seeds. This adds a bit of
;randomness. Without doing this, the timer values were
;always the same after a reset.
gosub scanadc
while adc1v < 512
	gosub scanadc
wend
gosub scanadc
while adc1v > 512
	gosub scanadc
wend

;Initialize all the random seeds.
gosub calcrand
pmseed = rndm
gosub calcrand
n1 = rndm
gosub calcrand
n2 = rndm
gosub calcrand
n3 = rndm
gosub calcrand
n4 = rndm

gosub scanadc
stpmax = 16
vpoint = 0
vcount = 15
pat1 = 0
pat2 = 0
gosub newpat	
gosub scanadc
stpmax = 16 - (adc4v / 64)
vol1 = val1(0)
vol2 = val2(0)

waitstart:
	low runled
	high stopled
	dac1v = 0
	dac2v = vol1
	dac3v = 0
	dac4v = vol2
	gosub loadalldacs
	button bstart,1,0,0,bvar,1,restart
	goto waitstart
	
restart:
	stp = stpmax
	trig = 1
	patchg = 0
	goto clocklow
	
main:
	if (pat1 & trig) > 0 then
		dac1v = 4095
		vol1 = val1(stp - 1)
		dac2v = vol1
	endif

	if (pat2 & trig) > 0 then
		dac3v = 4095
		vol2 = val2(stp - 1)
		dac4v = vol2
	endif
	
	do	; Wait for clock to go high
		gosub scanadc
		button bstop,1,0,0,bvar,1,waitstart
	while adc1v < 512

	; Clock is now high.	
	gosub loadalldacs
	if patchg = 1 then	; Flash the STOP LED if pattern is due to change.
		high stopled
	  else
	  	low stopled
	endif
	if stp = 1 then		; If this is the first step in the pattern
		high aux		; set AUX output high and light the RUN LED.
		high runled
		pmutate = random pmseed		;Decide if the pattern should mutate.
		pmseed = pmutate
	endif
	
	; Prepare for clock to go low.
	dac1v = 0
	dac2v = vol1
	dac3v = 0
	dac4v = vol2

clocklow:	
	do	; Wait for clock to go low.
		gosub scanadc
		if (pmutate & 1023) < adc2v then	;Check the mutation variable against the mutation probability.
			patchg = 1
		else
			patchg = 0
		endif
		button bstop,1,0,0,bvar,1,waitstart
	while adc1v > 512
	
	; Clock is now low.
	gosub loadalldacs
	low aux
	low runled
	low stopled

	stp = stp + 1
	trig = trig * 2

	if stp > stpmax then
		stp = 1
		trig = 1
		stpmax = 16 - (adc4v / 64)

		if patchg = 1 then
			vcount = adc3v / 64
			gosub newpat
			patchg = 0
		endif
	endif

	goto main

end


newpat:
	for i = 0 to vcount
		; Change rhythm pattern 1
		n = n1
		rand = random n
		n1 = rand
		rand = rand // stpmax
		patbit = 1
		while rand > 0
			patbit = patbit * 2
			rand = rand - 1
		wend
		pat1 = pat1 ^ patbit

		;Change rhythm pattern 2
		n = n2
		rand = random n
		n2 = rand
		rand = rand // stpmax
		patbit = 1
		while rand > 0
			patbit = patbit * 2
			rand = rand - 1
		wend
		pat2 = pat2 ^ patbit
	
		; Change voltage pattern 1
		n = n3
		rand = random n
		n3 = rand
		val1(vpoint) = (n3 & 0x003f) * 32

		; Change voltage pattern 2
		n = n4
		rand = random n
		n4 = rand
		val2(vpoint) = (n4 & 0x003f) * 32

		vpoint = (vpoint + 1) // stpmax
	next
	return
	
rng:
	rand = (13709 * n + 13849) & 0xffff
	return
	
'*******************************************************************
'************************** SUBROUTINES ****************************
' by Grant Richter of Wiard Synthesizer Company as of 17 Jan 2004
'                 ALL FOUR channels are touched 
'*******************************************************************

resetdac:
	dac1v = 0
	dac2v = 0
	dac3v = 0
	dac4v = 0
	gosub loadalldacs
	return
	
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
