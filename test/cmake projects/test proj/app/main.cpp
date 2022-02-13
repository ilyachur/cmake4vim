#include <test_class.hpp>
#include <iostream>
#include <string>
#include <limits.h>
#ifdef _WIN32
#include <direct.h>
#include <windows.h>

#ifndef PATH_MAX
#define PATH_MAX MAX_PATH
#endif

#else
#include <unistd.h>
#endif

std::string get_cwd() {
    char buffer[PATH_MAX];
#ifdef _WIN32
    _getcwd(buffer, PATH_MAX);
#else
    if (getcwd(buffer, sizeof(buffer)) == NULL) {
        return "";
    }
#endif
    std::string path = buffer;
    size_t found = path.find_last_of("/\\");
    return path.substr(found+1);
}

int main(int argc, const char *argv[])
{
    TestLib::TestClass c;
    for (int i = 1; i < argc; i++)
        std::cout << argv[i] << " ";
    std::cout << c.f1() << " " << get_cwd() << std::endl;
    if (c.f2() != "F2 default")
        return 1;
    return 0;
}
