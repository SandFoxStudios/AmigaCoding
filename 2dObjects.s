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
	 ;todo: save old copper list
	 sub.l	a1,a1
	 CALL	LoadView(a6)		; Init. view (clean AGA setup)
	 CALL	WaitTOF(a6)		; Wait two vbl in case we switch
	 CALL	WaitTOF(a6)		; to an interlace or 30khz+ mode
	ENDC

	lea 	$dff000,a5
	
	;
	; setup at least a VBL interrupt
	;
	move.w	$02(a5),m_OldDmacon(a4)
	or.w	#$c000,m_OldDmacon(a4)
	;todo: save intreq as well (and adkcon ?)
	move.w	$01c(a5),m_OldIntena(a4)
	or.w	#$c000,m_OldIntena(a4)
	move.w	#$7fff,d0
	move.w	d0,dmacon(a5)
	move.w	d0,intena(a5)
	
   	move.l	(a4),a1			; VBR in a1
	move.l	$6c(a1),m_SysIntLevel3(a4)
	lea	intCode.Level3(pc),a0
	move.l	a0,$6c(a1)
		
;	bra	.main

	
; ___ Main Entry : (a4-a5) should not be trashed until Exit  ________

main:	; insert movem here for fullproof-ness
  	
	move.l #BasicCopperList,cop1lc(a5)
	move.w	#$83c0,dmacon(a5)	; Set + DmaEn + BplEn + CopEn + BltEn 

	lea	bitplan+2,a0
	move.l	#backbuffer,d0
	move.w	d0,4(a0)
	swap	d0
	move.w	d0,(a0)
	
	bsr.w	GenerateGrid
	
	move.w	#$c020,intena(a5)	; vbl interrupt
	
	moveq	#0,d6
.mainloop
	tst.b	$06(a5)
	bne.s	.mainloop
	;move.l	#$12000,d1
	;WAITRASTER
	
.pal60	cmp.b	#$1f,$06(a5)
	bne.s	.pal60

	;lea	backbuffer,a0
	;bsr.w	ClearScreenDirty
		
		
.testclick
	btst	#6,CIAAPRA
	bne.w	.mainloop	
;	bra.w	exit

; ___ Exit Application: (a4-a5) should have been preserved __________	
	
exit:	; insert movems here for fullproof-ness

	WAITBLT
	move.l	#$12000,d1
	WAITRASTER

	; restore system interrupts
	move.w	#$7fff,d0
	move.w	d0,dmacon(a5)
	move.w	d0,intena(a5)
		
	move.l	(a4),a1			; m_VBR
	move.l	m_SysIntLevel3(a4),$6c(a1)
	
	move.w	m_OldDmacon(a4),$096(a5)
	move.w	m_OldIntena(a4),$09a(a5)
					
	move.l	gb_copinit(a6),cop1lc(a5)
	move.l	m_GfxBase(a4),a6
	IFND VERY_OLDSCHOOL_DEMO
	 move.l	m_WbView(a4),a1
	 CALL	LoadView(a6)
	 CALL	WaitTOF(a6)		
	 CALL	WaitTOF(a6)
	ENDC
	
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

; ---
	;ALIGN	4
	VBRTRAP		; exception code



; ___ Remember NOT to trash a4/a5 ___________________________________


	ALIGN	4
intCode.Level3	
	movem.l	d0-d7/a0-a6,-(sp)
	lea	$dff000,a5
	andi.w	#$0020,intreqr(a5)
	beq.s	.noint

	move.w	#$0,$180(a5)	; raster PROFILE_BEGIN

	move.l	frame.cpt(pc),d0
	bsr.w	TransformObject
	move.w	#$f00,$180(a5)
	;move.l	a0,bplpt(a5)	; set 
	lea	backbuffer,a0
	bsr.w	ClearScreenDirty
	WAITBLT			; otherwise cpu/blitter data collision
	lea 	backbuffer,a0
	move.w	#$ff0,$180(a5)
	lea	rcube(pc),a1
	move.l	frame.cpt(pc),d0
	bsr.w	DrawQuadLine
	move.w	#$aaa,$180(a5)
.doint
	lea	frame.cpt(pc),a0
	move.l	(a0),d7
	addq.l	#8,d7
	move.l	d7,(a0)
	
	move.w	#$fff,color(a5)	; raster PROFILE_END
	move.w	#$0020,intreq(a5)
	move.w	#$0020,intreq(a5)
.noint	movem.l	(sp)+,d0-d7/a0-a6
	;moveq	#0,d0
	;rts
	rte


	ALIGN	4
;
; d0 - angle[0,1023]
;
TransformObject
	and.w	#$3ff,d0	; angle
	lea	cube(pc),a0
	add.w	d0,d0		; word offset
	lea 	sincos(pc),a1
	lea	rcube(pc),a2
	lea	centre(pc),a3
	move.w	(a1,d0.w),d1	; sin(angle)
	add.w	#2*256,d0
	moveq	#3,d7	; *** TEMP ***
	move.w	(a1,d0.w),d2	; cos(angle)
.rotz	move.w	d1,d3
	move.w	d2,d4
	move.w	d1,d5
	move.w	d2,d6

	;move.l	(a0)+,d0
	movem.w (a0)+,d3/d4
	;muls.w	d0,d3		; x*sin
	;muls.w	d0,d4		; x*cos
	
	;;muls.w	d0,d3
	;swap	d0
	;;muls.w	d1,d4
	
	;muls.w	d0,d5		; y*sin
	;muls.w	d0,d6		; y*cos
	;sub.l	d5,d4		; x*cos-y*sin
	;add.l	d6,d3		; x*sin+y*cos
	;lsr.l	#5,d4
	;lsr.l	#5,d3
	;lsr.l	#5,d4
	;lsr.l	#5,d3
	add.w	(a3),d3
	add.w	2(a3),d4
	;move.w	d3,(a2)+
	;move.w	d4,(a2)+
	
	dbf	d7,.rotz
	

	;lea 	rcube(pc),a0
	;move.w	scl.neg(pc),d0
	;move.w	scl.pos(pc),d1
	;add.w	d0,(a0)+
	;add.w	d0,(a0)+
	;add.w	d1,(a0)+
	;add.w	d0,(a0)+
	;add.w	d1,(a0)+
	;add.w	d1,(a0)+
	;add.w	d0,(a0)+
	;add.w	d1,(a0)+	
	
	;lea	scl.cpt(pc),a2
	;move.l	(a2),d2
	;addq.w	#1,d2
	;cmp.w	#64,d2
	;blo.s	.endtrs
	;lea	scl.neg(pc),a1
	;move.l	(a1),d1
	;swap	d1
	;moveq	#0,d2
	;move.l	d1,(a1)
.endtrs
	;move.l	d2,(a2)
	rts

	ALIGN	4
scl.cpt	dc.l	0
scl.neg	dc.w	-100
scl.pos	dc.w	100

GenerateGrid
	
	lea	grid(pc),a0
	move.w	#11,d0

	move.w	#12*12,(a0)+
	
	move.w	#-88,d2
.gridy	
	move.w	#11,d1
	move.w	#-88,d3
.gridx	move.w	d2,(a0)+
	move.w	d3,(a0)+
	add.w	#16,d3
	dbra	d1,.gridx
	
	add.w	#16,d2
	dbra	d0,.gridy

	rts

;
;	a0 - backbuffer, a1 - point list
;	todo: indices
DrawQuadLine
;	move.l	#$140,d7	; ref point count
	
	;lea	.pixel(pc),a1
	lea	grid(pc),a1
	move.w	(a1)+,d7
	subq	#1,d7
	lea	.mul40(pc),a2
	
	lea	sincos(pc),a3
	;moveq	#-$80,d4
	;move.w	#$0001,d7	; bitmask
	
	
	;move.w	d0,d4
	and.w	#$3ff,d0	; angle
	add.w	d0,d0
	move.w	(a3,d0.w),d5	; sin
	add.w	#2*256,d0
	move.w	(a3,d0.w),d6	; cos
	moveq	#10,d4		; fixed point divisor
	lea	centre(pc),a3
.plot2d
	;move.w	d4,d0
	;and.w	#$3ff,d0	; angle
	;add.w	d0,d0
	;move.w	(a3,d0.w),d5	; sin
	;add.w	#2*256,d0
	;move.w	(a3,d0.w),d6	; cos
	;add.w	d7,d4
	;and.w	#$3ff,d4
	
	move.w	(a1)+,d0
	move.w	(a1)+,d2
	move.w	d0,d1
	move.w	d2,d3
	;move.w	2(a1),d0	; radius
	;move.w	d0,d1
;.rotate	
	muls.w	d6,d0		; x*cos
	muls.w	d5,d1		; x*sin
	muls.w	d5,d2		; y*sin
	muls.w	d6,d3		; y*cos
	sub.l	d2,d0		
	add.l	d3,d1
	lsr.l	d4,d0
	lsr.l	d4,d1	
	;and.w	#255,d0		; guard band
	;and.w	#255,d1
	
	add.w	(a3),d0
	add.w	2(a3),d1
	
	move.w	d0,d2
	lsr.w	#3,d2		; (12) div8 addr en octets
	;;move.b	(a3,d2.w),d2	; (14)
	add.w	d1,d1		; (4)
	add.w	d1,d1		; (4) mul4
	add.w	d1,d1		; (4) mul8
	move.w	d1,d3		; (4)
	add.w	d1,d1		; (4) mul16
	add.w	d1,d1		; (4) mul32
	add.w	d3,d1		; (4) mul40 = 24cycl
;	move.w	(a2,d1.w),d1	; (14) = 18cycl+2*256bytes
	add.w	d2,d1
	not.b	d0
	bset.b	d0,(a0,d1.w)
	dbra	d7,.plot2d
	
;	lea	4000(a0),a0
;	jmp	.drLoop(pc,d1.w)
;.drLoop
; 	REPT 20
;	move.w	d7,(a0)+
;	ENDR
	
	;move.l	d7,d1
	;move.l	d7,d2
	;move.l	d7,d3
	;move.l	d7,d4
	;move.l	d7,d5
	;move.l	d7,d6
	;move.l	d7,d0
	;move.l	d7,a1
	;move.l	d7,a2
	;movem.l	d0-d7/a1-a2,(a0)
	
	rts
	
.pixel	dc.w 160,30

DUP8B	MACRO
	dc.b \1,\1,\1,\1,\1,\1,\1,\1
	ENDM

.div8	DUP8B 0
	DUP8B 1
	DUP8B 2
	DUP8B 3
	DUP8B 4
	DUP8B 5
	DUP8B 6
	DUP8B 7
	DUP8B 8
	DUP8B 9
	DUP8B 10
	DUP8B 11
	DUP8B 12
	DUP8B 13
	DUP8B 14
	DUP8B 15
	DUP8B 16
	DUP8B 17
	DUP8B 18
	DUP8B 19
	DUP8B 20
	DUP8B 21
	DUP8B 22
	DUP8B 23
	DUP8B 24
	DUP8B 25
	DUP8B 26
	DUP8B 27
	DUP8B 28
	DUP8B 29
	DUP8B 30
	DUP8B 31
	DUP8B 32
	DUP8B 33
	DUP8B 34
	DUP8B 35
	DUP8B 36
	DUP8B 37
	DUP8B 38
	DUP8B 39	
	DUP8B 40
	DUP8B 41
	DUP8B 42
	DUP8B 43
	DUP8B 44
	DUP8B 45
	DUP8B 46
	DUP8B 47
	DUP8B 48
	DUP8B 49
	 
WS 	equ 40
.mul40	dc.w 0*WS,1*WS,2*40,3*WS,4*40,5*WS,6*40,7*WS,8*40,9*WS
	dc.w 10*40,11*WS,12*40,13*WS,14*40,15*WS,16*40,17*WS,18*40,19*WS
	dc.w 20*40,21*WS,22*40,23*WS,24*40,25*WS,26*40,27*WS,28*40,29*WS
	dc.w 30*40,31*WS,32*40,33*WS,34*40,35*WS,36*40,37*WS,38*40,39*WS
	dc.w 40*40,41*WS,42*40,43*WS,44*40,45*WS,46*40,47*WS,48*40,49*WS
	dc.w 50*40,51*WS,52*40,53*WS,54*40,55*WS,56*40,57*WS,58*40,59*WS
	dc.w 60*40,61*WS,62*40,63*WS,64*40,65*WS,66*40,67*WS,68*40,69*WS
	dc.w 70*40,71*WS,72*40,73*WS,74*40,75*WS,76*40,77*WS,78*40,79*WS
	dc.w 80*40,81*WS,82*40,83*WS,84*40,85*WS,86*40,87*WS,88*40,89*WS
	dc.w 90*40,91*WS,92*40,93*WS,94*40,95*WS,96*40,97*WS,98*40,99*WS
	dc.w 100*40,101*WS,102*40,103*WS,104*40,105*WS,106*40,107*WS,108*40,109*WS

	moveq	#2,d7
	move.l	a0,a6
	move.l	a1,a3
.nxQline
	move.l	d7,-(sp)
	move.w	(a3)+,d0
	move.w	(a3)+,d1
	move.w	(a3),d2
	move.w	2(a3),d3
	;lea	.endDrawQuadLine(pc),a6
	bsr.w	DrawLine
;.endDrawQuadLine
	move.l	(sp)+,d7
	move.l	a6,a0
	dbf	d7,.nxQline
	
	move.w	(a3)+,d0
	move.w	(a3)+,d1
	move.w	-16(a3),d2
	move.w	-14(a3),d3
	;lea	.lastQline(pc),a6
	bsr.w	DrawLine
.lastQline
	rts
	
	ALIGN	4
cube	
grid	dc.w	4,-16,-16,16,-16,16,16,-16,16
;grid	;dc.w	1
	dcb.w	20*20
centre	dc.w	160,128
rcube	dc.w	0,0,319,0,319,255,0,255

;
;	d0-d3 - x1,y1/x2,y2	a0 - Backbuffer
;	trashes d0-d7/a0-a2
;
	ALIGN	4
DrawLine
	moveq	#$0028,d7 	; | 00 | +-40 |
.swapx	cmp.w	d0,d2	; which "x" is right-most ?
	bpl.s	.bresline
	exg	d1,d3	; we draw from left to right, swap p1,p2
	exg	d0,d2	
.bresline
	move.w	d2,d4
	move.w	d3,d5
	sub.w	d0,d4	; dx
	sub.w	d1,d5	; dy
	subx.w	d6,d6	; abs(dy)..
	move.l	d0,a1	; save x1	
	eor.w	d6,d5	; ...1-complement
	move.l	#$10000,d0 	; | 01 | 00 |	
	eor.w	d6,d7
	sub.w	d6,d5	; ...2-complement
	sub.w	d6,d7	; neg d7 if dy<0 (descending mode)

	cmp.w	d5,d4	; slope < 1 ?
	bpl.s	.nodswp
	exg	d4,d5	; else loop = dx	/d4 = dU
	exg	d0,d7	; | da1 | da0 |

.nodswp	move.w	d4,d6	; then loop = dy	/d5 = dV
	add.w	d5,d5	; 2*dV (dx or dy depending on slope)
	move.w	d1,d2		;
	;subq.w	#1,d6
	lsl.w	#5,d1		; p1.y *= 32
	move.w	d5,d3	; error1 
	lsl.w	#3,d2		; p1.y *= 8
	sub.w	d4,d5	; 2*dV-dU (start error value)
	add.w	d2,d1		; p1.y*40
	add.w	d4,d4	; 2*dU
	add.w	d1,a0		
	
	; a0 = start scanline, a1 = x1	
.lineloop	
	move.w	a1,d2	; get x1
	move.l	a0,a2
	lsr.w	#3,d2	; get byte's offset
	move.w	a1,d1
	add.w	d2,a2
	add.w	d0,a0	; y1+=da0'
	moveq	#7,d2
	swap	d0	
	and.w	d2,d1	; get the bit by...
	add.w	d0,a1	; x1+=da1'

	tst.w	d5	; if (error >= 0) error+=error2 else error+=error1
	bmi.s	.err1	
	add.w	d7,a0	; y1+=da0"
	swap	d7
	sub.w	d4,d5	; -2*dU (error2)
	add.w	d7,a1	; x1+=da1"
	swap	d7

.err1	
	sub.b	d1,d2	; ...swapping bit order
	add.w	d3,d5	; +2*dV
	bset	d2,(a2)	; plot 1-bitplane pixel
	swap	d0	
	dbf	d6,.lineloop
	;jmp	(a6)
	rts

; todo: setup a blitter interrupt and clear backbuffer while cpu is busy
; a0 - backbuffer
ClearScreenDirty
	move.l	m_GfxBase(a4),a6
	WAITBLT
	;CALL	OwnBlitter(a6)
	move.l	a0,bltdpt(a5)
	move.w	#0,bltdmod(a5)
	move.l	#-1,bltafwm(a5)
	move.w	#$0100,bltcon0(a5)	; useD
	move.w	#0,bltcon1(a5)
	;WAITBLT
	move.w	#(256*64)+20,bltsize(a5)
	;move.w	#20,bltsize(a5)
	;CALL	DisownBlitter(a6)
	rts
	
 
; ___ PC-Relative Data ______________________________________________

        ALIGN	4	
gSystem	ds.b	sizeof_System
	
GfxName	dc.b 	"graphics.library",0
        EVEN

; ----
; todo: create a frame structure with infos
; ----
frame.cpt 
	dc.l	0

	ALIGN	4
sincos	include	"sincostable1024.i"
        
; ___ Put all CHIP data below _______________________________________

	SECTION copperlist,data_c
	
	ALIGN	4			
BasicCopperList:
	dc.w	$0106,$0c00,$01fc,$0,$01dc,$20
	dc.w 	$0100,$1200
	dc.w	bplcon1,0,bplcon2,0,bpl1mod,0,bpl2mod,0
bitplan	dc.w	bplpt,0,bplpt+2,0,bplpt+4,0,bplpt+6,0	
	dc.w	diwstrt,$2c81,diwstop,$2cc1,ddfstrt,$38,ddfstop,$d0
sprite	dc.w	$0120,0,$122,0,$0124,0,$126,0,$0128,0,$12a,0,$012c,0,$12e,0
	dc.w	$0130,0,$132,0,$0134,0,$136,0,$0138,0,$13a,0,$013c,0,$13e,0
	dc.w	color,$fff,color+2,$000,color+4,$555,color+6,$aaa
	
	dc.w 	$ff07,$fffe	; 1 scanline interval
	dc.w	color,$0
	dc.w	$ffe1,$fffe	; draw past 255th scanline (PAL)	
	dc.w	color,$f0f
Past255	dc.w	$0007,$fffe
	dc.w	color,$0ff

	dc.w 	$ffff,$fffe	; Nothing is impossible to the Copper...	
	dc.w 	$ffff,$fffe	; ...well except unreachable raster position							


	; ----
	; Todo: AllocMem instead of bss
	; ----
	;SECTION backbuffer,bss_c
	ALIGN	4
backbuffer
	dcb.b	40*256,0

	end