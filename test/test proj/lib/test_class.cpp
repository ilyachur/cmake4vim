#include "test_class.hpp"
#include <iostream>

using namespace TestLib;

TestClass::TestClass() {}

void TestClass::f1() {
    std::cout << "F1" << std::endl;
}

void TestClass::f2() {
#if defined(CUSTOM_OP)
    std::cout << "F2 custom" << std::endl;
#else
    std::cout << "F2 default" << std::endl;
#endif
}
