#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "webmodule.h"


COOKIE *find_cookie (COOKIES *cookies,COOKIE *cookie) {
  COOKIE *result = NULL;
  if ((cookies != NULL) && (cookie != NULL)) {
    int tmp_result = -1;
    if (cookies->count_entries > 0) {
      if (cookies->count_entries > 1) {
	tmp_result = locate_cookie(cookies,cookie,0,cookies->count_entries-1);
      } else {
	tmp_result = locate_cookie(cookies,cookie,0,0);
      }
      if (tmp_result != -1) {
	result = cookies->list[tmp_result];
      }
    }
  };
  return result;
}

