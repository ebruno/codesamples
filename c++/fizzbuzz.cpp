#include <iostream>
#include <format>
#include <string>

int fizzbuzz(int start,int end, int step, int modulo_fizz, int modulo_buzz) {
  int status = 0;
  int max_length = 12;
  std::string result;
  for (int value=start; value <= end; value+=step) {
    result = "";
    if ( (value % modulo_fizz) == 0) {
      result += "fizz";
    }
    if ( (value % modulo_buzz) == 0 ) {
      result += "buzz";
    }
    if (result.length() == 0) {
      result = std::format("{}",value);
    }
    std::cout << result << std::endl;
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
