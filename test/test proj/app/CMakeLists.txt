set (TARGET_NAME "test_app")

set(SRC main.cpp)

add_executable(${TARGET_NAME} ${SRC})
target_include_directories(${TARGET_NAME} PRIVATE "${CMAKE_SOURCE_DIR}/lib/")
target_link_libraries(${TARGET_NAME} PRIVATE test_lib)
