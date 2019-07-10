#define _GNU_SOURCE 1
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include "webmodule.h"

int main (int argc, char **argv) {
  int result = 0;
  COOKIES cookies;
  char *line = NULL;
  size_t line_capacity = 0;
  size_t in_count = 0;
  char *cookie_start = NULL;
  char *tmp_ptr = NULL;
  if (init_cookies(&cookies,COOKIES_CURRENT_VERSION,COOKIE_EXTEND_SIZE) == OK_TO_CONTINUE) {
    while ((in_count = getline(&line,&line_capacity,stdin)) > 0) {
      if (feof(stdin) == 0) {
	tmp_ptr = rindex(line,'\n');
	if (tmp_ptr != NULL) {
	  *tmp_ptr = '\0';   // Remove the carridge return and new line if present.
        }
	tmp_ptr = rindex(line,'\r');
	if (tmp_ptr != NULL) {
	  *tmp_ptr = '\0';   // Remove the carridge return and new line if present.
        }
	if ((tmp_ptr = strcasestr(line,"Set-Cookie:")) != NULL) {
	  
	  cookie_start = tmp_ptr + strlen("Set-Cookie:");
	  while (*++cookie_start == ' ') {
	    if (*cookie_start == '\0') {
	      break;
	    }
	  }
	  add_cookie(&cookies,cookie_start,WB_TRUE);
	}
      } else {
	break;
      }
    }
    for (int idx = 0; idx < cookies.count_entries; idx++) {
      printf("%s = %s\n",cookies.list[idx]->name,cookies.list[idx]->value);
    }
  }
  return result;
}
