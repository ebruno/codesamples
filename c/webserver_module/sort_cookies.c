/**
 * File: sort_cookies.c
 * Standard: C17/C18 (Fallback from C23 due to compiler compatibility)
 * Compiler: Apple clang version 21.0.0
 * Missing C23 Features: constexpr, auto
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "webmodule.h"

/**
 * @brief Comparison function for qsort to sort cookies by name.
 *
 * @param a Pointer to the first COOKIE pointer.
 * @param b Pointer to the second COOKIE pointer.
 * @return int Comparison result: negative if a < b, positive if a > b, 0 if equal.
 */
static int compare_cookies(const void *a, const void *b) {
    if (a == NULL || b == NULL) {
        return 0;
    }
    COOKIE *a_cookie = *(COOKIE **)a;
    COOKIE *b_cookie = *(COOKIE **)b;
    if (a_cookie == NULL || b_cookie == NULL) return 0;
    return strcmp(a_cookie->name, b_cookie->name);
}

/**
 * @brief Sorts the cookies in the collection by name using qsort.
 *
 * @param cookies Pointer to the COOKIES collection to sort.
 * @return int Always returns 0.
 */
int sort_cookies(COOKIES *cookies) {
    if (cookies == NULL || cookies->count_entries == 0) {
        return 0;
    }
    qsort(cookies->list, cookies->count_entries, sizeof(COOKIE *), compare_cookies);
    return 0;
}
