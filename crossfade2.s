
;TEST
;TOCOPPER

	IFD TEST
OCS_PALETTE
	ENDC

	IFD OCS_PALETTE
FADEMASK	equ $0f
FADESHIFT	equ 4
FADEGRADIENT	equ $0f	 	; OCS/ECS - 16 possible gradients
	ELSE
FADEMASK 	equ $ff
FADESHIFT	equ 8	
FADEGRADIENT	equ $ff		; AGA/RTG - 256   "" 	   ""
	ENDC

; *---
; 	Fade a source palette to a target palette (approx. linear)
; 			*** Two colors at a time version ***
; Trashed: a0 - Fade Source, a1 - Fade Dest, d0 - Num Colors, a6 - Rts  
;									---*
	IFD TEST
start:	 lea	output(pc),a1
	 lea	input(pc),a0
	 moveq	#15,d0
	ENDC
CrossFade:	
	movem.l	d1-d7,-(sp)

	;move.l	d0,d6		; D0 = num. colors 
	;move.l	a0,a2		; colors
	;move.l	a1,a3		; targets
	IFD TOCOPPER	
	 addq	#2,a0		; skip $0180 registers
	 addq	#2,a1
	ENDC

.xfadeRGB
	move.l	#$000f000f,d6	; masks two 12-bit colors	
.xfadeInner	
	IFND TOCOPPER
	 move.l	(a1),d4
	 move.l	(a0),d5
	ELSE
	 move.w	(a1),d4
	 move.w	(a0),d5
	 swap	d4
	 swap	d5
	 move.w	4(a1),d4
	 move.w 4(a0),d5
	ENDC
	;cmp.l	d4,d5
	;beq.w	.nextcolor	
	move.l	d4,d1		
	move.l	d5,d2
	and.l	d6,d1		; Lerp blue component first...
	and.l	d6,d2
	move.l	d2,d3
	sub.l	d1,d2	
.blueLerp	
	;IFND OCS_PALETTE ; TODO
	; add.l	d3,(a0)
	;ELSE
	 add.l	d2,d3	 
	 and.l	d6,d3 		
	 move.l	d3,d7 
	;ENDC
.green	move.l	#$00f000f0,d6
	move.l	d4,d1
	move.l	d5,d2
	and.l	d6,d1
	and.l	d6,d2
	move.l	d2,d3	
	sub.l	d1,d2
.greenLerp	
	;IFND OCS_PALETTE ; TODO
	; add.l	d3,(a0)
	;ELSE
	 add.l	d2,d3 
	 and.l	d6,d3
	 or.l	d3,d7 
	;ENDC
.red	move.l	#$0f000f00,d6
	move.l	d4,d1
	move.l	d5,d2
	and.l	d6,d1
	and.l	d6,d2	
	move.l	d2,d3	
	sub.l	d1,d2
.redLerp	
	;IFND OCS_PALETTE ; TODO
	; add.l	d3,(a0)
	;ELSE
	 add.l	d2,d3 	 
	 and.l	d6,d3	 		
	 or.l	d3,d7 	
	;ENDC
	IFND TOCOPPER
	 move.l	d7,(a0)
	ELSE
	 move.w	d7,(a0)
	 swap	d7
	 move.w	d7,4(a0)
	ENDC
.nextcolor
	IFND TOCOPPER	
	 addq	#FADESHIFT,a1
	 addq	#FADESHIFT,a0
	ELSE
	IFND TEST
	 addq	#FADESHIFT*2,a1
	 addq	#FADESHIFT*2,a0
	ENDC
	ENDC			
	dbf.w	d0,.xfadeRGB
	movem.l	(sp)+,d1-d7
	jmp	(a6)
	; rts

	IFD TEST
	IFND TOCOPPER
input	dc.l	$02f00000
output	dc.l	$0a4f0fff
	ELSE
input	dc.w	$180,$0,$182,$2f0
output	dc.w	$180,$fff,$182,$a4f
	ENDC
	ENDC