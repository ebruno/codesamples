#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"
#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <unistd.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <getopt.h>
#include <functional>
#include <memory>
#include <cstring>

using namespace swtr;

// Global for error handler control
int g_error_mode = 0;

int test_error_handler(size_t slot_idx, BufferStatus status) {
    (void)slot_idx;
    (void)status;
    if (g_error_mode == 1) return 1; // Fatal
    if (g_error_mode == 2) return 0; // Non-fatal
    return 0;
}

void print_usage(const char* prog_name) {
    std::cerr << "Usage: " << prog_name << " [-o output_file] [-l log_file] [-s slots] [-b size] [-t transform_type] [-e error_mode] [-r] [-w <ip:port>] <input_file>" << std::endl;
}

int main(int argc, char* argv[]) {
    std::string input_file;
    std::string output_file;
    std::string log_file;
    size_t slots = 4;
    size_t buffer_size = 4096;
    int transform_type = 0;
    g_error_mode = 0;
    bool use_socket_read = false;
    std::string socket_write_addr;

    int opt;
    while ((opt = getopt(argc, argv, "o:l:s:b:t:e:rw:")) != -1) {
        switch (opt) {
            case 'o': output_file = optarg; break;
            case 'l': log_file = optarg; break;
            case 's': slots = std::stoul(optarg); break;
            case 'b': buffer_size = std::stoul(optarg); break;
            case 't': transform_type = std::stoi(optarg); break;
            case 'e': g_error_mode = std::stoi(optarg); break;
            case 'r': use_socket_read = true; break;
            case 'w': socket_write_addr = optarg; break;
            default: print_usage(argv[0]); return 1;
        }
    }

    if (optind >= argc) {
        print_usage(argv[0]);
        return 1;
    }
    input_file = argv[optind];

    // Setup logging
    std::ofstream log_out;
    if (!log_file.empty()) {
        log_out.open(log_file);
        if (!log_out) {
            std::cerr << "Failed to open log file: " << log_file << std::endl;
            return 1;
        }
    }
    
    std::ostream* logger_stream = log_out.is_open() ? &log_out : &std::cerr;

    // Setup transformation
    std::function<void(std::vector<uint8_t>&, size_t&)> transform_fn = nullptr;
    if (transform_type == 1) {
        transform_fn = [](std::vector<uint8_t>& data, size_t& size) {
            for (size_t i = 0; i < size; ++i) {
                if (data[i] >= 'a' && data[i] <= 'z') {
                    data[i] -= 32;
                }
            }
        };
    } else if (transform_type == 2) {
        transform_fn = [](std::vector<uint8_t>& data, size_t& size) {
            for (size_t i = 0; i < size; ++i) {
                data[i] = ~data[i];
            }
        };
    }

    // Initialize RingBuffer
    auto rb = std::make_unique<SwtrRingBuffer>(slots, BufferStatus::readyforread, buffer_size, test_error_handler, transform_fn);
    rb->set_output_stream(*logger_stream);

    // Input FD
    int read_fd = -1;
    if (use_socket_read) {
        int listen_fd = socket(AF_INET, SOCK_STREAM, 0);
        if (listen_fd == -1) return 1;
        
        int optval = 1;
        setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval));

        sockaddr_in addr{};
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = INADDR_ANY;
        addr.sin_port = 0; // Auto-assign port

        if (bind(listen_fd, (struct sockaddr*)&addr, sizeof(addr)) == -1) return 1;
        if (listen(listen_fd, 1) == -1) return 1;

        socklen_t len = sizeof(addr);
        getsockname(listen_fd, (struct sockaddr*)&addr, &len);
        std::cout << "LISTEN_PORT=" << ntohs(addr.sin_port) << std::endl;

        read_fd = accept(listen_fd, nullptr, nullptr);
        close(listen_fd);
        if (read_fd == -1) return 1;
    } else {
        read_fd = open(input_file.c_str(), O_RDONLY);
        if (read_fd == -1) {
            std::cerr << "Failed to open input file: " << input_file << std::endl;
            return 1;
        }
    }
    rb->set_read_fd(read_fd);

    // Output FD
    int write_fd = -1;
    if (!socket_write_addr.empty()) {
        size_t colon_pos = socket_write_addr.find(':');
        if (colon_pos == std::string::npos) return 1;
        
        std::string ip = socket_write_addr.substr(0, colon_pos);
        int port = std::stoi(socket_write_addr.substr(colon_pos + 1));
        
        write_fd = socket(AF_INET, SOCK_STREAM, 0);
        if (write_fd == -1) return 1;
        
        sockaddr_in addr{};
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        if (inet_pton(AF_INET, ip.c_str(), &addr.sin_addr) <= 0) return 1;
        
        if (connect(write_fd, (struct sockaddr*)&addr, sizeof(addr)) == -1) {
            std::cerr << "Failed to connect to " << socket_write_addr << std::endl;
            return 1;
        }
    } else if (!output_file.empty()) {
        write_fd = open(output_file.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (write_fd == -1) return 1;
    } else {
        // Default to stdout (cannot use open(), just use 1)
        write_fd = 1;
    }
    rb->set_write_fd(write_fd);

    // Execute
    rb->start();
    std::cout << "waiting for ringbuffer" << std::endl;
    rb->wait();
    std::cout.flush();

    // Cleanup
    if (read_fd != -1 && read_fd != 1) close(read_fd);
    if (write_fd != -1 && write_fd != 1) close(write_fd);

    return (g_error_mode == 1) ? 1 : 0;
}
