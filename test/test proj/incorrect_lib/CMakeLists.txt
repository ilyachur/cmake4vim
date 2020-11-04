set (TARGET_NAME "incorrect_lib")

set (SRC incorrect_class.hpp incorrect_class.cpp)

add_library(${TARGET_NAME} EXCLUDE_FROM_ALL STATIC ${SRC})
