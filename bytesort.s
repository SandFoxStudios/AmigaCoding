
start:	lea	input(pc),a0
	moveq	#size-1,d7
	moveq	#0,d1
	lea	counter(pc),a1
	lea	offset(pc),a2
		 
	move.l	a1,a3
.count0	move.b	(a0)+,d0
	addq.b	#1,(a3,d0)	
	dbf	d7,.count0
	; boucle separée pour les octets suivants
	; si on tombe sur un count_c[0] à 255 c'est que
	; très probablement il s'agit de valeurs ayant 
	; une taille de (c+1) octets			

	move.l	a1,a3		
	move.w	#255,d7
	; we start at offset[1] since offset[0] is always 0
calcOffset	
	move.b	(a2)+,d1	; offset[i-1]
	add.b	(a3)+,d1	; count of [i-1]
	;cmp	#size-1,d6
	;beq.s	.skip
	;addq	#1,d6
	move.b	d1,(a2)		; offset[i]		
	dbf.w	d7,calcOffset	

.skip	lea	offset(pc),a2
	lea	input(pc),a0	
	lea 	output(pc),a1
	move.w	#size-1,d7
.sort	move.b	(a0)+,d0
	move.b	(a2,d0),d1
	move.b	d0,(a1,d1)
	addq.b	#1,(a2,d0)
	dbf	d7,.sort
	lea	output(pc),a1
	rts
	
input	dc.b	5,68,2,9,198,36,255,0
	;dc.b	3,1,3,0,3
size = *-input
	even
output	ds.b size
	even
counter	ds.b 256
offset	ds.b 256	; 256 valeurs similaires au max