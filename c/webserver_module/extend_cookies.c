/**
 * File: extend_cookies.c
 * Standard: C17/C18 (Fallback from C23 due to compiler compatibility)
 * Compiler: Apple clang version 21.0.0
 * Missing C23 Features: constexpr, auto
 */

#include <stdlib.h>
#include <stdio.h>
#include "webmodule.h"

/**
 * @brief Extends the capacity of the cookies collection.
 *
 * This function increases the size of the internal cookie list by the
 * specified extend_increment, ensuring there is more space for new cookies.
 *
 * @param cookies Pointer to the COOKIES collection to extend.
 * @return int    Returns 0 on success, or ERROR_ENCOUNTERED if memory allocation fails.
 */
int extend_cookies(COOKIES *cookies) {
    int result = 0;
    if (cookies == NULL) {
        return result;
    }

    int new_size = cookies->max_entries + cookies->extend_increment;
    COOKIE **new_list = realloc(cookies->list, new_size * sizeof(COOKIE *));
    
    if (new_list == NULL) {
        result = ERROR_ENCOUNTERED;
    } else {
        cookies->list = new_list;
        for (int idx = cookies->max_entries; idx < new_size; idx++) {
            cookies->list[idx] = NULL;
        }
        cookies->free_entries += cookies->extend_increment;
        cookies->max_entries = new_size;
    }
    return result;
}
