#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "webmodule.h"

int delete_cookie(COOKIE *cookie) {
  int result = OK_TO_CONTINUE;
  if (cookie != NULL) {
    if (cookie->name != NULL) {
      free(cookie->name);
      cookie->name = NULL;
    }
    if (cookie->value != NULL) {
      free(cookie->value);
      cookie->value = NULL;
    }
  }
  return result;
}
