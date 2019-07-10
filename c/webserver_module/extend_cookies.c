#include <stdlib.h>
#include <stdio.h>
#include "webmodule.h"


int extend_cookies (COOKIES *cookies) {
  int result = 0;
  if (cookies != NULL) {
    int new_size = cookies->max_entries + cookies->extend_increment; 
    cookies->list = (COOKIE **) realloc(cookies->list,sizeof(cookies->list)*new_size);
    if (cookies->list == NULL) {
      result = ERROR_ENCOUNTERED;
    } else {
      for (int idx = cookies->max_entries; idx < new_size; idx++) {
	cookies->list[idx] = NULL;
      }
      cookies->free_entries += cookies->extend_increment;
      cookies->max_entries = new_size;
    }
  }
  return result;
}
