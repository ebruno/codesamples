/**
 * File: add_cookie.c
 * Standard: C17/C18 (Fallback from C23 due to compiler compatibility)
 * Compiler: Apple clang version 21.0.0
 * Missing C23 Features: constexpr, auto
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "webmodule.h"

/**
 * @brief Adds a new cookie to the cookies collection or updates an existing one.
 *
 * If no_dupe is true, it checks for existing cookies with the same name.
 * If found, the value is updated. Otherwise, a new cookie is added.
 *
 * @param cookies Pointer to the COOKIES collection.
 * @param cookie  String containing the cookie in "name=value" format.
 * @param no_dupe Boolean flag to prevent duplicate cookie names.
 * @return int    Returns OK_TO_CONTINUE on success, or ERROR_ENCOUNTERED on failure.
 */
int add_cookie(COOKIES *cookies, char *cookie, int no_dupe) {
    int result = ERROR_ENCOUNTERED;
    char *separator_loc = NULL;
    COOKIE tmp_cookie;
    bool should_add = false;
    size_t tmp_len = 0;

    if (cookies == NULL || cookie == NULL) {
        return result;
    }

    separator_loc = strchr(cookie, EQUAL_SIGN);
    if (separator_loc == NULL) {
        return result;
    }

    tmp_len = (size_t)(separator_loc - cookie);

    if (no_dupe == WB_TRUE) {
        tmp_cookie.name = calloc(tmp_len + 1, sizeof(char));
        if (tmp_cookie.name == NULL) return ERROR_ENCOUNTERED;
        
        strncpy(tmp_cookie.name, cookie, tmp_len);
        tmp_cookie.value = NULL;

        COOKIE *update_cookie = find_cookie(cookies, &tmp_cookie);
        free(tmp_cookie.name);

        if (update_cookie == NULL) {
            should_add = true;
        } else {
            size_t value_len = strlen(cookie) - tmp_len;
            char *semicolon_loc = strchr(separator_loc, ';');
            if (semicolon_loc != NULL) {
                value_len -= (strlen(semicolon_loc));
                if (value_len > 0) value_len--;
            }

            free(update_cookie->value);
            update_cookie->value = calloc(value_len + 1, sizeof(char));
            if (update_cookie->value != NULL && value_len > 0) {
                strncpy(update_cookie->value, separator_loc + 1, value_len);
            }
            should_add = false;
        }
    } else {
        should_add = true;
    }

    if (should_add) {
        if (cookies->free_entries < 1) {
            extend_cookies(cookies);
        }

        if (cookies->free_entries > 0) {
            COOKIE *new_cookie = calloc(1, sizeof(COOKIE));
            if (new_cookie != NULL) {
                new_cookie->version = COOKIE_CURRENT_VERSION;
                
                new_cookie->name = calloc(tmp_len + 1, sizeof(char));
                if (new_cookie->name != NULL) {
                    strncpy(new_cookie->name, cookie, tmp_len);
                }

                size_t value_len = strlen(cookie) - tmp_len;
                char *semicolon_loc = strchr(separator_loc, ';');
                if (semicolon_loc != NULL) {
                    value_len -= (strlen(semicolon_loc));
                    if (value_len > 0) value_len--;
                }

                if (value_len > 0) {
                    new_cookie->value = calloc(value_len + 1, sizeof(char));
                    if (new_cookie->value != NULL) {
                        strncpy(new_cookie->value, separator_loc + 1, value_len);
                    }
                }

                cookies->list[cookies->count_entries] = new_cookie;
                cookies->count_entries++;
                cookies->free_entries--;
                sort_cookies(cookies);
                result = OK_TO_CONTINUE;
            }
        }
    }

    return result;
}
