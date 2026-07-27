/**
 * File: delete_cookies.c
 * Standard: C17/C18 (Fallback from C23 due to compiler compatibility)
 * Compiler: Apple clang version 21.0.0
 * Missing C23 Features: constexpr, auto
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "webmodule.h"

/**
 * @brief Deletes all cookies within the cookies collection.
 *
 * This function iterates through the cookie list, frees each individual cookie
 * using delete_cookie(), and then frees the cookie pointer itself.
 *
 * @param cookies Pointer to the COOKIES collection.
 * @return int    Returns OK_TO_CONTINUE on success.
 */
int delete_all_cookies(COOKIES *cookies) {
    int result = OK_TO_CONTINUE;
    if (cookies == NULL) {
        return result;
    }

    int count = cookies->count_entries;
    for (int idx = 0; idx < count; idx++) {
        if (cookies->list[idx] != NULL) {
            if (delete_cookie(cookies->list[idx]) == OK_TO_CONTINUE) {
                free(cookies->list[idx]);
                cookies->list[idx] = NULL;
            }
        }
    }
    cookies->count_entries = 0;
    
    return result;
}
