#include <test_class.hpp>
#include <iostream>
#include <string>
#include <filesystem>

std::string get_cwd() {
    std::string path = std::filesystem::current_path();
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
