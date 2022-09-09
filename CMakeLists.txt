cmake_minimum_required(VERSION 3.21 FATAL_ERROR)
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/name-version.txt" INFO)
string(REPLACE ":" ";" INFO_LIST "${INFO}")
list(GET INFO_LIST 0 RAW_NAME)
list(GET INFO_LIST 1 RAW_VERSION)
string(STRIP "${RAW_NAME}" NAME)
string(STRIP "${RAW_VERSION}" VERSION)
project("${NAME}" VERSION "${VERSION}" LANGUAGES "NONE")

message("project: '${PROJECT_NAME}-${PROJECT_VERSION}'")

# include setup .cmake scripts
include("util.cmake")
include("config.cmake")

# add the exqudens cpp vulkan library as a subdirectory
add_subdirectory("exqudens-cpp-vulkan")

# create executable for the main project
add_executable(${PROJECT_NAME}
    "src/main.cpp"
 "src/ErrorUtils.cpp")

set_target_properties("${PROJECT_NAME}" PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY                "${PROJECT_BINARY_DIR}/main/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE        "${PROJECT_BINARY_DIR}/main/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${PROJECT_BINARY_DIR}/main/bin"
    RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL     "${PROJECT_BINARY_DIR}/main/bin"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG          "${PROJECT_BINARY_DIR}/main/bin"

    ARCHIVE_OUTPUT_DIRECTORY                "${PROJECT_BINARY_DIR}/main/lib"
    ARCHIVE_OUTPUT_DIRECTORY_RELEASE        "${PROJECT_BINARY_DIR}/main/lib"
    ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${PROJECT_BINARY_DIR}/main/lib"
    ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL     "${PROJECT_BINARY_DIR}/main/lib"
    ARCHIVE_OUTPUT_DIRECTORY_DEBUG          "${PROJECT_BINARY_DIR}/main/lib"

    LIBRARY_OUTPUT_DIRECTORY                "${PROJECT_BINARY_DIR}/main/lib"
    LIBRARY_OUTPUT_DIRECTORY_RELEASE        "${PROJECT_BINARY_DIR}/main/lib"
    LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO "${PROJECT_BINARY_DIR}/main/lib"
    LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL     "${PROJECT_BINARY_DIR}/main/lib"
    LIBRARY_OUTPUT_DIRECTORY_DEBUG          "${PROJECT_BINARY_DIR}/main/lib"
)

target_link_libraries(${PROJECT_NAME}
    "exqudens-cpp-vulkan"
)

