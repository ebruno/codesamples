#include <iostream>
#include <fstream>
#include <fcntl.h>
#include <unistd.h>
#include <unistd.h>
#include "swtr_ringbuffer_impl.hpp"

void print_usage(const char* prog_name) {
    std::cout << "Usage: " << prog_name << " [-o output_file] [-l log_file] <input_file>\n"
              << "Options:\n"
              << "  -o output_file  File to use for write_fd (default: stdout)\n"
              << "  -l log_file     File to use for logger output (default: stderr)\n"
              << std::endl;
}

int main(int argc, char* argv[]) {
    std::string input_filename;
    std::string output_filename;
    std::string log_filename;

    int opt;
    while ((opt = getopt(argc, argv, "o:l:")) != -1) {
        switch (opt) {
            case 'o':
                output_filename = optarg;
                break;
            case 'l':
                log_filename = optarg;
                break;
            default:
                print_usage(argv[0]);
                return 1;
        }
    }

    if (optind < argc) {
        input_filename = argv[optind];
    } else {
        std::cerr << "Error: Input file is required." << std::endl;
        print_usage(argv[0]);
        return 1;
    }

    // Open input file
    int read_fd = open(input_filename.c_str(), O_RDONLY);
    if (read_fd == -1) {
        std::perror("Error opening input file");
        return 1;
    }

    // Open output file if specified, otherwise use stdout
    int write_fd = STDOUT_FILENO;
    if (!output_filename.empty()) {
        write_fd = open(output_filename.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (write_fd == -1) {
            std::perror("Error opening output file");
            close(read_fd);
            return 1;
        }
    }

    try {
        swtr::RingBufferImpl rb(5);

        // Configure Logger
        if (!log_filename.empty()) {
            static std::ofstream log_file;
            log_file.open(log_filename, std::ios::out | std::ios::trunc);
            if (!log_file.is_open()) {
                std::cerr << "Error: Could not open log file " << log_filename << std::endl;
                throw std::runtime_error("Log file open failed");
            }
            rb.set_output_stream(log_file);
        }

        std::cout << "waiting for ringbuffer" << std::endl;
        rb.start(read_fd, write_fd, nullptr, nullptr);

        rb.wait();
        std::cout.flush();
    } catch (const std::exception& e) {
        std::cerr << "Exception: " << e.what() << std::endl;
        close(read_fd);
        if (write_fd != STDOUT_FILENO) close(write_fd);
        return 1;
    }

    close(read_fd);
    if (write_fd != STDOUT_FILENO) close(write_fd);
    return 0;
}
