#include <stdlib.h>
#include <stdio.h>
#include "webmodule.h"


int init_cookies (COOKIES *cookies, int version,int extend_size) {
  int result = 0;
  if (cookies != NULL) {
    cookies->version = version;
    cookies->extend_increment = extend_size;
    cookies->max_entries = 0;
    cookies->free_entries = 0;
    cookies->count_entries = 0;
    cookies->list = NULL;
    cookies->list = (COOKIE **) realloc(cookies->list,sizeof(cookies->list)*cookies->extend_increment);
    if (cookies->list == NULL) {
      result = ERROR_ENCOUNTERED;
    } else {
      for (int idx = 0; idx < cookies->extend_increment; idx++) {
	cookies->list[idx] = NULL;
      }
      cookies->max_entries = cookies->extend_increment;
      cookies->free_entries = cookies->extend_increment;      
    }
  }
  return result;
}
