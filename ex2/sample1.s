; 	sample 1
		lui		x1,0x8		; x1 = 0x00008000
		addi	x2,x0,1		; x2 = x0 + 1
		addi	x3,x0,11	; x3 = x0 + 11
		addi	x4,x0,1		; x4 = x0 + 1

loop:	andi	x5,x2,1		; extract LSB of x2
		beq		x5,x4,skip	; if odd, jump to skip
		add		x1,x1,x2	; if even, add x2 to x1

skip:	addi	x2,x2,1		; x2 = x2 + 1
		slt		x5,x2,x3	; if x2 < 11, x5 == 1 else x5 == 0
		beq		x5,x4,loop	; if x5 == 1, jump to loop

		ori		x1,x1,0x100	; add 0x100 to x1
		sw		x1,84(x0)	; store x1 to memory address 84

