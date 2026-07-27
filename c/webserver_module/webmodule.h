/**
 * @file webmodule.h
 * @brief Header file for the cookie management module.
 * 
 * This module provides functionality to initialize, manage, search, 
 * and sort a collection of cookies extracted from HTTP headers.
 */

#ifndef _WEBMODULE_H_
#define _WEBMODULE_H_

#include <sys/errno.h>

/** @name Version and Configuration Constants */
/**@{*/
#define COOKIE_CURRENT_VERSION 1    ///< Current version of a single cookie
#define COOKIES_CURRENT_VERSION 1   ///< Current version of the cookie collection
#define COOKIE_EXTEND_SIZE  10      ///< Default increment when extending cookie list capacity
/**@}*/

/** @name Status Codes */
/**@{*/
#define OK_TO_CONTINUE  0           ///< Operation completed successfully
#define ERROR_ENCOUNTERED 1         ///< An error occurred during operation
/**@}*/

#define EQUAL_SIGN '='              ///< Character separating cookie name and value

/** @name Boolean Definitions */
/**@{*/
#ifndef WB_TRUE
#define WB_TRUE 1
#endif
#ifndef WB_FALSE
#define WB_FALSE 0
#endif
/**@}*/

/**
 * @struct COOKIE
 * @brief Represents a single HTTP cookie.
 */
typedef struct _COOKIE {
    int version;    ///< Version of the cookie structure
    char *name;     ///< Pointer to the cookie name string
    char *value;    ///< Pointer to the cookie value string
} COOKIE;

/**
 * @struct COOKIES
 * @brief Represents a collection of cookies.
 */
typedef struct _COOKIES {
    int version;            ///< Version of the collection structure
    int max_entries;        ///< Maximum capacity of the current list
    int count_entries;      ///< Current number of cookies stored
    int free_entries;       ///< Number of available slots before extension is needed
    int extend_increment;   ///< Amount to increase capacity during extension
    COOKIE **list;          ///< Dynamic array of pointers to COOKIE structures
} COOKIES;

/**
 * @brief Sorts the cookies in the collection by name.
 * @param cookies Pointer to the COOKIES collection.
 * @return int Returns 0 on success.
 */
int sort_cookies(COOKIES *cookies);

/**
 * @brief Initializes a COOKIES collection with a specified version and initial size.
 * @param cookies      Pointer to the COOKIES structure to initialize.
 * @param version      The version number to assign to the collection.
 * @param extend_size  The initial number of cookie slots to allocate.
 * @return int         Returns 0 on success, or ERROR_ENCOUNTERED on failure.
 */
int init_cookies(COOKIES *cookies, int version, int extend_size);

/**
 * @brief Extends the capacity of the internal cookie list.
 * @param cookies Pointer to the COOKIES collection.
 * @return int    Returns 0 on success, or ERROR_ENCOUNTERED if memory allocation fails.
 */
int extend_cookies(COOKIES *cookies);

/**
 * @brief Adds a new cookie to the collection or updates an existing one.
 * @param cookies Pointer to the COOKIES collection.
 * @param cookie  String in "name=value" format.
 * @param no_dupe If true, prevents duplicate cookie names by updating existing ones.
 * @return int    Returns OK_TO_CONTINUE on success, or ERROR_ENCOUNTERED on failure.
 */
int add_cookie(COOKIES *cookies, char *cookie, int no_dupe);

/**
 * @brief Finds a cookie in the collection by its name.
 * @param cookies Pointer to the COOKIES collection.
 * @param cookie  Pointer to a COOKIE containing the name to search for.
 * @return COOKIE* Pointer to the found cookie, or NULL if not found.
 */
COOKIE *find_cookie(COOKIES *cookies, COOKIE *cookie);

/**
 * @brief Internal helper to locate a cookie index using binary search.
 * @param cookies Pointer to the COOKIES collection.
 * @param cookie  Pointer to a COOKIE containing the name to search for.
 * @param low     Lower bound index of the search range.
 * @param high    Upper bound index of the search range.
 * @return int    Index of the cookie if found, otherwise -1.
 */
int locate_cookie(COOKIES *cookies, COOKIE *cookie, int low, int high);

/**
 * @brief Deletes all cookies and frees associated memory.
 * @param cookies Pointer to the COOKIES collection.
 * @return int    Returns OK_TO_CONTINUE on success.
 */
int delete_all_cookies(COOKIES *cookies);

/**
 * @brief Frees memory for a specific cookie's name and value.
 * @param cookie Pointer to the COOKIE structure to delete.
 * @return int   Always returns OK_TO_CONTINUE.
 */
int delete_cookie(COOKIE *cookie);

#endif
