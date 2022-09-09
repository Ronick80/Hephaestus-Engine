#pragma once

// create a non copyable class that can be inherited by other classes
// if they don't want to be copyable
class NonCopyable
{
public:
    NonCopyable() = default;
    NonCopyable(const NonCopyable&) = delete;
    NonCopyable& operator=(const NonCopyable&) = delete;
};