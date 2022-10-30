set (TARGET_NAME unit_tests)

add_executable(${TARGET_NAME} src/main.cpp
                              src/test_class.cpp)

find_package(GTest QUIET)

if (NOT GTEST_FOUND)
    configure_file(CMakeLists.txt.in googletest-download/CMakeLists.txt)
    execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
        RESULT_VARIABLE result
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/googletest-download )
    if(result)
        message(FATAL_ERROR "CMake step for googletest failed: ${result}")
    endif()
    execute_process(COMMAND ${CMAKE_COMMAND} --build .
        RESULT_VARIABLE result
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/googletest-download )
    if(result)
        message(FATAL_ERROR "Build step for googletest failed: ${result}")
    endif()

    # Prevent overriding the parent project's compiler/linker
    # settings on Windows
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

    # Add googletest directly to our build. This defines
    # the gtest and gtest_main targets.
    add_subdirectory(${CMAKE_CURRENT_BINARY_DIR}/googletest-src
        ${CMAKE_CURRENT_BINARY_DIR}/googletest-build
        EXCLUDE_FROM_ALL)

    # The gtest/gtest_main targets carry header search path
    # dependencies automatically when using CMake 2.8.11 or
    # later. Otherwise we have to add them here ourselves.
    if (CMAKE_VERSION VERSION_LESS 2.8.11)
        target_include_directories(${TARGET_NAME} PRIVATE "${gtest_SOURCE_DIR}/include")
    endif()
    set(GTEST_LIBRARIES gtest)
else()
    target_include_directories(${TARGET_NAME} PRIVATE ${GTEST_INCLUDE_DIRS})
endif()

target_link_libraries(${TARGET_NAME} PRIVATE ${GTEST_LIBRARIES} test_lib)
add_test(NAME ${TARGET_NAME} COMMAND ${TARGET_NAME})
