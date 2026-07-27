/**
 * File: delete_cookie.c
 * Standard: C17/C18 (Fallback from C23 due to compiler compatibility)
 * Compiler: Apple clang version 21.0.0
 * Missing C23 Features: constexpr, auto
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "webmodule.h"

/**
 * @brief Frees the memory associated with a single cookie.
 *
 * This function releases the memory allocated for the cookie's name and value,
 * setting the pointers to NULL to prevent dangling pointers.
 *
 * @param cookie Pointer to the COOKIE structure to be deleted.
 * @return int   Always returns OK_TO_CONTINUE.
 */
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
