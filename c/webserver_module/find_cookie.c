/**
 * File: find_cookie.c
 * Standard: C17/C18 (Fallback from C23 due to compiler compatibility)
 * Compiler: Apple clang version 21.0.0
 * Missing C23 Features: constexpr, auto
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "webmodule.h"

/**
 * @brief Searches for a cookie in the collection by name.
 *
 * This function uses a binary search (via locate_cookie) to find the
 * first cookie that matches the name of the provided cookie.
 *
 * @param cookies Pointer to the COOKIES collection.
 * @param cookie  Pointer to a COOKIE structure containing the name to search for.
 * @return COOKIE* Pointer to the found cookie, or NULL if not found or parameters are invalid.
 */
COOKIE *find_cookie(COOKIES *cookies, COOKIE *cookie) {
    if (cookies == NULL || cookie == NULL || cookies->count_entries <= 0) {
        return NULL;
    }

    int index = locate_cookie(cookies, cookie, 0, cookies->count_entries - 1);
    if (index != -1) {
        return cookies->list[index];
    }

    return NULL;
}
