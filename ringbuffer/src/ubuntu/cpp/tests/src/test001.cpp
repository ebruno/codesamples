#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"
#include <fcntl.h>
#include <iostream>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <cstring>

// Error handler function (must be a plain function pointer, not a lambda)
static int test_error_handler(size_t slot_idx, swtr::BufferStatus status) {
    (void)slot_idx; (void)status;
    // Default: non-fatal error - pipeline continues
    return 0;
}

void usage(const char* prog) {
    std::cerr << "Usage: " << prog 
              << " [-o output_file] [-l log_file] [-s slots] [-b size]"
              << " [-t transform_type] [-e error_mode] [-r] [-w <ip:port>] <input_file>"
              << std::endl;
}

int main(int argc, char* argv[]) {
    const char* output_file = nullptr;
    const char* log_file = nullptr;
    int slots = 4;
    size_t buffer_size = 4096;
    int transform_type = 0;
    int error_mode = 0;
    bool use_socket_read = false;
    std::string write_addr;
    
    // Parse arguments
    int opt;
    while ((opt = getopt(argc, argv, "o:l:s:b:t:e:rw:")) != -1) {
        switch (opt) {
            case 'o': output_file = optarg; break;
            case 'l': log_file = optarg; break;
            case 's': slots = std::atoi(optarg); break;
            case 'b': buffer_size = std::stoul(optarg); break;
            case 't': transform_type = std::atoi(optarg); break;
            case 'e': error_mode = std::atoi(optarg); break;
            case 'r': use_socket_read = true; break;
            case 'w': write_addr = optarg; break;
            default: usage(argv[0]); return 1;
        }
    }
    
    if (optind >= argc) {
        usage(argv[0]);
        return 1;
    }
    
    const char* input_file = argv[optind];
    
    // Setup logging
    std::ostream* log_stream = &std::cerr;
    if (log_file) {
        // In a real implementation, we'd open the file and store pointer
        log_stream = &std::cerr; // Simplified for now
    }
    
    // Setup transform function
    std::function<void(std::vector<uint8_t>&, size_t&)> transform_fn = nullptr;
    if (transform_type == 1) {
        transform_fn = [](std::vector<uint8_t>& data, size_t& size) {
            for (size_t i = 0; i < size; ++i) {
                data[i] = std::toupper(data[i]);
            }
        };
    } else if (transform_type == 2) {
        transform_fn = [](std::vector<uint8_t>& data, size_t& size) {
            for (size_t i = 0; i < size; ++i) {
                data[i] ^= 0xFF;
            }
        };
    }
    
    // Setup error handler (must be a function pointer, not a lambda)
    swtr::ErrorHandler err_handler = nullptr;
    if (error_mode == 1 || error_mode == 2) {
        err_handler = test_error_handler;
    }
    
    try {
        // Open input file
        int fd_in = open(input_file, O_RDONLY);
        if (fd_in == -1) {
            std::cerr << "ERROR: Cannot open input file: " << input_file << std::endl;
            return 1;
        }
        
        int read_fd = fd_in;
        int write_fd = STDOUT_FILENO;
        
        // Handle socket read mode
        if (use_socket_read) {
            int server_fd = socket(AF_INET, SOCK_STREAM, 0);
            if (server_fd == -1) {
                std::cerr << "ERROR: Socket creation failed" << std::endl;
                close(fd_in);
                return 1;
            }
            
            int opt_val = 1;
            if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt_val, sizeof(opt_val)) == -1) {
                std::cerr << "ERROR: setsockopt failed" << std::endl;
                close(server_fd);
                close(fd_in);
                return 1;
            }
            
            struct sockaddr_in addr;
            memset(&addr, 0, sizeof(addr));
            addr.sin_family = AF_INET;
            addr.sin_addr.s_addr = INADDR_ANY;
            addr.sin_port = 0; // Let kernel assign port
            
            if (bind(server_fd, (struct sockaddr*)&addr, sizeof(addr)) == -1) {
                std::cerr << "ERROR: bind failed" << std::endl;
                close(server_fd);
                close(fd_in);
                return 1;
            }
            
            socklen_t addr_len = sizeof(addr);
            if (getsockname(server_fd, (struct sockaddr*)&addr, &addr_len) == -1) {
                std::cerr << "ERROR: getsockname failed" << std::endl;
                close(server_fd);
                close(fd_in);
                return 1;
            }
            
            int port = ntohs(addr.sin_port);
            std::cout << "LISTEN_PORT=" << port << std::endl;
            
            if (listen(server_fd, 1) == -1) {
                std::cerr << "ERROR: listen failed" << std::endl;
                close(server_fd);
                close(fd_in);
                return 1;
            }
            
            std::cout.flush();
            
            int client_fd = accept(server_fd, nullptr, nullptr);
            if (client_fd == -1) {
                std::cerr << "ERROR: accept failed" << std::endl;
                close(server_fd);
                close(fd_in);
                return 1;
            }
            
            read_fd = client_fd;
            close(server_fd);
        }
        
        // Handle socket write mode
        if (!write_addr.empty()) {
            auto colon_pos = write_addr.find(':');
            if (colon_pos == std::string::npos) {
                std::cerr << "ERROR: Invalid write address format (expected ip:port)" << std::endl;
                close(fd_in);
                return 1;
            }
            
            std::string ip = write_addr.substr(0, colon_pos);
            int port = std::atoi(write_addr.substr(colon_pos + 1).c_str());
            
            int sock = socket(AF_INET, SOCK_STREAM, 0);
            if (sock == -1) {
                std::cerr << "ERROR: Socket creation failed" << std::endl;
                close(fd_in);
                return 1;
            }
            
            struct sockaddr_in server_addr;
            memset(&server_addr, 0, sizeof(server_addr));
            server_addr.sin_family = AF_INET;
            server_addr.sin_port = htons(port);
            
            if (inet_pton(AF_INET, ip.c_str(), &server_addr.sin_addr) <= 0) {
                std::cerr << "ERROR: Invalid IP address" << std::endl;
                close(sock);
                close(fd_in);
                return 1;
            }
            
            if (connect(sock, (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1) {
                std::cerr << "ERROR: Connection failed" << std::endl;
                close(sock);
                close(fd_in);
                return 1;
            }
            
            write_fd = sock;
        }
        
        // Create ring buffer
        auto rb = std::make_unique<swtr::SwtrRingBuffer>(slots, swtr::BufferStatus::readyforread, buffer_size, err_handler, transform_fn);
        
        rb->set_read_fd(read_fd);
        rb->set_write_fd(write_fd);
        
        // Start processing
        rb->start();
        rb->wait();
        
        std::cout.flush();
        
        // Cleanup
        if (read_fd != fd_in) close(read_fd);
        close(fd_in);
        
    } catch (const std::exception& e) {
        std::cerr << "ERROR: " << e.what() << std::endl;
        return 1;
    }
    
    return error_mode == 1 ? 1 : 0;
}
