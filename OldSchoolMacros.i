

	IFND OLDSCHOOL_MACROS_I
		OLDSCHOOL_MACROS_I: SET 1


; ___ Defines _______________________________________________________

bVblInterrupt	EQU	5
bBlitterReady 	EQU 	6

; ___ Oldschool macros ______________________________________________	
	
; -------
; WARNING : a5 is assumed to be set to $dff000
; -------	
	
WAITVBL	MACRO
.wvbl\@	btst 	#bVblInterrupt,intreqr(a5)
	beq.s	.wvbl\@
	ENDM

WAITRASTER MACRO		; d1 - vertical position to wait for
.wrst\@	move.l	vposr(a5),d0
	and.l	#$1ff00,d0
	cmp.l	d1,d0
	bne.s	.wrst\@	
	ENDM	

WAITBLT	MACRO
	Btst	#bBlitterReady,dmaconr(a5)
.wblt\@	Btst	#bBlitterReady,dmaconr(a5)
	bne.s	.wblt\@
	ENDM
	
	
	ENDC	; OLDSCHOOL_MACROS_I