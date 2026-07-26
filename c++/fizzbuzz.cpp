#include <iostream>
#include <format>
#include <string_view>
#include <ranges>
#include <vector>

/**
 * @brief Performs the FizzBuzz logic over a specified range.
 * 
 * @param start         The starting integer of the range.
 * @param end           The ending integer of the range (inclusive).
 * @param step          The increment value between iterations.
 * @param modulo_fizz   The divisor that triggers "fizz".
 * @param modulo_buzz   The divisor that triggers "buzz".
 */
void run_fizzbuzz(int start, int end, int step, int modulo_fizz, int modulo_buzz) {
    // Create a range from start to end with the given step
    for (int value = start; value <= end; value += step) {
        bool fizz = (value % modulo_fizz == 0);
        bool buzz = (value % modulo_buzz == 0);

        if (fizz && buzz) {
            std::cout << "fizzbuzz\n";
        } else if (fizz) {
            std::cout << "fizz\n";
        } else if (buzz) {
            std::cout << "buzz\n";
        } else {
            std::cout << std::format("{}\n", value);
        }
    }
}

int main() {
    // Use constexpr for configuration to allow compile-time optimization
    constexpr int start        = 1;
    constexpr int end          = 100;
    constexpr int step         = 1;
    constexpr int modulo_fizz  = 3;
    constexpr int modulo_buzz  = 5;

    run_fizzbuzz(start, end, step, modulo_fizz, modulo_buzz);

    return 0;
}
