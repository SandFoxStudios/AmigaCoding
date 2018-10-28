
;start	lea	color(pc),a0
;	lea	input(pc),a1
;.copy	move.l	(a0)+,(a1)+
	;move.l	(a0)+,(a1)+
	;move.l	(a0)+,(a1)+
	;move.l	(a0)+,(a1)+
	
	
;	lea	-16(a0),a0	; output
;	lea	outputok(pc),a6
;	jmp	FadeOutBW(pc)

;outputok
;	moveq	#3,d0
;	lea	output(pc),a0	; output
;	lea	input(pc),a1
;	lea	inputok(pc),a6
;	jmp	CrossFade(pc)
;inputok
;	rts

OCS_PALETTE
;TOWHITE

	IFD OCS_PALETTE
FADEMASK	equ $f
FADESHIFT	equ 4
FADEGRADIENT	equ $0f	 	; OCS/ECS - 16 possible gradients
	ELSE
FADEMASK 	equ $ff
FADESHIFT	equ 8	
FADEGRADIENT	equ $ff		; AGA/RTG - 256   "" 	   ""
	ENDC


FadeOutBW:	; d0-d7/a0-a2
	IFD TOWHITE
	 move.l	#$0f,d0
	ELSE
	 moveq	#FADEMASK,d0
	ENDC
	moveq	#$01,d3 	; Lerp Red component first	
	IFND OCS_PALETTE
	 swap	d0
	 swap	d3
	ELSE
	 lsl.w 	#8,d0
	 lsl.w	#8,d3
	ENDC
	moveq	#2,d5		; then Green & Blue components

.fadetoBW
	IFD OCS_PALETTE
	 moveq	#$0e,d6	 	; OCS/ECS - 16 possible gradients
	ELSE
	 move.w	#$fe,d6		; AGA/RTG - 256 ...
	ENDC
	
.fadeBW	moveq	#3,d7		; numcolors = PARAM
	move.l	a0,a2
	IFD TOCOPPER	
	addq	#2,a2
	ENDC

.innrBW	
	IFND OCS_PALETTE
	 move.l	(a2),d1
	 move.l	d1,d2
	 and.l	d0,d2
	ELSE
	 move.w (a2),d1
	 move.w	d1,d2
	 and.w	d0,d2
	ENDC
	IFD TOWHITE
	 cmp.l	d0,d2		; TOZERO doesn't need compare (and.l flags Z IFEQ)
	ENDC
	beq.s	.nextBW
	
	IFD TOWHITE
	 add.l	d3,d1
	ELSE
	 sub.w	d3,d1 ; OCS
	ENDC
.nextBW	move.w	d1,(a2)+ ; OCS
	IFD TOCOPPER	
	 addq	#FADESHIFT,a2
	ENDC
			
	dbf.w	d7,.innrBW
	dbf.w	d6,.fadeBW
	lsr.w	#FADESHIFT,d0 ; OCS
	lsr.w	#FADESHIFT,d3 ; OCS
	
	dbf.w	d5,.fadetoBW			
	jmp	(a6)
	; rts

;
; a0 - Fade Source, a1 - Fade Dest, d0 - Num Colors (trashed), a6 - Return Address
;
CrossFade:	
	movem.l	d1-d6,-(sp) ;/a0-a3,-(sp)
	;move.w	#FADEGRADIENT-1,d7
	
.xfade	move.l	d0,d6		; D0 = num. colors 
	move.l	a0,a2		; colors
	move.l	a1,a3		; targets
	IFD TOCOPPER	
	addq	#2,a2
	addq	#2,a3
	ENDC

.xfadeRGB
	moveq.l	#FADEMASK,d0
	moveq	#$01,d3 	; Lerp blue component first...	
	moveq	#2,d5		; ...then green & red components
.xfadeInner	
	IFND OCS_PALETTE
	 move.l	(a3),d1
	 move.l	(a2),d2
	ELSE
	 move.w	(a3),d1
	 move.w	(a2),d2
	ENDC
	and.l	d0,d1
	move.l	d3,d4
	and.l	d0,d2
	lsl.l	#FADESHIFT,d3	; shift color mask
	cmp.l	d1,d2
	beq.s	.xfadeNext
	blo.s	.xfadeLerp
	neg.l	d4
.xfadeLerp	
	IFND OCS_PALETTE
	 add.l	d4,(a2)
	ELSE
	 add.w	d4,(a2)	
	ENDC
.xfadeNext	
	lsl.l	#FADESHIFT,d0
	dbf.w	d5,.xfadeInner		
	IFND TOCOPPER	
	addq	#FADESHIFT/2,a3
	addq	#FADESHIFT/2,a2
	ELSE
	addq	#FADESHIFT,a3
	addq	#FADESHIFT,a2
	ENDC			
	dbf.w	d6,.xfadeRGB
	;dbf.w	d7,.xfade
	movem.l	(sp)+,d1-d6 ;/a0-a3		
	jmp	(a6)
	; rts


;	CNOP 0,4
;	IFND OCS_PALETTE
;color	dc.l 	0,$0f0f0f,$0A0208,$0A0801
;output	dc.l	$0f0f0f,$0A0208,$080A02,0
;	ELSE
;color	dc.w 	0,$0fff,$0A28,$0A81
;output	dc.w	$0fff,$0A28,$08A2,0
;	ENDC
;input	dc.l	0,0,0,0
;input	dc.l	$0fffffff,-1,-1,-1
;
;	end