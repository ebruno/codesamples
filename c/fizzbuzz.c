/**
 * File: fizzbuzz.c
 * Standard: C17/C18 (Fallback from C23 due to compiler compatibility)
 * Compiler: Apple clang version 21.0.0
 * Missing C23 Features: constexpr, auto
 */

#include <stdio.h>
#include <string.h>
#include <stdbool.h>

/**
 * @brief Performs the FizzBuzz logic over a range of numbers.
 *
 * This function iterates from start to end with a given step and prints
 * "fizz" if the value is divisible by modulo_fizz, "buzz" if divisible by
 * modulo_buzz, both if divisible by both, or the value itself otherwise.
 *
 * @param start       The starting value of the range.
 * @param end         The ending value of the range.
 * @param step        The increment value for each iteration.
 * @param modulo_fizz The divisor that triggers the "fizz" output.
 * @param modulo_buzz The divisor that triggers the "buzz" output.
 * @return int        Returns 0 on success, or -1 if invalid parameters are provided.
 */
int fizzbuzz(int start, int end, int step, int modulo_fizz, int modulo_buzz) {
    if (step <= 0 || modulo_fizz <= 0 || modulo_buzz <= 0) {
        return -1;
    }

    const int max_length = 12;
    char result[max_length + 1];

    for (int value = start; value <= end; value += step) {
        result[0] = '\0';

        if (value % modulo_fizz == 0) {
            strcat(result, "fizz");
        }
        if (value % modulo_buzz == 0) {
            strcat(result, "buzz");
        }

        if (result[0] == '\0') {
            snprintf(result, sizeof(result), "%d", value);
        }
        printf("%s\n", result);
    }
    return 0;
}

/**
 * @brief Entry point of the FizzBuzz application.
 *
 * Initializes default parameters and invokes the fizzbuzz logic.
 *
 * @param argc The number of command line arguments.
 * @param argv The array of command line arguments.
 * @return int The status of the fizzbuzz execution.
 */
int main(int argc, char **argv) {
    (void)argc;
    (void)argv;

    const int start = 1;
    const int end = 100;
    const int step = 1;
    const int modulo_fizz = 3;
    const int modulo_buzz = 5;

    return fizzbuzz(start, end, step, modulo_fizz, modulo_buzz);
}
