#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <memory>
#include <unistd.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <algorithm>
#include <stdexcept>
#include "ringbuffer.hpp"
#include "swtr_ringbuffer_impl.hpp"

using namespace swtr;

static int G_ERROR_MODE = 0;

void transform_identity(std::vector<uint8_t>& data, size_t& size) {
}

void transform_uppercase(std::vector<uint8_t>& data, size_t& size) {
    for (size_t i = 0; i < size; ++i) {
        if (data[i] >= 'a' && data[i] <= 'z') data[i] -= 32;
    }
}

void transform_xor(std::vector<uint8_t>& data, size_t& size) {
    for (size_t i = 0; i < size; ++i) data[i] ^= 0xFF;
}

int test_error_handler(size_t slot_idx, BufferStatus status) {
    return (G_ERROR_MODE == 1) ? 1 : 0;
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " [-o output_file] [-l log_file] [-s slots] [-b size] [-t transform_type] [-e error_mode] [-r] [-w <ip:port>] <input_file>" << std::endl;
        return 1;
    }

    std::string input_file = argv[argc - 1];
    std::string output_file = "stdout";
    std::string log_file = "stderr";
    size_t slots = 4;
    size_t buffer_size = 4096;
    int transform_type = 0;
    G_ERROR_MODE = 0;
    bool use_read_socket = false;
    std::string write_socket_addr = "";

    for (int i = 1; i < argc - 1; ++i) {
        std::string arg = argv[i];
        if (arg == "-o" && i + 1 < argc - 1) output_file = argv[++i];
        else if (arg == "-l" && i + 1 < argc - 1) log_file = argv[++i];
        else if (arg == "-s" && i + 1 < argc - 1) slots = std::stoul(argv[++i]);
        else if (arg == "-b" && i + 1 < argc - 1) buffer_size = std::stoul(argv[++i]);
        else if (arg == "-t" && i + 1 < argc - 1) transform_type = std::stoi(argv[++i]);
        else if (arg == "-e" && i + 1 < argc - 1) G_ERROR_MODE = std::stoi(argv[++i]);
        else if (arg == "-r") use_read_socket = true;
        else if (arg == "-w" && i + 1 < argc - 1) write_socket_addr = argv[++i];
    }

    try {
        TransformFn tfn = nullptr;
        if (transform_type == 1) tfn = transform_uppercase;
        else if (transform_type == 2) tfn = transform_xor;

        auto rb = std::make_unique<SwtrRingBuffer>(slots, BufferStatus::readyforread, buffer_size, test_error_handler, tfn);

        if (output_file == "stdout") {
            rb->set_write_fd(STDOUT_FILENO);
        } else {
            int fd = open(output_file.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0644);
            if (fd == -1) throw std::runtime_error("Cannot open output file");
            rb->set_write_fd(fd);
        }

        if (log_file == "stderr") {
            rb->set_output_stream(std::cerr);
        } else {
            std::ofstream log_fs(log_file);
            rb->set_output_stream(log_fs);
        }

        if (use_read_socket) {
            int s = socket(AF_INET, SOCK_STREAM, 0);
            int opt = 1;
            setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
            struct sockaddr_in addr{};
            addr.sin_family = AF_INET;
            addr.sin_addr.s_addr = INADDR_ANY;
            addr.sin_port = 0;
            if (bind(s, (struct sockaddr*)&addr, sizeof(addr)) == -1) throw std::runtime_error("Bind failed");
            if (listen(s, 1) == -1) throw std::runtime_error("Listen failed");
            
            socklen_t len = sizeof(addr);
            getsockname(s, (struct sockaddr*)&addr, &len);
            std::cout << "LISTEN_PORT=" << ntohs(addr.sin_port) << std::endl;
            
            int client = accept(s, nullptr, nullptr);
            if (client == -1) throw std::runtime_error("Accept failed");
            rb->set_read_fd(client);
            close(s);
        } else {
            int fd = open(input_file.c_str(), O_RDONLY);
            if (fd == -1) throw std::runtime_error("Cannot open input file");
            rb->set_read_fd(fd);
        }

        if (!write_socket_addr.empty()) {
            size_t colon = write_socket_addr.find(':');
            std::string ip = write_socket_addr.substr(0, colon);
            int port = std::stoi(write_socket_addr.substr(colon + 1));
            int s = socket(AF_INET, SOCK_STREAM, 0);
            struct sockaddr_in addr{};
            addr.sin_family = AF_INET;
            addr.sin_port = htons(port);
            inet_pton(AF_INET, ip.c_str(), &addr.sin_addr);
            if (connect(s, (struct sockaddr*)&addr, sizeof(addr)) == -1) throw std::runtime_error("Connect failed");
            rb->set_write_fd(s);
        }

        rb->start();
        rb->wait();
        rb->stop();

    } catch (const std::exception& e) {
        std::cerr << "Exception: " << e.what() << std::endl;
        return 1;
    }

    return (G_ERROR_MODE == 1) ? 1 : 0;
}
