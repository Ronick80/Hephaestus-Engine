from os import path
from traceback import format_exc
from logging import error
from conans import ConanFile, tools
from conans.util.files import save

required_conan_version = ">=1.43.0"


class ConanConfiguration(ConanFile):
    requires = [
        "vulkan/1.3.216.0",
        "glfw/3.3.7"
    ]
    generators = "cmake_find_package"

    def set_name(self):
        try:
            self.name = tools.load(path.join(path.dirname(path.abspath(__file__)), "name-version.txt")).split(':')[0].strip()
        except Exception as e:
            error(format_exc())
            raise e

    def set_version(self):
        try:
            self.version = tools.load(path.join(path.dirname(path.abspath(__file__)), "name-version.txt")).split(':')[1].strip()
        except Exception as e:
            error(format_exc())
            raise e

    def configure(self):
        try:
            self.options["vulkan"].shared = True
        except Exception as e:
            error(format_exc())
            raise e

    def generate(self):
        try:
            filename = 'conan-packages.cmake'
            content = ''

            content += 'set("${PROJECT_NAME}_CONAN_PACKAGE_NAMES"\n'
            for dep_name in self.deps_cpp_info.deps:
                if dep_name == 'glfw':
                    dep_name = 'glfw3'
                content += '    "' + dep_name + '"' + '\n'
            content += ')\n'

            content += 'set("${PROJECT_NAME}_CMAKE_PACKAGE_NAMES"\n'
            for dep_name, dep in self.deps_cpp_info.dependencies:
                if dep_name == 'glfw':
                    dep_name = 'glfw3'
                if dep.get_name('cmake_find_package') == 'glfw':
                    cmake_package_name = 'glfw3'
                else:
                    cmake_package_name = dep.get_name('cmake_find_package')
                content += '    "' + dep.get_name('cmake_find_package') + '" # ' + dep_name + '\n'
            content += ')\n'

            content += 'set("${PROJECT_NAME}_CMAKE_PACKAGE_VERSIONS"\n'
            for dep_name, dep in self.deps_cpp_info.dependencies:
                content += '    "' + dep.version + '" # ' + dep_name + '\n'
            content += ')\n'

            content += 'set("${PROJECT_NAME}_CMAKE_PACKAGE_PATHS"\n'
            for dep_name, dep in self.deps_cpp_info.dependencies:
                content += '    "' + dep.rootpath.replace('\\', '/') + '" # ' + dep_name + '\n'
            content += ')\n'

            save(filename, content)
        except Exception as e:
            error(format_exc())
            raise e

    def imports(self):
        try:
            self.copy(pattern="*.dll", dst="bin", src="bin")
            self.copy(pattern="*.dylib", dst="lib", src="lib")
            self.copy(pattern="*.json", dst="bin", src="bin")
        except Exception as e:
            error(format_exc())
            raise e

    def package_info(self):
        try:
            self.cpp_info.libs = []
        except Exception as e:
            error(format_exc())
            raise e

    def package_id(self):
        try:
            self.info.header_only()
        except Exception as e:
            error(format_exc())
            raise e


if __name__ == "__main__":
    pass
