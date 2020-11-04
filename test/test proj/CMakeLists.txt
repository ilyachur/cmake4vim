cmake_minimum_required(VERSION 2.8)
project(test_proj)

option(CUSTOM_OP "Test option" ON)

add_subdirectory(lib)
add_subdirectory(app)

# Disabled by default library which has some compilations errors
add_subdirectory(incorrect_lib)
