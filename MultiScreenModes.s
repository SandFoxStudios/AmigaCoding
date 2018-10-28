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

CIAAPRA 	= $bfe001
		
	
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

	SECTION main,code

	ALIGN 	4
get_on_up:
	movem.l	d1-d7/a1-a6,-(sp)

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
	beq.w	hit_it_n_quit
	
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
;	bra	.main

	
; ___ Main Entry : (a4-a5) should not be trashed until Exit  ________

.main	; insert movem here for fullproof-ness
  	
	move.l 	#BasicCopperList,cop1lc(a5)
	move.w	#$83a0,dmacon(a5)	; Set + DmaEn + BplEn +CopEn 
	;move.w	#0,copjmp1(a5)
	;move.w	#0,copjmp2(a5)
	
	move.l	#image,d0
	moveq	#2,d2
	move.l	#screen1+2,a0
	move.l	#screen2+2,a1
	move.l	#screen3+2,a2
	move.l	#screen4+2,a3
.screenSetup
	move.w	d0,4(a0)
	move.w	d0,4(a1)
	move.w	d0,4(a2)
	move.w	d0,4(a3)
	swap	d0
	move.w	d0,(a0)
	move.w	d0,(a1)
	move.w	d0,(a2)
	move.w	d0,(a3)
	swap	d0
	addq	#8,a0
	addq	#8,a1
	addq	#8,a2
	addq	#8,a3	
	add.l	#40*256,d0
	dbf	d2,.screenSetup

	move.l	#sprite2+2,a0
	move.l	#testSprite,d0
	move.w	d0,4(a0)
	swap	d0
	move.w	d0,(a0)
	
	move.l	#255*$4C-2,d1	; 76-2 scanlines	
	moveq	#0,d2		; raster counter
	moveq	#0,d3		; infinite scroll counter	
	move.w	#$ff,d7		; horizontal scroll counter
.mainloop
	tst.b	$06(a5)
	bne.s	.mainloop
;	move.w	#$fff,$180(a5)	; raster PROFILE_BEGIN
;.pal60	cmp.b	#$1e,$06(a5)
;	blo.s	.pal60

;
; raster effect
;	
	lea	BlueRst,a1	; inc. blue raster
	addq.w	#2,(a1)
	lea	GrnRst,a2	; inc. green raster
	addq.w	#2,(a2)
	lea	RedRst,a1	; inc. red raster
	addq.w	#2,(a1)
	;lea	Past255,a2	; inc. white raster
	;addq.w	#2,(a2)

.checkraster
	addq	#2,d2		; count
	cmp.l	d1,d2
	ble.s	.checkinfscroll

	moveq	#0,d2
	move.w	RedRst-8,RedRst
	move.w	GrnRst-8,GrnRst
	move.w	BlueRst-8,BlueRst

.checkinfscroll
	addq.w	#1,d3
	moveq	#2,d6
	move.l	#image,d5
	move.l	#screen1+2,a0
	and.w	#$FF,d3
	beq.s	.updateinfscroll	
	move.w	(a0),d4
	swap	d4
	move.w	4(a0),d4
	add.l	#40,d4
	move.l	d4,d5	
.updateinfscroll
	move.w	d5,4(a0)
	swap	d5
	move.w	d5,(a0)
	swap	d5
	add.l	#40*256,d5
	addq	#8,a0
	dbf.w	d6,.updateinfscroll	

.hScroll
	sub.w	#$11,d7
	cmp.w	#-$11,d7
	bgt.s	.dohscroll
	move.w	#$ff,d7
	move.l	#screen4+6,a1
	addq.w	#2,(a1)
	addq.w	#2,8(a1)	
	addq.w	#2,16(a1)
.dohscroll
	move.l	#screen4+26,a0	
	;move.l	d7,d5
	;lsr.w	#2,d5
	;and.w	#$fff0,d5
	;not.b	d5
	;move.l 	d5,d4
	;and.l	#$fff0,d5
	;sub.l	d5,d4
	move.w	d7,(a0)
	
.testclick
;	move.w	#0,$180(a5)	; raster PROFILE_END
	btst	#6,CIAAPRA
	bne.w	.mainloop	
;	bra	.exit
	
	
; ___ Exit Application: (a4-a5) should have been preserved __________	
	
.exit	; insert movem here for fullproof-ness

	move.l	m_GfxBase(a4),a6
	IFND VERY_OLDSCHOOL_DEMO
	 move.l	m_WbView(a4),a1
	 CALL	LoadView(a6)
	 CALL	WaitTOF(a6)		
	 CALL	WaitTOF(a6)
	ENDC
	;move.w	#$03ff,dmacon(a5)				
	move.l	gb_copinit(a6),cop1lc(a5)	
	;move.w	#$83e0,dmacon(a5)	; re-enable everything

	move.l	a6,a1
	move.l	$4.w,a6
	CALL	CloseLibrary(a6)
	
	IFD SYSTEM_TAKEOVER & OLDSCHOOL_DEMO
	 CALL	Permit(a6)
	ENDC

hit_it_n_quit:
 	movem.l (sp)+,d1-d7/a1-a6
	moveq	#0,d0
	rts

	ALIGN	4
	VBRTRAP		; exception code 

 
; ___ PC-Relative Data ______________________________________________

        ALIGN	4	
gSystem	ds.b	sizeof_System
	
GfxName	dc.b 	"graphics.library",0
        EVEN
        
; ___ Put all CHIP data below _______________________________________

	SECTION copperlist,data_c
	
	ALIGN	4			
BasicCopperList:
	dc.w	$0106,$0c00,$01fc,$0,$01dc,$20
	dc.w	sprpt,0,sprpt+2,0,sprpt+4,0,sprpt+6,0
	dc.w	sprpt+8,0,sprpt+10,0,sprpt+12,0,sprpt+14,0
	dc.w	sprpt+16,0,sprpt+18,0,sprpt+20,0,sprpt+22,0
	dc.w	sprpt+24,0,sprpt+26,0,sprpt+28,0,sprpt+30,0
	dc.w	$0100,$0,$0102,0,$104,0

	dc.w	$0180,$0000,$0182,$0dd6,$0184,$0db4,$0186,$0400
	dc.w	$0188,$0740,$018a,$0a70,$018c,$0c92,$018e,$0b80

	dc.w	bplpt,0,bplpt+2,0
	dc.w	bplpt+4,0,bplpt+6,0
	dc.w	bplpt+8,0,bplpt+10,0
	dc.w	bpl1mod,0,bpl2mod,0
	dc.w	diwstrt,$2a81,diwstop,$2ac1
	dc.w	ddfstrt,$0038,ddfstop,$00d0

	dc.w	$1b07,$fffe
	dc.w 	$0100,$3200	; LOWRES
screen1	dc.w	bplpt,0,bplpt+2,0
	dc.w	bplpt+4,0,bplpt+6,0
	dc.w	bplpt+8,0,bplpt+10,0
	dc.w 	color,$00f
BlueRst	dc.w	$1c07,$fffe	; blue raster position
	dc.w 	color,$ccc
	
	dc.w	$6607,$fffe	; 1 scanline interval
	dc.w	color,$0
	dc.w 	$0100,$0	; reset display
	dc.w	bplpt,0,bplpt+2,0
	dc.w	bplpt+4,0,bplpt+6,0
	dc.w	bplpt+8,0,bplpt+10,0
	dc.w	ddfstrt,$003c,ddfstop,$00d4
	
	dc.w	$6701,$fffe
	dc.w 	$0100,$b200	; HIRES
screen2	dc.w	bplpt,0,bplpt+2,0
	dc.w	bplpt+4,0,bplpt+6,0
	dc.w	bplpt+8,0,bplpt+10,0
	dc.w	color,$0f0
sprite2	dc.w	sprpt,0,sprpt+2,0
	
GrnRst	dc.w	$6807,$fffe	; green raster position
	dc.w	color,$aaa
	
	dc.w	$b207,$fffe	; 1 scanline interval
	dc.w	color,$0
	dc.w 	$0100,$0	; reset display
	dc.w	bplpt,0,bplpt+2,0
	dc.w	bplpt+4,0,bplpt+6,0
	dc.w	bplpt+8,0,bplpt+10,0
	dc.w	ddfstrt,$0038,ddfstop,$00d0

	dc.w	$b307,$fffe
	dc.w 	$0100,$3204	; LACED LOWRES 
screen3	dc.w	bplpt,0,bplpt+2,0
	dc.w	bplpt+4,0,bplpt+6,0
	dc.w	bplpt+8,0,bplpt+10,0
	dc.w	bpl1mod,40,bpl2mod,40
	dc.w	color,$f00	
RedRst	dc.w	$b407,$fffe	; red raster position
	dc.w	color,$777	
	
	dc.w 	$ff07,$fffe	; 1 scanline interval
	dc.w	color,$0
	dc.w 	$0100,$0	; reset display
	dc.w	bplpt,0,bplpt+2,0
	dc.w	bplpt+4,0,bplpt+6,0
	dc.w	bplpt+8,0,bplpt+10,0
	dc.w	ddfstrt,$0038,ddfstop,$00d0

	dc.w	$ffe1,$fffe	; draw past 255th scanline (PAL)	
	dc.w 	$0100,$b204	; LACED HIRES
screen4	dc.w	bplpt,0,bplpt+2,0 
	dc.w	bplpt+4,0,bplpt+6,0
	dc.w	bplpt+8,0,bplpt+10,0
	dc.w	bplcon1,0
	dc.w	bpl1mod,80,bpl2mod,80

	dc.w	color,$fff
Past255	dc.w	$0007,$fffe
	dc.w	color,$555

	dc.w 	$ffff,$fffe	; Nothing is impossible to the Copper...	
	dc.w 	$ffff,$fffe	; ...well except unreachable raster position							

	ALIGN	4
image	incbin	"data/image2.raw"	


testSprite
	dc.w	$a05a,$a800
	dc.w	%0000 0000 0000 0000,%0000 0011 1100 0000
	dc.w	%0000 0000 0000 0000,%0000 1100 0011 0000
	dc.w	%0000 0001 1000 0000,%0001 1001 1001 1000
	dc.w	%0000 0011 1100 0000,%0001 1010 0010 1100
	dc.w	%0000 0011 1100 0000,%0011 0010 0010 1100
	dc.w	%0000 0001 1000 0000,%0001 1001 1001 1000
	dc.w	%0000 0000 0000 0000,%0000 1100 0011 0000
	dc.w	%0000 0000 0000 0000,%0000 0011 1100 0000
	dc.w 	0,0
	
	end