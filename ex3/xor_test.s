addi x1, x0, 12     ; x1 = 12 (1100)
addi x2, x0, 10     ; x2 = 10 (1010)
xor  x3, x1, x2     ; Test XOR : 12 XOR 10 = 6 (0110)
xori x4, x1, -1     ; Test XORI : 12 XOR -1 = -13 (1001)
addi x10, x0, 7     ; Set test value (7)
sw   x10, 84(x0)    ; Store to 84

