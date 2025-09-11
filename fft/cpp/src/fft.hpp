#pragma once

#include <complex>
#include <vector>
#include <numbers>
#include <algorithm>
#include <ranges>
#include <cmath>

using Complex = std::complex<double>;

class FFT {
public:
    static void fft(std::vector<Complex>& arr) {
        _fft(arr);
        
        // Normalize using C++23 ranges
        const double factor = 1.0 / std::sqrt(static_cast<double>(arr.size()));
        std::ranges::for_each(arr, [factor](Complex& x) { x *= factor; });
    }
    
private:
    static void _fft(std::vector<Complex>& arr) {
        const size_t n = arr.size();
        if (n == 1) {
            return;
        }
        
        // Use C++23 ranges to split even and odd elements
        std::vector<Complex> a0, a1;
        a0.reserve(n / 2);
        a1.reserve(n / 2);
        
        // Use ranges with stride to get even/odd elements
        auto even_indices = std::views::iota(0uz, n) | std::views::filter([](size_t i) { return i % 2 == 0; });
        auto odd_indices = std::views::iota(0uz, n) | std::views::filter([](size_t i) { return i % 2 == 1; });
        
        std::ranges::transform(even_indices, std::back_inserter(a0), [&arr](size_t i) { return arr[i]; });
        std::ranges::transform(odd_indices, std::back_inserter(a1), [&arr](size_t i) { return arr[i]; });
        
        _fft(a0);
        _fft(a1);
        
        const double ang = -2.0 * std::numbers::pi / static_cast<double>(n);
        Complex w{1.0, 0.0};
        const Complex wn{std::cos(ang), std::sin(ang)};
        
        // Butterfly operations using C++23 ranges with zip and enumerate
        auto indices = std::views::iota(0uz, n / 2);
        std::ranges::for_each(indices, [&](size_t i) {
            const Complex p = a0[i];
            const Complex q = w * a1[i];
            arr[i] = p + q;
            arr[i + n / 2] = p - q;
            w *= wn;
        });
    }
};