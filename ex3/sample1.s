; 	sample 1
	lui x1,0x8
	addi x2,x0,1
	addi x3,x0,11
	addi x4,x0,1
loop:	add x1,x1,x2
	addi x2,x2,1
	slt x5,x2,x3
	beq x5,x4,loop
	ori x1,x1,0x100
	sw x1,84(x0)
