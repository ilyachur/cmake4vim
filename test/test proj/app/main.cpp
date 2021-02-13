#include <test_class.hpp>
#include <iostream>

int main(int argc, const char *argv[])
{
    TestLib::TestClass c;
    for (int i = 1; i < argc; i++)
        std::cout << argv[i] << " ";
    std::cout << c.f1() << std::endl;
    if (c.f2() != "F2 default")
        return 1;
    return 0;
}
