
TEST

	IFD TEST
OCS_PALETTE
	ENDC

	IFD OCS_PALETTE
FADEMASK	equ $f
FADESHIFT	equ 4
FADEGRADIENT	equ $0f	 	; OCS/ECS - 16 possible gradients
	ELSE
FADEMASK 	equ $ff
FADESHIFT	equ 8	
FADEGRADIENT	equ $ff		; AGA/RTG - 256   "" 	   ""
	ENDC


;
; a0 - Fade Source, a1 - Fade Dest, d0 - Num Colors (trashed), a6 - Return Address
;
	IFD TEST
	lea	output(pc),a1
	lea	input(pc),a0
	moveq	#15,d0
	ENDC
CrossFade:	
	movem.l	d1-d7,-(sp) ;/a0-a3,-(sp)
	;move.w	#FADEGRADIENT-1,d7	
;.xfade	
	move.l	d0,d6		; D0 = num. colors 
	move.l	a0,a2		; colors
	move.l	a1,a3		; targets
	moveq	#0,d4
	move.l	d4,d5

	IFND TEST
	IFD TOCOPPER	
	 addq	#2,a2
	 addq	#2,a3
	ENDC
	ENDC

.xfadeRGB
	moveq	#FADEMASK,d0	
	moveq	#0,d7
.xfadeInner	
	IFND OCS_PALETTE
	 move.l	(a3),d4
	 move.l	(a2),d5
	ELSE
	 move.w	(a3),d4
	 move.w	(a2),d5
	ENDC
	;cmp.l	d4,d5
	;beq.w	.nextcolor	
	move.l	d4,d1
	move.l	d5,d2
	and.l	d0,d1
	;moveq	#$01,d3 	; Lerp blue component first...
	and.l	d0,d2
	move.w	d2,d3
	sub.l	d1,d2
	;beq.s	.green
	;blo.s	.blueLerp
	;neg.l	d3
.blueLerp	
	IFND OCS_PALETTE ; TODO
	; add.l	d3,(a2)
	ELSE
	 add.w	d2,d3
	 and.w	d0,d3 		
	 move.w	d3,d7 ;(a2)
	ENDC
.green	move.l	#$f0,d0
	move.l	d4,d1
	move.l	d5,d2
	and.l	d0,d1
	;moveq	#$10,d3
	and.l	d0,d2
	move.w	d2,d3	
	sub.l	d1,d2
	;beq.s	.red
	;blo.s	.greenLerp
	;neg.l	d3
.greenLerp	
	IFND OCS_PALETTE ; TODO
	; add.l	d3,(a2)
	ELSE
	 add.w	d2,d3
	 and.w	d0,d3	 		
	 or.w	d3,d7 ;(a2)
	ENDC
.red	move.l	#$f00,d0
	move.l	d4,d1
	move.l	d5,d2
	and.l	d0,d1
	;move.l	#$100,d3
	and.l	d0,d2
	move.w	d2,d3	
	sub.l	d1,d2
	;beq.s	.nextcolor
	;blo.s	.redLerp
	;neg.l	d3
.redLerp	
	IFND OCS_PALETTE ; TODO
	; add.l	d3,(a2)
	ELSE
	 add.w	d2,d3	 
	 and.w	d0,d3	 		
	 or.w	d3,d7 ;(a2)
	
	ENDC
	move.w	d7,(a2); was add
.nextcolor
	;lsl.l	#FADESHIFT,d0
	;dbf.w	d5,.xfadeInner		
	
	IFND TOCOPPER	
	;addq	#FADESHIFT/2,a3
	;addq	#FADESHIFT/2,a2
	ELSE
	 addq	#FADESHIFT,a3
	 addq	#FADESHIFT,a2
	ENDC			
	dbf.w	d6,.xfadeRGB
	;dbf.w	d7,.xfade
	movem.l	(sp)+,d1-d7 ;/a0-a3		
	jmp	(a6)
	; rts

	IFD TEST
input	dc.l	$02f00000
output	dc.l	$0a4f0fff
	ENDC