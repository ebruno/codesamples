/**
 * File: main.c
 * Standard: C17/C18 (Fallback from C23 due to compiler compatibility)
 * Compiler: Apple clang version 21.0.0
 * Missing C23 Features: constexpr, auto
 */

#define _GNU_SOURCE 1
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <stdbool.h>
#include "webmodule.h"

/**
 * @brief Entry point for the cookie header processor.
 *
 * Reads HTTP headers from stdin, extracts Set-Cookie headers,
 * and prints the unique cookies found.
 *
 * @param argc The number of command line arguments.
 * @param argv The array of command line arguments.
 * @return int Returns 0 on successful completion.
 */
int main(int argc, char **argv) {
    (void)argc;
    (void)argv;

    COOKIES cookies;
    char *line = NULL;
    size_t line_capacity = 0;
    ssize_t in_count = 0;
    char *cookie_start = NULL;
    char *tmp_ptr = NULL;

    if (init_cookies(&cookies, COOKIES_CURRENT_VERSION, COOKIE_EXTEND_SIZE) == OK_TO_CONTINUE) {
        while ((in_count = getline(&line, &line_capacity, stdin)) > 0) {
            tmp_ptr = strrchr(line, '\n');
            if (tmp_ptr != NULL) {
                *tmp_ptr = '\0';
            }
            tmp_ptr = strrchr(line, '\r');
            if (tmp_ptr != NULL) {
                *tmp_ptr = '\0';
            }

            if ((tmp_ptr = strcasestr(line, "Set-Cookie:")) != NULL) {
                cookie_start = tmp_ptr + strlen("Set-Cookie:");
                while (*cookie_start == ' ') {
                    cookie_start++;
                }
                add_cookie(&cookies, cookie_start, WB_TRUE);
            }
        }

        for (int idx = 0; idx < cookies.count_entries; idx++) {
            if (cookies.list[idx]) {
                printf("%s = %s\n", cookies.list[idx]->name, cookies.list[idx]->value);
            }
        }

        free(line);
        delete_all_cookies(&cookies);
        free(cookies.list);
    }

    return 0;
}
