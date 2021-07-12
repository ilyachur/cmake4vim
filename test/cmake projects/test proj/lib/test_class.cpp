#include "test_class.hpp"

using namespace TestLib;

TestClass::TestClass() {}

std::string TestClass::f1() {
    return "F1";
}

std::string TestClass::f2() {
#if defined(CUSTOM_OP)
    return "F2 custom";
#else
    return "F2 default";
#endif
}
