
	opt	d+
	
	;include	progs:divers/equates.s
	;include progs:divers/MesMacros.s
	include	exec/exec_lib.i
	;include	dos/dos_lib.i
	include "types.i"
	
	section	mycode,CODE

start	
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	$4.w,a6			* Execbase
	suba.l	a1,a1
	jsr	_LVOFindTask(a6)	* Tache courante
;	move.l	d0,task
	move.l	d0,a1
	moveq.l	#10,d0			* Plus haute
	jsr	_LVOSetTaskPri(a6)	* priorité 
;	move.b	d0,Oldpri		* Ancienne pri
	lea	_DOSName,a1
	moveq	#37,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,_DOSBase
	beq.w	goback
	
;	jsr	_LVOForbid(a6)

main	lea	$dff000,a5
	;move.l	$4.w,a6
	;lea	cpt.int,a1
	;moveq	#5,d0
	;jsr	_LVOAddIntServer(a6)
	;bsr	print
	
	GETVBR
	move.w	$01c(a5),OldIntena
	or.w	#$c000,OldIntena
;	move.w	$02(a5),OldDMA
;	or.w	#$8100,OldDMA
	
	move.w	#$7fff,$9a(a5)
;	move.w	#$7fff,$9c(a5)
;        move.w	#$7fff,$96(a5)
   
	move.l	$6c(a1),oldInt ;(a0)
	move.l	#cpt.code,$6c(a1)

	move.w	#$c020,$09a(a5)
;	move.w	#$8280,$096(a5)	
        	

	moveq	#0,d7
wait	
	addq.l	#1,d7
	move.l	cpt,d0
	cmp.l	#50,d0
	ble.s	.skip
	move.l	d7,compteur
	bsr.w	printf
	move.l	#0,cpt
	clr.l	d7
.skip
	btst	#6,$bfe001
	bne.s	wait
	
	move.w	#$7fff,$09a(a5)
;	move.w	#$7fff,$09c(a5)
;	move.w	#$7fff,$096(a5)

	;lea	oldInt,a0
	move.l	oldInt,$6c(a1)
	
	move.w	OldIntena,$09a(a5)
;	move.w	OldDMA,$096(a5)

	move.l	_DOSBase,a1
	move.l	$4.w,a6
	jsr	_LVOCloseLibrary(a6)
	
;	jsr	_LVOPermit(a6)
	;moveq	#5,d0
	;lea	cpt.int,a1
	;jsr	_LVORemIntServer(a6)
	
goback	
;	move.l	task,a1	
;	move.b	Oldpri,d0		* Remise de l'
;	jsr	_LVOSetTaskPri(a6)	* Ancienne pri.

	movem.l	(sp)+,d0-d7/a0-a6
fin	moveq	#0,d0
	rts			

	VBRTRAP

cpt.code
	movem.l	d0-d7/a0-a6,-(sp)
	lea	$dff000,a5
	andi.w #$20,$1e(a5)
	beq.s	noint
	lea 	cpt,a1
	addq.l	#1,(a1)
	move.w	#$0020,$09c(a5)
	move.w	#$0020,$09c(a5)
noint	movem.l	(sp)+,d0-d7/a0-a6
	;moveq	#0,d0
	;rts
	rte
	
	
print	movem.l	d0-d1/a0-a1,-(sp)
	move.l	#coucou,d1
	move.l	_DOSBase,a6
	jsr	_LVOPutStr(a6)
	movem.l	(sp)+,d0-d1/a0-a1
	rts
	
printf	
	lea	format,a0
	lea	compteur,a1
	lea	range(pc),a2
	lea	tampon,a3
	move.l	$4.w,a6
	jsr	_LVORawDoFmt(a6)
	move.l	_DOSBase,a6
	move.l	#tampon,d1
	jsr	_LVOPutStr(a6)
	rts

range	move.b	d0,(a3)+
	rts

	section	MyData,DATA

	CNOP	0,4
_DOSBase	dc.l	0
;task		dc.l	0
compteur	dc.l	0
OldDMA		dc.w	0
OldIntena	dc.w	0
;Oldpri		dc.b	0
oldInt		dc.l	0
coucou		dc.b	"Kikou  ",10,0
format		dc.b	"Exec.%ld.",10,0

;	CNOP	0,4
;cpt.int		dc.l	0,0
;		dc.b	2,-100		; NT_INTERRUPT
;		dc.l	int.nom,cpt,cpt.code

;	CNOP	0,4
cpt		dc.l	0
;int.nom		dc.b	"compteur d'interruption",0
_DOSName		dc.b	'dos.library',0

	section myBss,BSS

tampon		ds.b	256		