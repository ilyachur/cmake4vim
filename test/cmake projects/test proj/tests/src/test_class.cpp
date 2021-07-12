#include <gtest/gtest.h>
#include <test_class.hpp>
#include <string>
#include <map>

using namespace TestLib;

TEST(TestClassTests, TestMethodF1) {
    TestClass m;
    ASSERT_EQ(m.f1(), "F1");
}

TEST(TestClassTests, TestMethodF2) {
    TestClass m;
    ASSERT_EQ(m.f2(), "F2 default");
}
