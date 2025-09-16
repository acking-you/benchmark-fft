cmake_minimum_required(VERSION 3.20)
project(fft_benchmark)

# Set C++23 standard
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(mimalloc CONFIG REQUIRED)

# Enable native CPU optimizations with loop unrolling and LTO
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -ffast-math -march=native -mtune=native -funroll-loops -flto -DNDEBUG")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "-flto")  # Enable LTO for linking

# Add executable
add_executable(main src/main.cpp)

# Use mimalloc
target_link_libraries(main PRIVATE $<IF:$<TARGET_EXISTS:mimalloc-static>,mimalloc-static,mimalloc>)

# Set output directory
set_target_properties(main PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)