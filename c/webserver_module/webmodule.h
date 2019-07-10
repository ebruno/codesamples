#ifndef _WEBMODULE_H_
#define _WEBMODULE_H_

#include <sys/errno.h>

#define COOKIE_CURRENT_VERSION 1
#define COOKIES_CURRENT_VERSION 1
#define COOKIE_EXTEND_SIZE  10

#define OK_TO_CONTINUE  0
#define ERROR_ENCOUNTERED 1

#define EQUAL_SIGN '='

#ifndef WB_TRUE
#define WB_TRUE 1
#endif
#ifndef WB_FALSE
#define WB_FALSE 0
#endif

typedef struct _COOKIE {
  int version;
  char *name;
  char *value;
} COOKIE;

typedef struct _COOKIES {
  int version; 
  int max_entries;
  int count_entries;
  int free_entries;
  int extend_increment;
  COOKIE **list;
} COOKIES;

int sort_cookies(COOKIES *cookies);
int init_cookies(COOKIES *cookies, int version, int extend_size);
int extend_cookies(COOKIES *cookies);
int add_cookie(COOKIES *cookies,char *cookie,int no_dupe);
COOKIE *find_cookie(COOKIES *cookies, COOKIE *cookie);
int locate_cookie(COOKIES *cookies, COOKIE *cookie, int low, int high);
int delete_all_cookies(COOKIES *cookies);
int delete_cookie(COOKIE *cookie);
#endif
