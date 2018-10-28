;* -----
;
; 	Copper List example program
;
;					----- *


	opt l-,o+,CHKIMM


; ___ Defines _____________________________________________


OLDSCHOOL_DEMO			
;VERY_OLDSCHOOL_DEMO	; WARNING: 15khz only !
SYSTEM_TAKEOVER		; Either Forbid or high-prio task

OCS_PALETTE
TOCOPPER

CIAAPRA 	= $bfe001


	SECTION main,code		

; ___ Includes ____________________________________________


	include "types.i"
	include "exec/types.i"
	include "exec/exec_lib.i"
	include "graphics/graphics_lib.i"
	include "graphics/gfxbase.i"
	include "hardware/custom.i"
	IFD OLDSCHOOL_DEMO
	include "OldSchoolMacros.i"
	ENDC

; ___ Main Code ___________________________________________

	ALIGN 	4
start:	movem.l	d1-d7/a1-a6,-(sp)

	lea	gSystem(pc),a4
	move.l	4.w,a6

	IFD SYSTEM_TAKEOVER
	IFND OLDSCHOOL_DEMO
	 sub.l	a1,a1
	 CALL	FindTask(a6)
	 move.l	d0,a1
	 moveq	#15,d0
	 CALL	SetTaskPri(a6)
	ELSE
	 CALL	Forbid(a6)
	ENDC
	ENDC

	GETVBR			; VBR returned in a1
	move.l	a1,(a4)		; 0(a4) = m_VBR
		
	lea	GfxName(pc),a1
	moveq	#LIBRARY_MINIMUM,d0
	CALL	OpenLibrary(a6)
	move.l	d0,m_GfxBase(a4)	
	beq.w	.end
	
	move.w	#$03e0,dmacon(a5)
	IFND VERY_OLDSCHOOL_DEMO
	 move.l	d0,a6
	 move.l	gb_ActiView(a6),m_WbView(a4)
	 sub.l	a1,a1
	 CALL	LoadView(a6)		; Init. view (clean AGA setup)
	 CALL	WaitTOF(a6)		; Wait two vbl in case we switch
	 CALL	WaitTOF(a6)		; to an interlace or 30khz+ mode
	 move.l	$4.w,a6
	ENDC

	lea 	$dff000,a5
;	bra.s	.main		; or use XREF/XDEF ?
	
; ___ Main Entry : (a4-a5) should not be trashed until Exit  ________

.main	
	lea	planes+2,a0
	move.l	#image,d0
	moveq	#2,d1
.setptr	move.w	d0,4(a0)
	swap	d0
	move.w	d0,(a0)
	addq	#8,a0
	swap	d0
	add.l	#40*256,d0
	dbf.w	d1,.setptr

	move.w	#$03e0,dmacon(a5)		
	move.l	#BasicCopperList,cop1lc(a5)
	move.w	#0,copjmp1(a5)

	move.w	#$8380,dmacon(a5)	; Set + DmaEn + BplEn + CopEn 
	
	moveq	#16,d7
.mainloop		
.reloop	cmp.b	#$ff,$dff006.L ; DEBUG
	bne.s	.reloop	

	move.w	#$f00,color(a5) ; DEBUG
	tst.l	d7
	beq.s	.waitclick
	moveq	#(image2.numcol/8)-1,d0
	lea	image2.couleurs(pc),a1	; targets	
	lea	palette,a0		; copper color to fade
	lea	.fadein(pc),a6
	;jmp	CrossFade(pc)
.fadein	subq	#1,d7
.waitclick	
	move.w	#$0,color(a5) ; DEBUG	
	
	btst	#6,CIAAPRA
	bne.w	.mainloop
	
;	bra.s	.exit

	moveq	#16,d7
.exitloop
	cmp.b	#$ff,$dff006.L ; DEBUG
	bne.s	.exitloop
	;WAITVBL
	;move.w	#$f00,color(a5) ; DEBUG
	;tst.l	d7
	;beq.s	.waitclick
	moveq	#(image2.numcol/8)-1,d0
	lea	fadetoblack(pc),a1	; targets	
	lea	palette,a0		; copper color to fade
	;addq.l	#4,a1 ; DEBUG
	;addq.l	#4,a0 ; DEBUG
	lea	.fadeout(pc),a6
	jmp	CrossFade(pc)
.fadeout
	dbf	d7,.exitloop	
	
; ___ Exit Application: (a4-a5) should have been preserved __________	
	
.exit	move.l	m_GfxBase(a4),a6
	IFND VERY_OLDSCHOOL_DEMO
	 move.l	m_WbView(a4),a1
	 CALL	LoadView(a6)
	 CALL	WaitTOF(a6)		
	 CALL	WaitTOF(a6)
	ENDC
	move.w	#$03ff,dmacon(a5)			
	move.l	gb_copinit(a6),cop1lc(a5)	
	move.w	#0,copjmp1(a5)
	move.w	#$83e0,dmacon(a5)	; re-enable everything

	move.l	a6,a1
	move.l	$4.w,a6
	CALL	CloseLibrary(a6)
	
	IFD SYSTEM_TAKEOVER & OLDSCHOOL_DEMO
	 CALL	Permit(a6)
	ENDC

.end: 	movem.l (sp)+,d1-d7/a1-a6
	moveq	#0,d0
	rts

	ALIGN	4
	VBRTRAP		; exception code 


; TEMP External Code TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP TEMP

	include "crossfade2.s"

 
; ___ PC-Relative Data ______________________________________________

        ALIGN	4	
gSystem	ds.b	sizeof_System
	
GfxName	dc.b 	"graphics.library",0
        EVEN

image2.couleurs
	dc.w	$0180,$0000,$0182,$0dd6,$0184,$0db4,$0186,$0400
	dc.w	$0188,$0740,$018a,$0a70,$018c,$0c92,$018e,$0b80
image2.numcol = *-image2.couleurs

fadetoblack
;	dc.w	$0180,$0,$0182,$0,$0184,$0,$0186,$0
;	dc.w	$0188,$0,$018a,$0,$018c,$0,$018e,$0
	dc.w	$0180,$0fff,$0182,$0fff,$0184,$0fff,$0186,$0fff
	dc.w	$0188,$0fff,$018a,$0fff,$018c,$0fff,$018e,$0fff

	
; ___ Put all data below ____________________________________________
	
	SECTION copperlist,data_c
	
	ALIGN	4				
BasicCopperList:
	dc.w	$0106,$0c00,$01fc,$0 ; bplcon3, fmode
	dc.w 	$0100,$3200 ; bplcon0
	dc.w	bplcon1,0,bplcon2,0
	dc.w	bpl1mod,0,bpl2mod,0
	dc.w	beamcon0,$20
	
planes	dc.w	bplpt,0,bplpt+2,0
	dc.w	bplpt+4,0,bplpt+6,0
	dc.w	bplpt+8,0,bplpt+$a,0
	dc.w	bplpt+$c,0,bplpt+$e,0
	dc.w	bplpt+$10,0,bplpt+$12,0
	
	dc.w	diwstrt,$2981,diwstop,$29c1
	dc.w	ddfstrt,$0038,ddfstop,$00d0

palette	;include	"image2.couleurs"
;	dc.w	$0180,$0fff,$0182,$0fff,$0184,$0fff,$0186,$0fff
;	dc.w	$0188,$0fff,$018a,$0fff,$018c,$0fff,$018e,$0fff
	dc.w	$0180,$0000,$0182,$0dd6,$0184,$0db4,$0186,$0400
	dc.w	$0188,$0740,$018a,$0a70,$018c,$0c92,$018e,$0b80
	
SpritePointers1: 
	dc.l 	$01200000,$01220000,$01240000,$01260000
;	dc.l	$01280000,$012a0000,$012c0000,$012e0000
;	dc.l	$01300000,$01320000,$01340000,$01360000 
;	dc.l 	$01380000,$013a0000,$013c0000,$013e0000	

	dc.w 	$fffe,$fffe
	dc.w 	$ffff,$fffe								

	ALIGN	4
image	incbin	"data/image2.raw"	


	end