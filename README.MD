This program solves 9x9 Sudoku puzzle.
It is written in ARM assembly language.

Files:
	sudoku.c (main)
	sudoku.h (function prototype)
	sudoku.s (asm source)
	
How to compile:	
	
1) arm-linux-gnueabi-gcc -g -O0 -Wall -o sudoku.o -c sudoku.c
2) arm-linux-gnueabi-as -g -alh=sudoku1.lis -L -o sudoku1.o sudoku.s
3) arm-linux-gnueabi-gcc -g -o sudoku sudoku1.o sudoku.o

Run:

sudoku sudoku.txt