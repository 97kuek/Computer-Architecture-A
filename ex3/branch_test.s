            addi x1, x0, 10     ; Set x1 = 10
            addi x2, x0, 20     ; Set x2 = 20
            addi x3, x0, -5     ; Set x3 = -5

; 1. BNE_TEST (Not Equal)
            bne  x1, x2, success1    ; 10 != 20 -> success1
            j fail                   ; Fail if not taken
success1:
            bne  x1, x1, fail        ; 10 != 10 -> Not Taken (Fall through)

; 2. BLT_TEST (Less Than)
            blt  x1, x2, success2    ; 10 < 20 -> success2
            j fail
success2:
            blt  x2, x1, fail        ; 20 < 10 -> Not Taken

; 3. BGE_TEST (Greater or Equal)
            bge  x2, x1, success3    ; 20 >= 10 -> success3
            j fail
success3:
            bge  x1, x2, fail        ; 10 >= 20 -> Not Taken

; 4. BLTU_TEST (Unsigned Less Than)
            bltu x1, x3, success4    ; 10 < Huge -> success4
            j fail
success4:

; 5. BGEU_TEST (Unsigned Greater or Equal)
            bgeu x3, x1, success5    ; Huge >= 10 -> success5
            j fail

success5:

; Simulation succeeded
            addi x10, x0, 7         ; Set x10 = 7
            sw   x10, 84(x0)        ; Store to address 84
            j end

fail:
            sw   x0, 84(x0)         ; Store 0 (Fail)
end:


