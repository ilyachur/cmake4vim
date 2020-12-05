#pragma once

#include <map>
#include <unordered_set>

namespace TestLib {

template<
    class Key,
    class T,
    class Compare = std::less<Key>,
    class Allocator = std::allocator<std::pair<const Key, T> >
> class CustomMap {
private:
    std::map<Key, T, Compare, Allocator> mmap;

public:
    CustomMap() = default;
    CustomMap(const std::map<Key, T, Compare, Allocator>& map): mmap(map) {}
    CustomMap(std::map<Key, T, Compare, Allocator>&& map) noexcept: mmap(std::move(map)) {}
    CustomMap(const CustomMap& map): mmap(map.mmap) {}
    CustomMap(CustomMap&& map) noexcept: mmap(std::move(map.mmap)) {}
    virtual ~CustomMap() = default;

    CustomMap& operator=(const std::map<Key, T, Compare, Allocator>& map) {
        this->mmap = map;
        return *this;
    }
    CustomMap& operator=(std::map<Key, T, Compare, Allocator>&& map) noexcept {
        this->mmap = std::move(map.mmap);
        return *this;
    }
    CustomMap& operator=(const CustomMap& map) {
        this->mmap = map.mmap;
        return *this;
    }
    CustomMap& operator=(CustomMap&& map) noexcept {
        this->mmap = std::move(map.mmap);
        return *this;
    }

    operator std::map<Key, T, Compare, Allocator>() {
        return mmap;
    }

    typename std::map<Key, T, Compare, Allocator>::iterator begin() {
        return mmap.begin();
    }

    typename std::map<Key, T, Compare, Allocator>::const_iterator begin() const {
        return mmap.begin();
    }

    typename std::map<Key, T, Compare, Allocator>::iterator end() {
        return mmap.end();
    }

    typename std::map<Key, T, Compare, Allocator>::const_iterator end() const {
        return mmap.end();
    }

    typename std::map<Key, T, Compare, Allocator>::reverse_iterator rbegin() {
        return mmap.rbegin();
    }

    typename std::map<Key, T, Compare, Allocator>::const_reverse_iterator rbegin() const {
        return mmap.rbegin();
    }

    typename std::map<Key, T, Compare, Allocator>::reverse_iterator rend() {
        return mmap.rend();
    }

    typename std::map<Key, T, Compare, Allocator>::const_reverse_iterator rend() const {
        return mmap.rend();
    }

    typename std::map<Key, T, Compare, Allocator>::const_iterator cbegin() const {
        return begin();
    }

    typename std::map<Key, T, Compare, Allocator>::const_iterator cend() const {
        return end();
    }

    typename std::map<Key, T, Compare, Allocator>::const_reverse_iterator crbegin() const {
        return rbegin();
    }

    typename std::map<Key, T, Compare, Allocator>::const_reverse_iterator crend() const {
        return rend();
    }

    size_t size() const {
        size_t real_size(0);
        std::unordered_set<T> values;
        for (const auto& val : mmap) {
            if (values.find(val.second) == values.end()) {
                real_size++;
                values.insert(val.second);
            }
        }
        return real_size;
    }

    size_t max_size() const {
        return mmap.max_size();
    }

    bool empty() const {
        return mmap.empty();
    }
};

}
