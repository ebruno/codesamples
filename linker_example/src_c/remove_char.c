/*! \file
  \brief Strip all occurrences of a character from a buffer.
 */
// cppcheck-suppress-begin missingIncludeSystem
#include <string.h>
#include "swtrstrlib.h"
// cppcheck-suppress-end missingIncludeSystem
/*!
  \brief Strip all occurrences of a character from a buffer.
  The buffer is packed in place.
  Note: \ref SWTRSTRLIB_STRING_TERMINATOR_C cannot be stripped.

  @param inbuf   Pointer the buffer.
  @param remove_char Character to be removed.

  @returns the new length of the buffer or \ref SWTRSTRLIB_FAILURE
 */
int swtrstrlib_strip_char(char *inbuf, char remove_char) {
  int result = 0;
  char *result_ptr = NULL;
  char *look_ptr = NULL;
  if ((inbuf != NULL) && (remove_char != SWTRSTRLIB_STRING_TERMINATOR_C)) {
    look_ptr = inbuf;
    result_ptr = inbuf;
    while (*look_ptr != SWTRSTRLIB_STRING_TERMINATOR_C) {
      if (*(look_ptr) == remove_char) {
	look_ptr++;
      } else {
	*result_ptr++ = *look_ptr++;
	result++;
      }
    }
    *result_ptr = SWTRSTRLIB_STRING_TERMINATOR_C;
  }
  else {
    result = SWTRSTRLIB_FAILURE;
  }
  return result;
}
