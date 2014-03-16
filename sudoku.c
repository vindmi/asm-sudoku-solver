#include <stdio.h>
#include "sudoku.h"

void printSudoku(int* s)
{
    int i = 0;
    for(; i < 81; i++)
    {
          if (i % 9 == 0)
             printf("\n");

          printf("%d", s[i]);
    }
    printf("\n");
}

int main() {
    FILE *ifp;
    ifp = fopen("sudoku.txt", "r");
    
    if (ifp == NULL)
    {
       printf("Couldn't open sudoku.txt input file!\n");
       return 0;
    }
    
    int sud[81] = {0};
    int index = 0;
    fscanf(ifp, "%d", &sud[index]);
    while(!feof(ifp))
    {
       index++;
       if (index > 81)
       {
          printf("sudoku.txt contains more than 81 digits! Sudoku is invalid.\n");
          return 0;
       }
       fscanf(ifp, "%d", &sud[index]);
    }
    
    if (index < 81)
    {
       printf("sudoku.txt contains less than 81 digits! Sudoku is invalid.\n");
       return 0;
    }

    fclose(ifp);
    sudoku(sud);
    printSudoku(sud);
    return 0;
}
