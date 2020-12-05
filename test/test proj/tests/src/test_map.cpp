#include <gtest/gtest.h>
#include <test_map.hpp>
#include <string>
#include <map>

using namespace TestLib;

TEST(TestMap, CreateEmptyMap) {
    CustomMap<std::string, int> map;
    ASSERT_TRUE(map.empty());
}

TEST(TestMap, CreateMapWithUniqueVal) {
    std::map<std::string, int> mmap;
    mmap["test"] = 1;
    mmap["test2"] = 2;
    CustomMap<std::string, int> map(mmap);
    ASSERT_TRUE(!map.empty());
    ASSERT_EQ(map.size(), 2);
}

TEST(TestMap, CreateMapWithoutUniqueVal) {
    std::map<std::string, int> mmap;
    mmap["test"] = 1;
    mmap["test2"] = 1;
    CustomMap<std::string, int> map(mmap);
    ASSERT_TRUE(!map.empty());
    ASSERT_EQ(map.size(), 1);
}
