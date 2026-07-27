/**
 * File: init_cookies.c
 * Standard: C17/C18 (Fallback from C23 due to compiler compatibility)
 * Compiler: Apple clang version 21.0.0
 * Missing C23 Features: constexpr, auto
 */

#include <stdlib.h>
#include <stdio.h>
#include "webmodule.h"

/**
 * @brief Initializes the cookies collection.
 *
 * Sets up the initial version, extension increment, and allocates the
 * initial list of cookies.
 *
 * @param cookies      Pointer to the COOKIES structure to initialize.
 * @param version      The version number of the cookie collection.
 * @param extend_size  The initial number of cookies to allocate.
 * @return int         Returns 0 on success, or ERROR_ENCOUNTERED on failure.
 */
int init_cookies(COOKIES *cookies, int version, int extend_size) {
    if (cookies == NULL) {
        return ERROR_ENCOUNTERED;
    }

    cookies->version = version;
    cookies->extend_increment = extend_size;
    cookies->count_entries = 0;
    
    cookies->list = calloc(extend_size, sizeof(COOKIE *));
    if (cookies->list == NULL) {
        return ERROR_ENCOUNTERED;
    }

    cookies->max_entries = extend_size;
    cookies->free_entries = extend_size;

    return 0;
}
