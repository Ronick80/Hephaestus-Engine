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

#set_conan_settings(CONAN_SETTINGS
#    "${CMAKE_SYSTEM_NAME}"
#    "${CMAKE_SYSTEM_PROCESSOR}"
#    "${CMAKE_CXX_COMPILER_ID}"
#    "${CMAKE_CXX_COMPILER_VERSION}"
#    "${CMAKE_MSVC_RUNTIME_LIBRARY}"
#    "${CMAKE_CXX_STANDARD}"
#    "${CMAKE_BUILD_TYPE}"
#    "vulkan:build_type=Release"
#    "vulkan:compiler.runtime=MD"
#    "glfw:build_type=Release"
#    "glfw:compiler.runtime=${CONAN_RELEASE_COMPILER_RUNTIME}"
#)
#set_conan_options(CONAN_OPTIONS
#    "vulkan:shared=True"
##    "gtest:shared=${CONAN_BUILD_SHARED_LIBS}"
##    "lodepng:shared=${CONAN_BUILD_SHARED_LIBS}"
#    "glfw:shared=${CONAN_BUILD_SHARED_LIBS}"
#)
#set("CONAN_INSTALL_PREFIX" "${PROJECT_BINARY_DIR}/conan-install")
#message("conan install prefix: ${CONAN_INSTALL_PREFIX}")
#if(NOT EXISTS "${CONAN_INSTALL_PREFIX}")
#    execute_process(
#        COMMAND "${CONAN_COMMAND}"
#                install
#                "${PROJECT_SOURCE_DIR}/conanfile.py"
#                --install-folder
#                "${CONAN_INSTALL_PREFIX}"
#                ${CONAN_SETTINGS}
#                ${CONAN_OPTIONS}
#        COMMAND_ECHO "STDERR"
#        OUTPUT_STRIP_TRAILING_WHITESPACE
#        ENCODING "UTF-8"
#        COMMAND_ERROR_IS_FATAL ANY
#    )
#endif()
#include("${CONAN_INSTALL_PREFIX}/conanbuildinfo.cmake")
#CONAN_BASIC_SETUP()
#if(NOT EXISTS "${CONAN_INSTALL_PREFIX}/conan-packages.cmake")
#    message(FATAL_ERROR "Not exists: '${CONAN_INSTALL_PREFIX}/conan-packages.cmake'!")
#endif()
#include("${CONAN_INSTALL_PREFIX}/conan-packages.cmake")
#set(CMAKE_MODULE_PATH "${CONAN_INSTALL_PREFIX}")
#foreach(
#    conanPackageName
#    cmakePackageName
#    cmakePackageVersion
#    cmakePackagePath
#    IN ZIP_LISTS
#    "${PROJECT_NAME}_CONAN_PACKAGE_NAMES"
#    "${PROJECT_NAME}_CMAKE_PACKAGE_NAMES"
#    "${PROJECT_NAME}_CMAKE_PACKAGE_VERSIONS"
#    "${PROJECT_NAME}_CMAKE_PACKAGE_PATHS"
#)
#    if(
#        "" STREQUAL "${conanPackageName}"
#        OR "" STREQUAL "${cmakePackageName}"
#        OR "" STREQUAL "${cmakePackageVersion}"
#        OR "" STREQUAL "${cmakePackagePath}"
#    )
#        string(JOIN " " errorMessage
#            "Empty value 'conanPackageName': '${conanPackageName}'"
#            "or 'cmakePackageName': '${cmakePackageName}'"
#            "or 'cmakePackageVersion': '${cmakePackageVersion}'"
#            "or 'cmakePackagePath': '${cmakePackagePath}'!"
#        )
#        message(FATAL_ERROR "${errorMessage}")
#    elseif(NOT IS_DIRECTORY "${cmakePackagePath}")
#        message(FATAL_ERROR "Not is directory 'cmakePackagePath': '${cmakePackagePath}'!")
#    endif()
#
#    list(APPEND CMAKE_PREFIX_PATH "${cmakePackagePath}")
#
#    if("gtest" STREQUAL "${conanPackageName}")
#        file(REMOVE "${CONAN_INSTALL_PREFIX}/Find${cmakePackageName}.cmake")
#        list(APPEND NOT_FOUND_PACKAGE_NAMES "${cmakePackageName}")
#        find_package("${cmakePackageName}" "${cmakePackageVersion}" CONFIG)
#    elseif("vulkan" STREQUAL "${conanPackageName}")
#        list(APPEND NOT_FOUND_PACKAGE_NAMES "${cmakePackageName}")
#        message("Vulkan package info: ${cmakePackageName}")
#        find_package("${cmakePackageName}" "${cmakePackageVersion}" )
#        find_program(GLSLC_COMMAND NAMES "glslc.exe" "glslc" PATHS "${cmakePackagePath}/bin")
#    elseif("glm" STREQUAL "${conanPackageName}")
#        list(APPEND NOT_FOUND_PACKAGE_NAMES "${cmakePackageName}")
#        find_package("${cmakePackageName}" "${cmakePackageVersion}" )
#    elseif("lodepng" STREQUAL "${conanPackageName}")
#        list(APPEND NOT_FOUND_PACKAGE_NAMES "${cmakePackageName}")
#        find_package("${cmakePackageName}" )
#    elseif("glfw3" STREQUAL "${conanPackageName}")
#        #file(REMOVE "${CONAN_INSTALL_PREFIX}/Find${cmakePackageName}.cmake")
#        message("glfw package info: ${cmakePackageName}")
#        set(GLFW_PACKAGE_NAME "${cmakePackageName}")
#        list(APPEND NOT_FOUND_PACKAGE_NAMES "${GLFW_PACKAGE_NAME}")
#        find_package("${GLFW_PACKAGE_NAME}" "${cmakePackageVersion}" )
#    elseif("opengl" STREQUAL "${conanPackageName}")
#        #file(REMOVE "${CONAN_INSTALL_PREFIX}/Find${cmakePackageName}.cmake")
#        list(APPEND NOT_FOUND_PACKAGE_NAMES "${cmakePackageName}")
#        find_package("${cmakePackageName}" )
#    else()
#        message("Conan package name: ${cmakePackageName}")
#        message("conan package version: ${cmakePackageVersion}")
#        list(APPEND NOT_FOUND_PACKAGE_NAMES "${cmakePackageName}")
#        find_package("${cmakePackageName}" "${cmakePackageVersion}" QUIET CONFIG)
#    endif()
#endforeach()
#set_not_found_package_names(NOT_FOUND_PACKAGE_NAMES ${NOT_FOUND_PACKAGE_NAMES})
#if(NOT "" STREQUAL "${NOT_FOUND_PACKAGE_NAMES}")
#    foreach(package ${NOT_FOUND_PACKAGE_NAMES})
#        message(WARNING "${package}_FOUND: '${${package}_FOUND}'")
#    endforeach()
#    return()
#endif()
#
#

#find_package("glfw3")
#find_package("opengl_system")
#find_package("Vulkan")

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
message("Conan packages: ${CONAN_LIBS}")
target_link_libraries(${PROJECT_NAME}
    "exqudens-cpp-vulkan"
    #"Vulkan::Vulkan"
    #"vulkan-1.lib"
    #"glfw3"
)

