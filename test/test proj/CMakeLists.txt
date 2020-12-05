cmake_minimum_required(VERSION 2.8.2)
project(test_proj)

option(CUSTOM_OP "Test option" ON)

if(NOT DEFINED CMAKE_CXX_STANDARD)
    set (CMAKE_CXX_STANDARD 11)
    set (CMAKE_CXX_EXTENSIONS OFF)
    set (CMAKE_CXX_STANDARD_REQUIRED ON)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set (CMAKE_CXX_FLAGS "-std=c++11 ${CMAKE_CXX_FLAGS}")
    endif()
endif()

add_subdirectory(lib)
add_subdirectory(app)

# Disabled by default library which has some compilations errors
add_subdirectory(incorrect_lib)

enable_testing()
add_subdirectory(tests)
