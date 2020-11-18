cmake_minimum_required(VERSION 2.8)
project(test_proj)

option(CUSTOM_OP "Test option" ON)

add_subdirectory(lib)
if (CUSTOM_OP)
    add_subdirectory(app)
endif()

# Disabled by default library which has some compilations errors
add_subdirectory(incorrect_lib)
