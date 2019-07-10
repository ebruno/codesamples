#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "webmodule.h"


int locate_cookie(COOKIES *cookies, COOKIE *cookie, int low, int high) {
  int mid = (low + high + 1) / 2;
  int result = -1;
  int cmp_result = 0;
  if ((cookies != NULL) && (cookie != NULL)) {
    cmp_result = strcmp(cookies->list[mid]->name,cookie->name);
    if ( cmp_result < 0) {
      if (mid != low) {
	result = locate_cookie(cookies,cookie,mid,high);
      }
    } else if (cmp_result > 0) {
      if (mid != high) {
	result = locate_cookie(cookies,cookie,low,mid);
      } else if (low < mid) {
	result = locate_cookie(cookies,cookie,low,mid-1);
      } 
    } else {
      result = mid;
    }
  }
  return result;  
}
