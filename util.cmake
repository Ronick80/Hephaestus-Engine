cmake_policy(PUSH)
cmake_policy(SET CMP0054 NEW)
cmake_policy(PUSH)
cmake_policy(SET CMP0007 NEW)

function(set_if_not_defined var)
    if("" STREQUAL "${${var}}" AND NOT "" STREQUAL "${ARGN}")
        set("${var}" "${ARGN}" PARENT_SCOPE)
    endif()
endfunction()

function(string_substring_from var input fromExclusive)
    if("" STREQUAL "${fromExclusive}")
        message(FATAL_ERROR "Empty value not supported for 'fromExclusive'.")
    endif()
    string(FIND "${input}" "${fromExclusive}" fromStartIndex)
    if("-1" STREQUAL "${fromStartIndex}")
        message(FATAL_ERROR "Can't find 'fromExclusive' in 'input'")
    endif()
    string(LENGTH "${input}" inputLength)
    string(LENGTH "${fromExclusive}" "fromLength")
    math(EXPR fromEndIndex "${fromStartIndex} + ${fromLength}")
    math(EXPR substringLength "${inputLength} - ${fromEndIndex}")
    string(SUBSTRING "${input}" "${fromEndIndex}" "${substringLength}" result)
    set("${var}" "${result}" PARENT_SCOPE)
endfunction()

function(string_substring_to var input toExclusive)
    if("" STREQUAL "${toExclusive}")
        message(FATAL_ERROR "Empty value not supported for 'toExclusive'.")
    endif()
    string(FIND "${input}" "${toExclusive}" toStartIndex)
    if("-1" STREQUAL "${toStartIndex}")
        message(FATAL_ERROR "Can't find 'toExclusive' in 'input'")
    endif()
    string(LENGTH "${input}" inputLength)
    string(SUBSTRING "${input}" 0 "${toStartIndex}" result)
    set("${var}" "${result}" PARENT_SCOPE)
endfunction()

function(string_substring_between var input fromExclusive toExclusive)
    string_substring_from(result "${input}" "${fromExclusive}")
    string_substring_to(result "${result}" "${toExclusive}")
    set("${var}" "${result}" PARENT_SCOPE)
endfunction()

function(find_file_in_parent prefix name file_path max_parent_level)
    foreach(i prefix name file_path)
        if("" STREQUAL "${${i}}")
            message(FATAL_ERROR "Empty value not supported for '${i}'.")
        endif()
    endforeach()
    set(func_max "${max_parent_level}")
    if("" STREQUAL "${func_max}")
        set(func_max "1")
    endif()
    set(func_path "${file_path}")
    cmake_path(GET func_path ROOT_NAME func_path_root_name)
    cmake_path(GET func_path ROOT_DIRECTORY func_path_root_dir)
    set(func_path_root "${func_path_root_name}${func_path_root_dir}")
    foreach(i RANGE "1" "${func_max}")
        if("${func_path_root}" STREQUAL "${func_path}")
            break()
        endif()
        cmake_path(GET func_path PARENT_PATH func_path)
        #message(STATUS "find_file_in_parent processing: '${func_path}'")
        file(GLOB_RECURSE func_files "${func_path}/*")
        foreach(func_file IN LISTS func_files)
            get_filename_component(func_file_name "${func_file}" NAME)
            if("${func_file_name}" STREQUAL "${name}")
                set(func_result "${func_file}")
                get_filename_component(func_result_dir "${func_result}" DIRECTORY)
                set(func_path "${func_path_root}")
                break()
            endif()
        endforeach()
    endforeach()
    set("${prefix}_FILE" "${func_result}" PARENT_SCOPE)
    set("${prefix}_DIR" "${func_result_dir}" PARENT_SCOPE)
endfunction()

function(find_file_in prefix name path)
    foreach(i prefix name path)
        if("" STREQUAL "${${i}}")
            message(FATAL_ERROR "Empty value not supported for '${i}'.")
        endif()
    endforeach()
    file(GLOB_RECURSE func_files "${path}/*")
    foreach(func_file IN LISTS func_files)
        get_filename_component(func_file_name "${func_file}" NAME)
        if("${func_file_name}" STREQUAL "${name}")
            set(func_result "${func_file}")
            get_filename_component(func_result_dir "${func_result}" DIRECTORY)
            break()
        endif()
    endforeach()
    set("${prefix}_FILE" "${func_result}" PARENT_SCOPE)
    set("${prefix}_DIR" "${func_result_dir}" PARENT_SCOPE)
endfunction()

function(set_msvc_path var vswhereCommand compilerVersion)
    foreach(i var compilerVersion)
        if("" STREQUAL "${${i}}")
            message(FATAL_ERROR "Empty value not supported for '${i}'.")
        endif()
    endforeach()

    if(NOT "" STREQUAL "${vswhereCommand}")
        cmake_path(CONVERT "${vswhereCommand}" TO_CMAKE_PATH_LIST vswhereCommand NORMALIZE)
    else()
        set(vswhereCommand "C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe")
    endif()

    if("17" STREQUAL "${compilerVersion}" OR "2022" STREQUAL "${compilerVersion}")
        set(vswhereVersionArgs "-version" "[17.0, 18.0)")
    elseif("16" STREQUAL "${compilerVersion}" OR "2019" STREQUAL "${compilerVersion}")
        set(vswhereVersionArgs "-version" "[16.0, 17.0)")
    elseif("15" STREQUAL "${compilerVersion}" OR "2017" STREQUAL "${compilerVersion}")
        set(vswhereVersionArgs "-version" "[15.0, 16.0)")
    else()
        #set(vswhereVersionArgs "-latest")
        string(JOIN " " errorMessage
            "Unsupported or not specified 'compilerVersion': '${compilerVersion}'."
            "Supported values: ['15', '16', '17', '2017', '2019', '2022']."
        )
        message(FATAL_ERROR "${errorMessage}")
    endif()

    execute_process(
        COMMAND "${vswhereCommand}" ${vswhereVersionArgs} "-property" "installationPath"
        OUTPUT_VARIABLE "result"
        COMMAND_ECHO "STDERR"
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ENCODING "UTF-8"
        COMMAND_ERROR_IS_FATAL ANY
    )

    if("" STREQUAL "${result}")
        execute_process(
            COMMAND "${vswhereCommand}" ${vswhereVersionArgs} "-products" "Microsoft.VisualStudio.Product.BuildTools" "-property" "installationPath"
            OUTPUT_VARIABLE "result"
            COMMAND_ECHO "STDERR"
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ENCODING "UTF-8"
            COMMAND_ERROR_IS_FATAL ANY
        )
    endif()

    if("" STREQUAL "${result}")
        message(FATAL_ERROR "Empty result from: '${vswhereCommand}'.")
    endif()

    cmake_path(CONVERT "${result}" TO_CMAKE_PATH_LIST result NORMALIZE)
    string(REGEX REPLACE "[\r]" "" result "${result}")
    string(REGEX REPLACE "[\n]" ";" result "${result}")
    list(GET result 0 result)

    set("${var}" "${result}" PARENT_SCOPE)
endfunction()

function(set_msvc_env prefix vswhereCommand compilerPath compilerVersion compilerArch targetArch)
    foreach(i prefix)
        if("" STREQUAL "${${i}}")
            message(FATAL_ERROR "Empty value not supported for '${i}'.")
        endif()
    endforeach()

    if("" STREQUAL "${targetArch}")
        get_filename_component(compilerDir "${compilerPath}" DIRECTORY)
        get_filename_component(compilerDirName "${compilerDir}" NAME)
        string(TOLOWER "${compilerDirName}" compilerDirNameLower)
        if("x86" STREQUAL "${compilerDirNameLower}")
            set(targetArch "x86")
        elseif("x64" STREQUAL "${compilerDirNameLower}")
            set(targetArch "x64")
        endif()
    endif()

    if("" STREQUAL "${compilerArch}" AND NOT "" STREQUAL "${compilerDir}")
        get_filename_component(compilerDirParent "${compilerDir}" DIRECTORY)
        get_filename_component(compilerDirParentName "${compilerDirParent}" NAME)
        string(TOLOWER "${compilerDirParentName}" compilerDirParentNameLower)
        if("hostx86" STREQUAL "${compilerDirParentNameLower}")
            set(compilerArch "x86")
        elseif("hostx64" STREQUAL "${compilerDirParentNameLower}")
            set(compilerArch "x64")
        endif()
    endif()

    if(NOT "x86" STREQUAL "${compilerArch}" AND NOT "x64" STREQUAL "${compilerArch}")
        string(JOIN " " errorMessage
            "Unsupported or not specified 'compilerArch': '${compilerArch}'."
            "Supported values ['x86', 'x64']."
        )
        message(FATAL_ERROR "${errorMessage}")
    endif()

    if(NOT "x86" STREQUAL "${targetArch}" AND NOT "x64" STREQUAL "${targetArch}")
        string(JOIN " " errorMessage
            "Unsupported or not specified 'targetArch': '${targetArch}'."
            "Supported values [ 'x86', 'x64' ]."
        )
        message(FATAL_ERROR "${errorMessage}")
    endif()

    if("${compilerArch}" STREQUAL "${targetArch}")
        set(vcvarsallBatConf "${compilerArch}")
    else()
        set(vcvarsallBatConf "${compilerArch}_${targetArch}")
    endif()

    set(vcvarsallBatName "vcvarsall.bat")

    if("" STREQUAL "${compilerPath}")
        set_msvc_path(msvcPath "${vswhereCommand}" "${compilerVersion}")
        find_file_in(vcvarsall "${vcvarsallBatName}" "${msvcPath}")
        if("" STREQUAL "${vcvarsall_DIR}")
            message(FATAL_ERROR "Not found '${vcvarsallBatName}' in '${msvcPath}'")
        endif()
    elseif(NOT "" STREQUAL "${compilerPath}")
        if(NOT EXISTS "${compilerPath}")
            message(FATAL_ERROR "Not exists 'compilerPath': '${compilerPath}'")
        endif()
        find_file_in_parent(vcvarsall "${vcvarsallBatName}" "${compilerPath}" "8")
        if("" STREQUAL "${vcvarsall_DIR}")
            message(FATAL_ERROR "Not found '${vcvarsallBatName}' in '8' parent dirs of '${compilerPath}'")
        endif()
    endif()

    set(vcvarsallBatArgs
        "&&" "call" "echo" "INCLUDE_START"
        "&&" "call" "echo" "%INCLUDE%"
        "&&" "call" "echo" "INCLUDE_STOP"
        "&&" "call" "echo" "LIBPATH_START"
        "&&" "call" "echo" "%LIBPATH%"
        "&&" "call" "echo" "LIBPATH_STOP"
        "&&" "call" "echo" "LIB_START"
        "&&" "call" "echo" "%LIB%"
        "&&" "call" "echo" "LIB_STOP"
        "&&" "call" "echo" "CLPATH_START"
        "&&" "call" "where" "cl"
        "&&" "call" "echo" "CLPATH_STOP"
        "&&" "call" "echo" "RCPATH_START"
        "&&" "call" "where" "rc"
        "&&" "call" "echo" "RCPATH_STOP"
    )
    execute_process(
        COMMAND "cmd" "/c" "${vcvarsallBatName}" "${vcvarsallBatConf}" ${vcvarsallBatArgs}
        WORKING_DIRECTORY "${vcvarsall_DIR}"
        OUTPUT_VARIABLE "msvcEnv"
        COMMAND_ECHO "STDERR"
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ENCODING "UTF-8"
        COMMAND_ERROR_IS_FATAL ANY
    )

    string_substring_between(msvcInclude "${msvcEnv}" "INCLUDE_START" "INCLUDE_STOP")
    string(STRIP "${msvcInclude}" msvcInclude)
    string(REGEX REPLACE "[\r]" "" msvcInclude "${msvcInclude}")
    string(REGEX REPLACE "[\n]" "" msvcInclude "${msvcInclude}")

    string_substring_between(msvcLibPath "${msvcEnv}" "LIBPATH_START" "LIBPATH_STOP")
    string(STRIP "${msvcLibPath}" msvcLibPath)
    string(REGEX REPLACE "[\r]" "" msvcLibPath "${msvcLibPath}")
    string(REGEX REPLACE "[\n]" "" msvcLibPath "${msvcLibPath}")

    string_substring_between(msvcLib "${msvcEnv}" "LIB_START" "LIB_STOP")
    string(STRIP "${msvcLib}" msvcLib)
    string(REGEX REPLACE "[\r]" "" msvcLib "${msvcLib}")
    string(REGEX REPLACE "[\n]" "" msvcLib "${msvcLib}")

    string_substring_between(msvcClPath "${msvcEnv}" "CLPATH_START" "CLPATH_STOP")
    string(STRIP "${msvcClPath}" msvcClPath)
    string(REGEX REPLACE "[\r]" "" msvcClPath "${msvcClPath}")
    string(REGEX REPLACE "[\n]" ";" msvcClPath "${msvcClPath}")
    list(GET msvcClPath 0 msvcClPath)
    get_filename_component(msvcClPath "${msvcClPath}" DIRECTORY)
    cmake_path(CONVERT "${msvcClPath}" TO_NATIVE_PATH_LIST msvcClPath NORMALIZE)

    string_substring_between(msvcRcPath "${msvcEnv}" "RCPATH_START" "RCPATH_STOP")
    string(STRIP "${msvcRcPath}" msvcRcPath)
    string(REGEX REPLACE "[\r]" "" msvcRcPath "${msvcRcPath}")
    string(REGEX REPLACE "[\n]" ";" msvcRcPath "${msvcRcPath}")
    list(GET msvcRcPath 0 msvcRcPath)
    get_filename_component(msvcRcPath "${msvcRcPath}" DIRECTORY)
    cmake_path(CONVERT "${msvcRcPath}" TO_NATIVE_PATH_LIST msvcRcPath NORMALIZE)

    set("${prefix}_MSVC_INCLUDE" "${msvcInclude}" PARENT_SCOPE)
    set("${prefix}_MSVC_LIBPATH" "${msvcLibPath}" PARENT_SCOPE)
    set("${prefix}_MSVC_LIB" "${msvcLib}" PARENT_SCOPE)
    set("${prefix}_MSVC_CL_PATH" "${msvcClPath}" PARENT_SCOPE)
    set("${prefix}_MSVC_RC_PATH" "${msvcRcPath}" PARENT_SCOPE)
endfunction()

function(set_conan_msvc_compiler_runtime var cmakeMsvcRuntimeLibrary)
    if("" STREQUAL "${var}")
        message(FATAL_ERROR "Empty value not supported for 'var'.")
    endif()

    if("${cmakeMsvcRuntimeLibrary}" STREQUAL "MultiThreaded")
        set(value "MT")
    elseif("${cmakeMsvcRuntimeLibrary}" STREQUAL "MultiThreadedDLL")
        set(value "MD")
    elseif("${cmakeMsvcRuntimeLibrary}" STREQUAL "MultiThreadedDebug")
        set(value "MTd")
    elseif("${cmakeMsvcRuntimeLibrary}" STREQUAL "MultiThreadedDebugDLL")
        set(value "MDd")
    else()
        message(FATAL_ERROR "Unsupported 'cmakeMsvcRuntimeLibrary': '${cmakeMsvcRuntimeLibrary}'")
    endif()

    set("${var}" "${value}" PARENT_SCOPE)
endfunction()

function(
    set_conan_settings
    var
    cmakeSystemName
    cxxTargetArch
    cmakeCxxCompilerId
    cmakeCxxCompilerVersion
    cmakeMsvcRuntimeLibrary
    cmakeCxxStandard
    cmakeBuildType
)
    if("" STREQUAL "${var}")
        message(FATAL_ERROR "Empty value not supported for 'var'.")
    endif()

    # os
    if("Windows" STREQUAL "${cmakeSystemName}")
        set(value "--settings" "os=${cmakeSystemName}")

        # arch
        if("x64" STREQUAL "${cxxTargetArch}" OR "AMD64" STREQUAL "${cxxTargetArch}" OR "IA64" STREQUAL "${cxxTargetArch}")
            set(value "${value}" "--settings" "arch=x86_64")
        elseif("x86" STREQUAL "${cxxTargetArch}")
            set(value "${value}" "--settings" "arch=x86")
        else()
            message(FATAL_ERROR "Unsupported 'cxxTargetArch': '${cxxTargetArch}'")
        endif()
    else()
        message(FATAL_ERROR "Unsupported 'cmakeSystemName': '${cmakeSystemName}'")
    endif()

    # compiler
    if("MSVC" STREQUAL "${cmakeCxxCompilerId}")
        set(value "${value}" "--settings" "compiler=Visual Studio")

        # compiler.version
        if("${cmakeCxxCompilerVersion}" VERSION_GREATER_EQUAL "19.30" AND "${cmakeCxxCompilerVersion}" VERSION_LESS "19.40")
            set(value "${value}" "--settings" "compiler.version=16")
        elseif("${cmakeCxxCompilerVersion}" VERSION_GREATER_EQUAL "19.20" AND "${cmakeCxxCompilerVersion}" VERSION_LESS "19.30")
            set(value "${value}" "--settings" "compiler.version=16")
        elseif("${cmakeCxxCompilerVersion}" VERSION_GREATER_EQUAL "19.10" AND "${cmakeCxxCompilerVersion}" VERSION_LESS "19.20")
            set(value "${value}" "--settings" "compiler.version=15")
        else()
            message(FATAL_ERROR "Unsupported 'cmakeCxxCompilerVersion': '${cmakeCxxCompilerVersion}'")
        endif()

        # compiler.runtime
        set_conan_msvc_compiler_runtime(conanCompilerRuntime "${cmakeMsvcRuntimeLibrary}")
        set(value "${value}" "--settings" "compiler.runtime=${conanCompilerRuntime}")
    elseif("GNU" STREQUAL "${cmakeCxxCompilerId}")
        set(value "${value}" "--settings" "compiler=gcc")

        # compiler.version
        if("${cmakeCxxCompilerVersion}" VERSION_GREATER_EQUAL "13" AND "${cmakeCxxCompilerVersion}" VERSION_LESS "14")
            set(value "${value}" "--settings" "compiler.version=13")
        elseif("${cmakeCxxCompilerVersion}" VERSION_GREATER_EQUAL "12" AND "${cmakeCxxCompilerVersion}" VERSION_LESS "13")
            set(value "${value}" "--settings" "compiler.version=12")
        elseif("${cmakeCxxCompilerVersion}" VERSION_GREATER_EQUAL "11" AND "${cmakeCxxCompilerVersion}" VERSION_LESS "12")
            set(value "${value}" "--settings" "compiler.version=11")
        elseif("${cmakeCxxCompilerVersion}" VERSION_GREATER_EQUAL "10" AND "${cmakeCxxCompilerVersion}" VERSION_LESS "11")
            set(value "${value}" "--settings" "compiler.version=10")
        elseif("${cmakeCxxCompilerVersion}" VERSION_GREATER_EQUAL "9" AND "${cmakeCxxCompilerVersion}" VERSION_LESS "10")
            set(value "${value}" "--settings" "compiler.version=9")
        elseif("${cmakeCxxCompilerVersion}" VERSION_GREATER_EQUAL "8" AND "${cmakeCxxCompilerVersion}" VERSION_LESS "9")
            set(value "${value}" "--settings" "compiler.version=8")
        else()
            message(FATAL_ERROR "Unsupported 'cmakeCxxCompilerVersion': '${cmakeCxxCompilerVersion}'")
        endif()

        # compiler.libcxx
        if("${cmakeCxxStandard}" VERSION_GREATER_EQUAL "11")
            set(value "${value}" "--settings" "compiler.libcxx=libstdc++11")
        else()
            set(value "${value}" "--settings" "compiler.libcxx=libstdc++")
        endif()
    else()
        message(FATAL_ERROR "Unsupported 'cmakeCxxStandard': '${cmakeCxxStandard}'")
    endif()

    # build_type
    if("MinSizeRel" STREQUAL "${cmakeBuildType}")
        set(value "${value}" "--settings" "build_type=${cmakeBuildType}")
    elseif("Release" STREQUAL "${cmakeBuildType}")
        set(value "${value}" "--settings" "build_type=${cmakeBuildType}")
    elseif("RelWithDebInfo" STREQUAL "${cmakeBuildType}")
        set(value "${value}" "--settings" "build_type=${cmakeBuildType}")
    elseif("Debug" STREQUAL "${cmakeBuildType}")
        set(value "${value}" "--settings" "build_type=${cmakeBuildType}")
    else()
        message(FATAL_ERROR "Unsupported 'cmakeBuildType': '${cmakeBuildType}'")
    endif()

    # additional
    if(NOT "" STREQUAL "${ARGN}")
        foreach(arg ${ARGN})
            list(APPEND value "--settings" "${arg}")
        endforeach()
    endif()

    set("${var}" "${value}" PARENT_SCOPE)
endfunction()

function(set_python_boolean var cmakeBoolean)
    if("" STREQUAL "${var}")
        message(FATAL_ERROR "Empty value not supported for 'var'.")
    endif()

    if("${cmakeBoolean}")
        set(value "True")
    else()
        set(value "False")
    endif()

    set("${var}" "${value}" PARENT_SCOPE)
endfunction()

function(set_conan_options var)
    if("" STREQUAL "${var}")
        message(FATAL_ERROR "Empty value not supported for 'var'.")
    endif()

    # all options
    if(NOT "" STREQUAL "${ARGN}")
        foreach(arg ${ARGN})
            if(NOT "" STREQUAL "${arg}" AND NOT "${arg}" IN_LIST "value")
                list(APPEND value "--options" "${arg}")
            endif()
        endforeach()
    endif()

    set("${var}" "${value}" PARENT_SCOPE)
endfunction()

function(set_not_found_package_names var)
    if("" STREQUAL "${var}")
        message(FATAL_ERROR "Empty value not supported for 'var'.")
    endif()

    if(NOT "" STREQUAL "${ARGN}")
        foreach(arg ${ARGN})
            if(NOT "${${arg}_FOUND}")
                list(APPEND value "${arg}")
            endif()
        endforeach()
    endif()

    set("${var}" "${value}" PARENT_SCOPE)
endfunction()

function(
    set_target_names
    var
    dir
)
    get_property(subdirectories DIRECTORY "${dir}" PROPERTY SUBDIRECTORIES)
    foreach(subdir ${subdirectories})
        set_target_names(subTargets "${subdir}")
    endforeach()
    if(NOT "${subTargets}" STREQUAL "")
        list(APPEND targets "${subTargets}")
    endif()
    get_property(currentTargets DIRECTORY "${dir}" PROPERTY BUILDSYSTEM_TARGETS)
    if(NOT "${currentTargets}" STREQUAL "")
        list(APPEND targets "${currentTargets}")
    endif()
    set(${var} "${targets}" PARENT_SCOPE)
endfunction()

function(set_msvc_toolchain_content var processor os vswhereCommand compilerPath compilerVersion compilerArch targetArch)
    foreach(i var processor os)
        if("" STREQUAL "${${i}}")
            message(FATAL_ERROR "Empty value not supported for '${i}'.")
        endif()
    endforeach()

    set_msvc_env("func" "${vswhereCommand}" "${compilerPath}" "${compilerVersion}" "${compilerArch}" "${targetArch}")

    cmake_path(CONVERT "${func_MSVC_INCLUDE}" TO_CMAKE_PATH_LIST func_include NORMALIZE)
    list(FILTER func_include EXCLUDE REGEX "^$")
    list(REMOVE_DUPLICATES func_include)
    set(func_include_cmake "${func_include}")
    cmake_path(CONVERT "${func_include}" TO_NATIVE_PATH_LIST func_include NORMALIZE)

    cmake_path(CONVERT "${func_MSVC_LIBPATH}" TO_CMAKE_PATH_LIST func_libpath NORMALIZE)
    list(FILTER func_libpath EXCLUDE REGEX "^$")
    list(REMOVE_DUPLICATES func_libpath)
    set(func_libpath_cmake "${func_libpath}")
    cmake_path(CONVERT "${func_libpath}" TO_NATIVE_PATH_LIST func_libpath NORMALIZE)

    cmake_path(CONVERT "${func_MSVC_LIB}" TO_CMAKE_PATH_LIST func_lib NORMALIZE)
    list(FILTER func_lib EXCLUDE REGEX "^$")
    list(REMOVE_DUPLICATES func_lib)
    cmake_path(CONVERT "${func_lib}" TO_NATIVE_PATH_LIST func_lib NORMALIZE)

    cmake_path(CONVERT "$ENV{PATH}" TO_CMAKE_PATH_LIST func_path NORMALIZE)
    cmake_path(CONVERT "${func_MSVC_CL_PATH}" TO_CMAKE_PATH_LIST func_cl_cmake NORMALIZE)
    cmake_path(CONVERT "${func_MSVC_RC_PATH}" TO_CMAKE_PATH_LIST func_rc_cmake NORMALIZE)
    list(PREPEND func_path "${func_rc_cmake}")
    list(PREPEND func_path "${func_cl_cmake}")
    list(FILTER func_path EXCLUDE REGEX "^$")
    list(REMOVE_DUPLICATES func_path)
    cmake_path(CONVERT "${func_path}" TO_NATIVE_PATH_LIST func_path NORMALIZE)

    if("Windows" STREQUAL "${os}")
        string(REPLACE "\\" "\\\\" func_include "${func_include}")
        string(REPLACE ";" "\\;" func_include "${func_include}")

        string(REPLACE "\\" "\\\\" func_libpath "${func_libpath}")
        string(REPLACE ";" "\\;" func_libpath "${func_libpath}")

        string(REPLACE "\\" "\\\\" func_lib "${func_lib}")
        string(REPLACE ";" "\\;" func_lib "${func_lib}")

        string(REPLACE "\\" "\\\\" func_path "${func_path}")
        string(REPLACE ";" "\\;" func_path "${func_path}")
    endif()

    cmake_path(CONVERT "${func_MSVC_INCLUDE}" TO_CMAKE_PATH_LIST func_cmake_include NORMALIZE)

    set(func_cmake_libpath "${func_MSVC_LIBPATH}" "${func_MSVC_LIB}")
    cmake_path(CONVERT "${func_cmake_libpath}" TO_CMAKE_PATH_LIST func_cmake_libpath NORMALIZE)

    string(JOIN "\n" content
        "set(CMAKE_SYSTEM_PROCESSOR \"${processor}\")"
        "set(CMAKE_SYSTEM_NAME \"${os}\")"
        ""
        "set(MSVC_CL_PATH \"${func_cl_cmake}\")"
        "set(MSVC_RC_PATH \"${func_rc_cmake}\")"
        ""
        "set(CMAKE_C_COMPILER   \"\${MSVC_CL_PATH}/cl.exe\")"
        "set(CMAKE_CXX_COMPILER \"\${MSVC_CL_PATH}/cl.exe\")"
        "set(CMAKE_AR           \"\${MSVC_CL_PATH}/lib.exe\")"
        "set(CMAKE_LINKER       \"\${MSVC_CL_PATH}/link.exe\")"
        "set(CMAKE_RC_COMPILER  \"\${MSVC_RC_PATH}/rc.exe\")"
        "set(CMAKE_MT           \"\${MSVC_RC_PATH}/mt.exe\")"
        ""
        "set(ENV{INCLUDE} \"${func_include}\")"
        "set(ENV{LIBPATH} \"${func_libpath}\")"
        "set(ENV{LIB} \"${func_lib}\")"
        "set(ENV{PATH} \"${func_path}\")"
        ""
        "set(CMAKE_C_STANDARD_INCLUDE_DIRECTORIES \"${func_include_cmake}\")"
        "set(CMAKE_C_STANDARD_LINK_DIRECTORIES \"${func_libpath_cmake}\")"
        ""
        "set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES \"${func_cmake_include}\")"
        "set(CMAKE_CXX_STANDARD_LINK_DIRECTORIES \"${func_cmake_libpath}\")"
        ""
        "set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)"
        "set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)"
        "set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)"
        "set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)"
        ""
        "link_directories(\"\${CMAKE_CXX_STANDARD_LINK_DIRECTORIES}\") # remove when CMAKE_CXX_STANDARD_LINK_DIRECTORIES is supported"
        ""
    )
    set("${var}" "${content}" PARENT_SCOPE)
endfunction()

function(set_gnu_toolchain_content var processor os path)
    foreach(i var processor os path)
        if("" STREQUAL "${${i}}")
            message(FATAL_ERROR "Empty value not supported for '${i}'.")
        endif()
    endforeach()

    cmake_path(CONVERT "${path}" TO_CMAKE_PATH_LIST path NORMALIZE)

    get_filename_component(compilerDir "${path}" DIRECTORY)

    cmake_path(CONVERT "$ENV{PATH}" TO_CMAKE_PATH_LIST envPath NORMALIZE)
    list(PREPEND envPath "${compilerDir}")
    list(FILTER envPath EXCLUDE REGEX "^$")
    list(REMOVE_DUPLICATES envPath)
    cmake_path(CONVERT "${envPath}" TO_NATIVE_PATH_LIST envPathNative NORMALIZE)

    if("Windows" STREQUAL "${os}")
        string(REPLACE "\\" "\\\\" envPathNative "${envPathNative}")
        string(REPLACE ";" "\\;" envPathNative "${envPathNative}")
    endif()

    string(JOIN "\n" content
        "set(CMAKE_SYSTEM_PROCESSOR \"${processor}\")"
        "set(CMAKE_SYSTEM_NAME \"${os}\")"
        ""
        "set(CMAKE_C_COMPILER   \"${compilerDir}/gcc.exe\")"
        "set(CMAKE_CXX_COMPILER \"${compilerDir}/g++.exe\")"
        "set(CMAKE_AR           \"${compilerDir}/ar.exe\")"
        "set(CMAKE_LINKER       \"${compilerDir}/ld.exe\")"
        "set(CMAKE_RC_COMPILER  \"${compilerDir}/windres.exe\")"
        ""
        "set(ENV{PATH} \"${envPathNative}\")"
        ""
        "set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)"
        "set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)"
        "set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)"
        "set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)"
        ""
    )
    set("${var}" "${content}" PARENT_SCOPE)
endfunction()

function(set_msvc_toolchain_content_delegate var)
    set(oneValueKeywords
        "processor"
        "os"
        "compiler"
        "version"
        "host"
        "target"
        "path"
    )
    cmake_parse_arguments(PARSE_ARGV 1 "func" "${options}" "${oneValueKeywords}" "")
    if(
        "Windows" STREQUAL "${func_os}"
        AND "msvc" STREQUAL "${func_compiler}"
        AND (NOT "" STREQUAL "${func_path}" AND EXISTS "${func_path}")
    )
        set_msvc_toolchain_content(toolchain_content "${func_processor}" "${func_os}" "" "${func_path}" "" "" "")
        set("${var}" "${toolchain_content}" PARENT_SCOPE)
    elseif(
        "Windows" STREQUAL "${func_os}"
        AND "msvc" STREQUAL "${func_compiler}"
        AND ("x86" STREQUAL "${func_host}" OR "x64" STREQUAL "${func_host}")
        AND ("x86" STREQUAL "${func_target}" OR "x64" STREQUAL "${func_target}")
    )
        set_msvc_toolchain_content(toolchain_content "${func_processor}" "${func_os}" "" "" "${func_version}" "${func_host}" "${func_target}")
        set("${var}" "${toolchain_content}" PARENT_SCOPE)
    else()
        set("${var}" "NOT_SUPPORTED" PARENT_SCOPE)
    endif()
endfunction()

function(set_gnu_toolchain_content_delegate var)
    set(oneValueKeywords
        "processor"
        "os"
        "compiler"
        "path"
    )
    cmake_parse_arguments(PARSE_ARGV 1 "func" "${options}" "${oneValueKeywords}" "")
    if(
        "Windows" STREQUAL "${func_os}"
        AND "gnu" STREQUAL "${func_compiler}"
        AND (NOT "" STREQUAL "${func_path}" AND EXISTS "${func_path}")
    )
        set_gnu_toolchain_content(toolchain_content "${func_processor}" "${func_os}" "${func_path}")
        set("${var}" "${toolchain_content}" PARENT_SCOPE)
    else()
        set("${var}" "NOT_SUPPORTED" PARENT_SCOPE)
    endif()
endfunction()

function(script_execute args)
    set(options
        "help"
        "toolchain"
    )
    set(oneValueKeywords
        "processor"
        "os"
        "compiler"
        "version"
        "host"
        "target"
        "path"
        "file"
    )
    cmake_parse_arguments("func" "${options}" "${oneValueKeywords}" "" "${args}")

    if("TRUE" STREQUAL "${func_toolchain}" OR "ON" STREQUAL "${func_toolchain}")
        if(EXISTS "${func_file}")
            return()
        endif()

        set_msvc_toolchain_content_delegate(toolchain_content
            processor "${func_processor}"
            os "${func_os}"
            compiler "${func_compiler}"
            version "${func_version}"
            host "${func_host}"
            target "${func_target}"
            path "${func_path}"
        )

        if(NOT "NOT_SUPPORTED" STREQUAL "${toolchain_content}")
            file(WRITE "${func_file}" "${toolchain_content}")
            return()
        endif()

        set_gnu_toolchain_content_delegate(toolchain_content
            processor "${func_processor}"
            os "${func_os}"
            compiler "${func_compiler}"
            version "${func_version}"
            host "${func_host}"
            target "${func_target}"
            path "${func_path}"
        )

        if(NOT "NOT_SUPPORTED" STREQUAL "${toolchain_content}")
            file(WRITE "${func_file}" "${toolchain_content}")
            return()
        endif()

        string(JOIN "\n" error_message
            "Unsupported 'toolchain' set of arguments:"
            "  processor: '${func_processor}'"
            "  os: '${func_os}'"
            "  compiler: '${func_compiler}'"
            "  version: '${func_version}'"
            "  host: '${func_host}'"
            "  target: '${func_target}'"
            "  path: '${func_path}'"
            "  file: '${func_file}'"
        )
        message(FATAL_ERROR "${error_message}")
    elseif("TRUE" STREQUAL "${func_help}" OR "ON" STREQUAL "${func_help}")
        get_filename_component(func_current_file_name "${CMAKE_CURRENT_LIST_FILE}" NAME)

        string(JOIN " " func_usage_1 "cmake" "-P" "${func_current_file_name}" "help")
        string(JOIN " " func_usage_2 "cmake" "-P" "${func_current_file_name}" "toolchain"
            "processor" "'<value>'"
            "os" "'Windows'"
            "compiler" "'msvc'"
            "version" "'16(i.e. Visual Studio 2019)|17(i.e. Visual Studio 2022)'"
            "host" "'x86|x64'"
            "target" "'x86|x64'"
            "file" "'toolchain.cmake|build/toolchain.cmake'"
        )
        string(JOIN " " func_usage_3 "cmake" "-P" "${func_current_file_name}" "toolchain"
            "processor" "'<value>'"
            "os" "'Windows'"
            "compiler" "'msvc|gnu'"
            "path" "'path/to/cl.exe'"
            "file" "'toolchain.cmake|build/toolchain.cmake'"
        )

        string(JOIN "\n" func_content
            "Usage:"
            "  ${func_usage_1}"
            "  ${func_usage_2}"
            "  ${func_usage_3}"
        )
        message("${func_content}")
    endif()
endfunction()

math(EXPR MAX "${CMAKE_ARGC} - 1")
foreach(i RANGE "${MAX}")
    list(APPEND ARGS "${CMAKE_ARGV${i}}")
endforeach()
script_execute("${ARGS}")

cmake_policy(POP)
cmake_policy(POP)
