#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "webmodule.h"


int add_cookie (COOKIES *cookies,char *cookie,int no_dupe) {
  int result = ERROR_ENCOUNTERED;
  char *separator_loc = NULL;
  COOKIE tmp_cookie;
  int add_cookie = WB_FALSE;
  int tmp_len = 0;
  if ((cookies != NULL) && (cookie != NULL)) {
    separator_loc = strchr(cookie,EQUAL_SIGN);
    if (separator_loc != NULL) {
      tmp_len = separator_loc - cookie;
      if (no_dupe == WB_TRUE) {
	tmp_cookie.name = (char *) malloc(sizeof(char)*tmp_len+1);
	memset(tmp_cookie.name,'\0',tmp_len+1);
	strncpy(tmp_cookie.name,cookie,tmp_len);
	tmp_cookie.value = NULL;
	COOKIE *update_cookie = find_cookie(cookies,&tmp_cookie);
	if (update_cookie == NULL) {
	  add_cookie = WB_TRUE;
	} else {
	    tmp_len = strlen(cookie) - tmp_len;
	    free(update_cookie->value);
	    // locate the semi-colon and discard erverything after.
	    char *semicolon_loc = strchr(separator_loc,';');
	    if (semicolon_loc != NULL) {
	      int discard_len = strlen(semicolon_loc);
	      tmp_len -= discard_len;
	      tmp_len--;
	    }
	    update_cookie->value = (char *) malloc(sizeof(char)*tmp_len+1);
	    memset(update_cookie->value,'\0',tmp_len+1);
	    strncpy(update_cookie->value,++separator_loc,tmp_len);	  
	 }
       }
       if (add_cookie == WB_TRUE) {
	 if (cookies->free_entries < 1) {
	   extend_cookies(cookies);
	 }
	 if (cookies->free_entries > 0) {
	   cookies->list[cookies->count_entries] = (COOKIE *) malloc(sizeof(COOKIE));
	   if (cookies->list[cookies->count_entries] != NULL) {
	     cookies->list[cookies->count_entries]->version = COOKIE_CURRENT_VERSION;
	     cookies->list[cookies->count_entries]->name = (char *) malloc(sizeof(char)*tmp_len+1);
	     memset(cookies->list[cookies->count_entries]->name,'\0',tmp_len+1);
	     strncpy(cookies->list[cookies->count_entries]->name,cookie,tmp_len);
	     tmp_len = strlen(cookie) - tmp_len;
	     cookies->list[cookies->count_entries]->value = NULL;
	     // discard everything after the ';'
	     char *semicolon_loc = strchr(separator_loc,';');
	     if (semicolon_loc != NULL) {
	       int discard_len = strlen(semicolon_loc);
	       tmp_len -= discard_len;
	       tmp_len--;
	     }
	     if (tmp_len > 0) {
	       cookies->list[cookies->count_entries]->value = (char *) realloc(cookies->list[cookies->count_entries]->value,sizeof(char)*tmp_len+1);
	       memset(cookies->list[cookies->count_entries]->value,'\0',tmp_len+1);
	       strncpy(cookies->list[cookies->count_entries]->value,++separator_loc,tmp_len);
	     }
	     cookies->count_entries++;
	     cookies->free_entries--;
	     sort_cookies(cookies);
	     result = OK_TO_CONTINUE;
	  }
	}
      }
    }
  }
  return result;
}
