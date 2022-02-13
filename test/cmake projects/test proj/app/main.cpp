#include <test_class.hpp>
#include <iostream>
#include <string>
#ifndef _WIN32
#include <unistd.h>
#include <limits.h>
#endif

std::string get_cwd() {
    std::string path;
#ifdef _WIN32
    // Windows has issue: "The filename, directory name, or volume label syntax is incorrect." on CI
    return "app";
#else
    char buffer[PATH_MAX];
    if (getcwd(buffer, sizeof(buffer)) == NULL) {
        return "";
    }
    path = buffer;
#endif
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
