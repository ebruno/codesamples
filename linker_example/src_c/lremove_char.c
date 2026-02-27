// cppcheck-suppress-begin missingIncludeSystem
#include <string.h>
#include "swtrstrlib.h"
// cppcheck-suppress-end missingIncludeSystem

int swtrstrlib_left_remove_char(char *inbuf, char remove_char) {
  // cppcheck-suppress-begin constVariablePointer
  int result = SWTRSTRLIB_SUCCESS;
  char *result_ptr = NULL;
  char *look_ptr = NULL;
// cppcheck-suppress-end constVariablePointer
  if ((inbuf != NULL) && (remove_char != SWTRSTRLIB_STRING_TERMINATOR_C)) {
    look_ptr = inbuf;
    result_ptr = inbuf;
    while (*look_ptr != SWTRSTRLIB_STRING_TERMINATOR_C) {
      if (*(look_ptr) == remove_char) {
	look_ptr++;
      } else {
	/* If the remove character has been found shift the rest of buffer.
	   Otherwise nothing more to do.
	*/
	if (look_ptr != inbuf) {
	  while (*look_ptr != SWTRSTRLIB_STRING_TERMINATOR_C) {
	    *result_ptr++ = *look_ptr++;
	  }
	  *result_ptr = SWTRSTRLIB_STRING_TERMINATOR_C;
	}
	else {
	  break;
	}
      }
    }
  }
  else {
    result = SWTRSTRLIB_FAILURE;
  }
  return result;
}
