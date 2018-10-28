;
;
;

	IFND ENGINE_AMIGA_TYPES_I
		ENGINE_AMIGA_TYPES_I: SET 1

; ___ Basic Types ___________________________________________________

false	equ	0
true	equ	1


; ___ Global Structures (a4) ________________________________________

	rsreset
m_VBR		rs.l	1
m_SysIntLevel3	rs.l	1
m_WbView 	rs.l	1
m_GfxBase	rs.l	1
m_OldIntena	rs.w	1
m_OldDmacon	rs.w	1
sizeof_System	rs.b	0

	
; ___ Macros ________________________________________________________
	
	IFND LIBRARY_MINIMUM
LIBRARY_MINIMUM equ 33		; Kickstart 1.2
	ENDC

;* ---
;	Library Call. 
;	Optional param \2 is supposed to be the base pointer.
;								--- *;
CALL	MACRO
	IFNC '','\2'
		movea.l	\2,a6
		jsr	_LVO\1(a6)
	ELSE
		jsr	_LVO\1
	ENDC
	ENDM

ALIGN 	MACRO
	cnop	0,\1
	ENDM


; Memory Allocation : \1=Pointer \2=Size_in_Bytes		
	
	
ALLOC_CHIPMEM MACRO	
	move.l	#\2,d0
	moveq	#MEMF_CHIP,d1
	CALL	AllocMem(a6)	
	move.l	d0,\1
	ENDM
	
ALLOC_FASTMEM MACRO
	move.l	#\2,d0
	moveq	#MEMF_ANY,d1	; use MEMF_FAST if really required
	CALL	AllocMem(a6)	
	move.l	d0,\1
	ENDM

FREE_MEM MACRO
	move.l	\1,a1
	move.l	#\2,d0
	CALL 	FreeMem(a6)
	ENDM


; Stores Vector Base Register location in a1 (in fast-ram if 68010+)
; Trashes a5. a6 is supposed to be loaded with $4.w as usual.

GETVBR 	MACRO	
	suba.l	a1,a1
	btst	#0,$129(a6)	; (AttnFlags + 1)
	beq.s	.vbrdone	; taken if 68000
	lea	SuperCode(pc),a5
	CALL	Supervisor(a6)
.vbrdone
	ENDM
	
VBRTRAP	MACRO
	ALIGN	4
SuperCode:
	dc.l 	$4e7a9801	; movec.l VBR,a1
	;dc.l 	$4e7a0801	; movec.l VBR,d0
	rte
	ENDM	
	
	
	ENDC	; ENGINE_AMIGA_TYPES_I