set (TARGET_NAME "test_lib")
set (SRC test_class.hpp test_class.cpp)

if (CUSTOM_OP)
    add_definitions(-DCUSTOM_OP)
endif ()

add_library(${TARGET_NAME} STATIC ${SRC})
