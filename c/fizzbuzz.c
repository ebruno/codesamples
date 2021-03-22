#include <stdio.h>
#include <string.h>

int fizzbuzz(int start,int end, int step, int modulo_fizz, int modulo_buzz) {
  int status = .0;
  int max_length = 12;
  char result[max_length+1];
  for (int value=start; value <= end; value+=step) {
    memset(&result,0,max_length+1);
    if ( (value % modulo_fizz) == 0) {
      strcat(result,"fizz");
    }
    if ( (value % modulo_buzz) == 0 ) {
      strcat(result,"buzz");
    }
    if (strlen(result) == 0) {
      sprintf(result,"%d",value);
    }
    printf("%s\n",result);
  }
  return status;
}


int main(int argc, char **argv) {
  int status = 0;
  int start  = 1;
  int end    = 100;
  int step   = 1;
  int modulo_fizz = 3;
  int modulo_buzz = 5;
  status = fizzbuzz(start, end, step, modulo_fizz, modulo_buzz);
  return status;
}
