cmake_minimum_required(VERSION 2.8.2)
project(test_proj)

option(CUSTOM_OP "Test option" OFF)
option(ENABLE_TESTS "Enables tests" OFF)

set (CMAKE_CXX_STANDARD 17)
set (CMAKE_CXX_EXTENSIONS OFF)
set (CMAKE_CXX_STANDARD_REQUIRED ON)
if (APPLE OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set (CMAKE_CXX_FLAGS "-std=c++11 ${CMAKE_CXX_FLAGS}")
endif()

add_subdirectory(lib)
add_subdirectory(app)

# Disabled by default library which has some compilations errors
add_subdirectory(incorrect_lib)

add_executable(MakefileDemo makefile_main.cpp) # because make cannot build targets of subdirectories
add_executable(MakefilePathWithSpaces "folder with spaces/test.cpp")

if (ENABLE_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
