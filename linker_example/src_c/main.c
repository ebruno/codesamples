#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "swtrstrlib.h"

int main(int argc, char ** argv) {

  char testbuf[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  printf("Original: %s\n",testbuf);
  int result = swtrstrlib_left_remove_char(testbuf, 'A');
  if ( result == SWTRSTRLIB_SUCCESS) {
    printf("Modified: %s\n",testbuf);
  } else {
    printf("failed to remove char\n");
  }

  exit(0);
}
