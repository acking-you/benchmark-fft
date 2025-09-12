#include "fft.hpp"
#include <iostream>
#include <vector>
#include <chrono>
#include <fstream>
#include <sstream>
#include <format>
#include <cmath>
#include <numbers>

// Enable mimalloc as global allocator
#include <mimalloc-override.h>

constexpr double round_precision(double n) {
    return std::round(n * 100.0) / 100.0;
}

std::vector<Complex> generate_inputs(size_t len) {
    std::vector<Complex> res;
    res.reserve(len);
    
    for (size_t i = 0; i < len; ++i) {
        const double theta = static_cast<double>(i) / static_cast<double>(len) * std::numbers::pi;
        const double re = 1.0 * std::cos(10.0 * theta) + 0.5 * std::cos(25.0 * theta);
        const double im = 1.0 * std::sin(10.0 * theta) + 0.5 * std::sin(25.0 * theta);
        res.emplace_back(round_precision(re), round_precision(im));
    }
    
    return res;
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << std::format("usage: {} <size>\\n", argv[0]);
        return 1;
    }
    
    const int size = std::stoi(argv[1]);
    if (size < 0) {
        std::cerr << "invalid <size>; must be a non-negative integer\\n";
        return 1;
    }
    
    auto signals = generate_inputs(1ULL << size);
    
    const auto start = std::chrono::high_resolution_clock::now();
    FFT::fft(signals);
    const auto end = std::chrono::high_resolution_clock::now();
    
    if (argc > 2) {
        // Verification mode
        std::ifstream file(argv[2]);
        if (!file.is_open()) {
            std::cerr << std::format("Could not open file: {}\\n", argv[2]);
            return 1;
        }
        
        std::string line;
        size_t index = 0;
        while (std::getline(file, line) && index < signals.size()) {
            std::istringstream iss(line);
            std::string re_str, im_str;
            
            if (std::getline(iss, re_str, ',') && std::getline(iss, im_str)) {
                const double expected_re = std::stod(re_str);
                const double expected_im = std::stod(im_str);
                const Complex expected{expected_re, expected_im};
                
                if (signals[index] != expected) {
                    std::cerr << std::format("Mismatch at index {}: expected ({}, {}), got ({}, {})\\n",
                                           index, expected.real(), expected.imag(),
                                           signals[index].real(), signals[index].imag());
                    return 1;
                }
            }
            ++index;
        }
    } else {
        const auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start);
        const double ms = static_cast<double>(duration.count()) / 1'000'000.0;
        std::cout << std::format("execution time: {:.3f} ms\\n", ms);
    }
    
    return 0;
}