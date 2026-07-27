/**
 * File: locate_cookie.c
 * Standard: C17/C18 (Fallback from C23 due to compiler compatibility)
 * Compiler: Apple clang version 21.0.0
 * Missing C23 Features: constexpr, auto
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "webmodule.h"

/**
 * @brief Recursively locates a cookie in the collection using binary search.
 *
 * @param cookies Pointer to the COOKIES collection.
 * @param cookie  Pointer to a COOKIE structure containing the name to search for.
 * @param low     The lower bound index of the search range.
 * @param high    The upper bound index of the search range.
 * @return int    The index of the cookie if found, or -1 if not found.
 */
int locate_cookie(COOKIES *cookies, COOKIE *cookie, int low, int high) {
    if (cookies == NULL || cookie == NULL || low > high) {
        return -1;
    }

    int mid = low + (high - low) / 2;
    int cmp_result = strcmp(cookies->list[mid]->name, cookie->name);

    if (cmp_result < 0) {
        return locate_cookie(cookies, cookie, mid + 1, high);
    } else if (cmp_result > 0) {
        return locate_cookie(cookies, cookie, low, mid - 1);
    } else {
        return mid;
    }
}
