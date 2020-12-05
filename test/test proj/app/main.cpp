#include <test_class.hpp>
#include <iostream>

int main() {
    TestLib::TestClass c;
    std::cout << c.f1() << std::endl;
    if (c.f2() != "F2 default")
        return 1;
    return 0;
}
