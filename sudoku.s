	.text
	.align 2
	.global sudoku
	.type sudoku, %function
sudoku:
						@ R0 = passed data start address
	MOV R4, R0			@ save data start address, because R0 will be changed
	MOV R5, R0			@ R5 = data array iterator
	SUB R5, R5, #4		@ for pre-index addressing mode
	ADD R7, R0, #320	@ last element's address
	SUB SP, SP, #324	@ allocate stack space for 81 sudoku element (81 * 4) = 324 bytes
	MOV R6, SP			@ save stack start address for determinating stack emptyness
	MOV R9, LR			@ save return address
start:
	BL get_next_zero	
guess_next_number:
	ADD R8, R8, #1
	CMP R8, #9				 @ if none of 1..9 numbers match, previous guess was wrong, so return to it
	BHI get_previous_from_stack
row_check:
	BL get_row_start_address @ R0 = row start address
	ADD R1, R0, #36			 @ R1 = next row's first elem address
	SUB R0, R0, #4		     @ for pre-index addressing mode
row_check_loop:
	LDR R2, [R0, #4]!
	CMP R0, R1				 @ out of row?
	BGE column_check
	CMP R0, R5
	BEQ row_check_loop		 @ do not compare elem with itself
	CMP R2, R8				 @ if values are equal, guessed number is incorrect
	BEQ guess_next_number
	B row_check_loop
column_check:
	BL get_row_start_address @ R0 = row start address
	SUB R1, R5, R0			 @ current elem offset from row start
	ADD R1, R4, R1			 @ R1 = column's first elem addr (data start + current elem row offset)
	ADD R2, R1, #288		 @ R2 = column's last elem addr (8*36)
	SUB R1, R1, #36		     @ for pre-index addressing mode
column_check_loop:
	LDR R3, [R1, #36]!
	CMP R1, R2				@ checked entire column?
	BHI matrix_check		
	CMP R1, R5				@ do not compare elem with itself
	BEQ column_check_loop
	CMP R3, R8
	BEQ guess_next_number
	B column_check_loop
matrix_check:
	SUB R0, R5, R4			 @ current elem offset from array start
	MOV R1, #36
	BL div					 @ R0 = elem's row index
	MOV R10, R0				 @ save row index in R10, because other registers will change or are unavailable
	BL get_row_start_address
	SUB R0, R5, R0			 @ current elem offset from row start
	MOV R1, #4
	BL div					 @ R0 / 4
	MOV R3, R0				 @ R3 = elem's column index
	MOV R2, R10				 @ R2 = elem's row index
	BL get_matrix_start_address		@R0 = 3x3 matrix start address
	MOV R1, #0				 @ outer loop counter (Y)
	MOV R2, #0				 @ inner loop counter (X)
matrix_check_loop:
	CMP R0, R5				 @ do not compare elem with itself
	BEQ matrix_check_inc_inner
	LDR R3, [R0]			 
	CMP R3, R8				 @ are values equal?
	BEQ guess_next_number
matrix_check_inc_inner:
	CMP R2, #2				 @ X > 2 ? X = 0; Y++; : X++;
	BGE matrix_check_inc_outer
	ADD R2, R2, #1
	ADD R0, R0, #4			 @ X step is 4 bytes (1 element)
	B matrix_check_loop
matrix_check_inc_outer:
	CMP R1, #2
	BGE save_guessed_number
	MOV R2, #0
	ADD R1, R1, #1
	ADD R0, #28				@ Y step is 28 bytes (7 elements)
	B matrix_check_loop
save_guessed_number:
	STR R8, [R5]			@ save current guess at current position
	CMP R5, R7				@ if saved last Sudoku element, then Sudoku is solved - exit
	BEQ end_program
	STMFD SP!, {R5}			@ remember address of last saved guess
	B start
get_previous_from_stack:
	CMP R6, SP				@ is stack empty?
	BEQ end_program
	MOV R0, #0
	STR R0, [R5]			@ save 0 at current position, because current guess was wrong
	LDMFD SP!, {R5}			@ load previous guess position
	LDR R8, [R5]			@ load previous guess number
	B guess_next_number
end_program:
	ADD SP, R6, #324		@ restore SP
	MOV R0, R4				@ return array address
	MOV LR, R9				@ restore LR	
	BX LR
@ sets R5 to point to the next zero in sudoku table,
@ sets R8 to value of 0, if found any
get_next_zero:
	CMP R5, R7		  		@ have we reached the outside of the table?
	BHI end_program
	LDR R8, [R5, #4]! 		@ load into R8 value of the current sudoku field, increase pointer to current elem
	CMP R8, #0		  		@ have we read zero?
	BNE get_next_zero		@ read while reach zero
	BX LR
@ Modulus division function
@ R0 = dividend, R1 = modulus. R0 = result.
mod:
	CMP R1, R0
	BHI mod_return
	SUB R0, R0, R1
	B mod
mod_return:
	BX LR
@ Division function
@ R0 = dividend, R1 = divisor. R0 = result
div:
	MOV R2, #0
	CMP R1, #0				@ division by zero?
	BEQ div_return
div_loop:
	CMP R0, R1
	BLT div_return
	SUB R0, R0, R1			@ subtract divisor from divident
	ADD R2, #1				@ count subtractions
	B div_loop
div_return:
	MOV R0, R2
	BX LR
@ Function which gets current element row's start address
@ R5 = current elem addr, R0 = result
get_row_start_address:
	SUB R2, R5, R4			@ get current offset from data start
	MOV R3, LR				@ save LR for return
	MOV R0, R2				@ set mod params
	MOV R1, #36				@ offset from row start = offset from data start % 36
	BL mod					@ get current elem offset from row start
	SUB R0, R5, R0			@ row start = current addr - offset from start
	MOV LR, R3
	BX LR
@ Function gets start address of 3x3 sudoku matrix, which contains current element
@ R2 = elem's row index, R3 = elem's column index, R0 = result
get_matrix_start_address:
	MOV R1, LR
	MOV R0, R2
	BL normalize_index
	MOV R2, R0
	MOV R0, R3
	BL normalize_index
	MOV R3, R0
	MOV LR, R1
	MOV R0, #36
	MUL R2, R0, R2
	MOV R0, #4
	MUL R3, R0, R3
	ADD R0, R4, R2
	ADD R0, R0, R3
	BX LR
@ Function transforms coordinates to 3x3 matrix start coordinates.
@ R0 = current index. R0 = result (normalized index)
normalize_index:
	CMP R0, #2
	BHI higher_than_2
	MOV R0, #0
	BX LR
higher_than_2:
	CMP R0, #5
	BHI higher_than_5
	MOV R0, #3
	BX LR
higher_than_5:
	MOV R0, #6
	BX LR
	