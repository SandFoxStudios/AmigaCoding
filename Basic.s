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
  	
	move.l #BasicCopperList,cop1lc(a5)
	move.w	#$8280,dmacon(a5)	; Set + DmaEn + CopEn 

	
.mainloop
	tst.b	$06(a5)
	bne.s	.mainloop
	move.w	#$f00,$180(a5)	; raster PROFILE_BEGIN
;.pal60	cmp.b	#$1e,$06(a5)
;	blo.s	.pal60
	
.testclick
	move.w	#$fff,$180(a5)	; raster PROFILE_END
	btst	#6,CIAAPRA
	bne.s	.mainloop	
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
	dc.w 	$0100,$0200
sprite	dc.w	$0120,0,$122,0
	dc.w	color,$fff
	dc.w 	$ff07,$fffe	; 1 scanline interval
	dc.w	color,$0
	dc.w	$ffe1,$fffe	; draw past 255th scanline (PAL)	
	dc.w	color,$fff
Past255	dc.w	$0007,$fffe
	dc.w	color,$fff

	dc.w 	$ffff,$fffe	; Nothing is impossible to the Copper...	
	dc.w 	$ffff,$fffe	; ...well except unreachable raster position							


	end