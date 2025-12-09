addi x10, x0, 20    ; Set base address (20)
lw   x5,  60(x10)   ; Load from 80 (20 + 60)
addi x11, x0, 7     ; Set test value (7)
sw   x11, 64(x10)   ; Store to 84 (20 + 64)

