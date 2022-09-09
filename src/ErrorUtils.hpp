#pragma once
#include <vector>
#include <string>
#include <exception>

class ErrorUtils {
public:
    static std::vector<std::string> toStringVector(
        const std::exception& exception,
        std::vector<std::string> previous = {}
    );

    static std::vector<std::string> toStackTrace(const std::exception& exception);

    static std::string toString(const std::exception& e);
};