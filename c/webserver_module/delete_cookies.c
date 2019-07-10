#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "webmodule.h"

int delete_all_cookies(COOKIES *cookies) {
  int result = OK_TO_CONTINUE;
  if (cookies != NULL) {
    int max_cookies = cookies->count_entries;
    for (int idx = 0; idx < max_cookies; idx++) {
      if (delete_cookie(cookies->list[idx]) == OK_TO_CONTINUE) {
	free(cookies->list[idx]);
	cookies->list[idx] = NULL;
	cookies->count_entries--;;
      }
    }
    if (cookies->count_entries < 0) {
      cookies->count_entries = 0;
    }
  }
  return result;
}
