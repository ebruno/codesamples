#include <iostream>
#include <fstream>
#include <fcntl.h>
#include <unistd.h>
#include <getopt.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <algorithm>
#include <cctype>
#include <vector>
#include <string>
#include "swtr_ringbuffer_impl.hpp"

void print_usage(const char* prog_name) {
    std::cout << "Usage: " << prog_name << " [-o output_file] [-l log_file] [-s slots] [-b size] [-t transform_type] [-e error_mode] [-r] [-w <ip:port>] <input_file>\n"
              << "Options:\n"
              << "  -o output_file    File to use for write_fd (default: stdout)\n"
              << "  -l log_file       File to use for logger output (default: stderr)\n"
              << "  -s slots          Number of slots (default: 4)\n"
              << "  -b size           Buffer size per slot (default: 4096)\n"
              << "  -t transform_type Transformation: 0=None, 1=Uppercase, 2=XOR 0xFF\n"
              << "  -e error_mode     Error simulation: 0=None, 1=Fatal, 2=Non-fatal\n"
              << "  -r                Attach read_fd to socket (listen on 127.0.0.1)\n"
              << "  -w ip:port        Attach write_fd to socket (connect to ip:port)\n"
              << std::endl;
}

// Error Handler implementations
int fatal_error_handler(size_t slot_idx, swtr::BufferStatus status) {
    return 1;
}

int non_fatal_error_handler(size_t slot_idx, swtr::BufferStatus status) {
    return 0;
}

int main(int argc, char* argv[]) {
    std::string input_filename;
    std::string output_filename;
    std::string log_filename;
    int slots = 4;
    int buffer_size = 4096;
    int transform_type = 0;
    int error_mode = 0;
    bool use_read_socket = false;
    std::string write_socket_addr;

    int opt;
    while ((opt = getopt(argc, argv, "o:l:s:b:t:e:rw:")) != -1) {
        switch (opt) {
            case 'o':
                output_filename = optarg;
                break;
            case 'l':
                log_filename = optarg;
                break;
            case 's':
                slots = std::stoi(optarg);
                break;
            case 'b':
                buffer_size = std::stoi(optarg);
                break;
            case 't':
                transform_type = std::stoi(optarg);
                break;
            case 'e':
                error_mode = std::stoi(optarg);
                break;
            case 'r':
                use_read_socket = true;
                break;
            case 'w':
                write_socket_addr = optarg;
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

    int read_fd = -1;
    int write_fd = STDOUT_FILENO;

    // Setup read_fd
    if (use_read_socket) {
        int listen_sock = socket(AF_INET, SOCK_STREAM, 0);
        if (listen_sock == -1) {
            std::perror("Socket creation failed");
            return 1;
        }

        sockaddr_in addr{};
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = inet_addr("127.0.0.1");
        addr.sin_port = 0; // Let OS pick port

        if (bind(listen_sock, (struct sockaddr*)&addr, sizeof(addr)) == -1) {
            std::perror("Bind failed");
            close(listen_sock);
            return 1;
        }

        socklen_t len = sizeof(addr);
        getsockname(listen_sock, (struct sockaddr*)&addr, &len);
        std::cout << "LISTEN_PORT=" << ntohs(addr.sin_port) << "\n";

        if (listen(listen_sock, 1) == -1) {
            std::perror("Listen failed");
            close(listen_sock);
            return 1;
        }

        read_fd = accept(listen_sock, nullptr, nullptr);
        close(listen_sock); // We only need the accepted socket

        if (read_fd == -1) {
            std::perror("Accept failed");
            return 1;
        }
    } else {
        read_fd = open(input_filename.c_str(), O_RDONLY);
        if (read_fd == -1) {
            std::perror("Error opening input file");
            return 1;
        }
    }

    // Setup write_fd
    if (!write_socket_addr.empty()) {
        size_t colon_pos = write_socket_addr.find(':');
        if (colon_pos == std::string::npos) {
            std::cerr << "Error: Invalid write socket format. Expected IP:PORT" << std::endl;
            if (read_fd != -1) close(read_fd);
            return 1;
        }

        std::string ip = write_socket_addr.substr(0, colon_pos);
        int port = std::stoi(write_socket_addr.substr(colon_pos + 1));

        int sock = socket(AF_INET, SOCK_STREAM, 0);
        if (sock == -1) {
            std::perror("Socket creation failed for write");
            if (read_fd != -1) close(read_fd);
            return 1;
        }

        sockaddr_in server_addr{};
        server_addr.sin_family = AF_INET;
        server_addr.sin_port = htons(port);
        if (inet_pton(AF_INET, ip.c_str(), &server_addr.sin_addr) <= 0) {
            std::cerr << "Invalid IP address: " << ip << std::endl;
            close(sock);
            if (read_fd != -1) close(read_fd);
            return 1;
        }

        if (connect(sock, (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1) {
            std::perror("Connect failed to write socket");
            close(sock);
            if (read_fd != -1) close(read_fd);
            return 1;
        }
        write_fd = sock;
    } else if (!output_filename.empty()) {
        write_fd = open(output_filename.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (write_fd == -1) {
            std::perror("Error opening output file");
            if (read_fd != -1) close(read_fd);
            return 1;
        }
    }

    try {
        swtr::RingBufferImpl rb(slots, swtr::BufferStatus::READY_FOR_READ, buffer_size);

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

        // Define transformation
        std::function<void(std::vector<uint8_t>&, size_t&)> transform = nullptr;
        if (transform_type == 1) {
            transform = [](std::vector<uint8_t>& data, size_t& len) {
                for (size_t i = 0; i < len; ++i) {
                    data[i] = static_cast<uint8_t>(std::toupper(static_cast<unsigned char>(data[i])));
                }
            };
        } else if (transform_type == 2) {
            transform = [](std::vector<uint8_t>& data, size_t& len) {
                for (size_t i = 0; i < len; ++i) {
                    data[i] = data[i] ^ 0xFF;
                }
            };
        }

        // Define error handler
        int (*handler)(size_t, swtr::BufferStatus) = nullptr;
        if (error_mode == 1) {
            handler = fatal_error_handler;
        } else if (error_mode == 2) {
            handler = non_fatal_error_handler;
        } else {
            handler = [](size_t, swtr::BufferStatus) { return 0; };
        }

        rb.start(read_fd, write_fd, transform, handler);

        std::cout << "waiting for ringbuffer" << std::endl;
        rb.wait();
        std::cout.flush();

        if (error_mode == 1) {
            return 1;
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception: " << e.what() << std::endl;
        if (read_fd != -1) close(read_fd);
        if (write_fd != STDOUT_FILENO) close(write_fd);
        return 1;
    }

    if (read_fd != -1) close(read_fd);
    if (write_fd != STDOUT_FILENO) close(write_fd);
    return 0;
}
