#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "webmodule.h"

static int compare_cookies(const void *a, const void *b) {
  int result = 0;
  COOKIE **a_cookie = NULL;
  COOKIE **b_cookie = NULL;
  if ((a != NULL) && (b != NULL)) {
    a_cookie = (COOKIE **) a;
    b_cookie = (COOKIE **) b;
    result = strcmp((*a_cookie)->name,(*b_cookie)->name);
  }
  return result;
}


int sort_cookies (COOKIES *cookies) {
  int result = 0;
  size_t num_elements = cookies->count_entries;
  size_t width = sizeof(COOKIE *);
  qsort((void *) cookies->list,num_elements,width,&compare_cookies);
  return result;
}
