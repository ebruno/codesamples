/*!
  \file
  \brief Softwaretrace process management header file.
 */

#if !defined (__SWTRSTRLIB_H__)
#if defined (__FreeBSD__) || defined (__linux__)
#define SWTRLIB_CURRENT_OS_SUPPORTED 1
#else
#error "Unsupported Operating System"
#endif
// cppcheck-suppress-begin missingIncludeSystem
#define __SWTRSTRLIB_H__

#include <sys/types.h>

#include <stdbool.h>

// cppcheck-suppress-end missingIncludeSystem

#ifdef __cplusplus
extern "C" {
#endif
#define SWTRSTRLIB_SUCCESS 0
  /*! Function/Operation failed. */
#define SWTRSTRLIB_FAILURE -1
#define SWTRSTRLIB_STRING_TERMINATOR_C '\0'


extern int swtrstrlib_left_remove_char(char *inbuf, char remove_char);
extern int swtrstrlib_right_remove_char(char *inbuf, char remove_char);
extern int swtrstrlib_strip_char(char *inbuf, char remove_char);

#ifdef __cplusplus
}
#endif

#endif
