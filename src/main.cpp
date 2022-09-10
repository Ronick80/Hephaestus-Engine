//#include "Instance.hpp"
#include "ErrorUtils.hpp"
#include <GLFW/glfw3.h>
#include "VulkanContext.hpp"

#include <format>

using namespace exqudens::vulkan;

int main() {
    try {
        int width = 800;
        int height = 600;
        std::string title = "Vulkan";

        glfwInit();
        glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
        //glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE);

        GLFWwindow* window = glfwCreateWindow(width, height, title.c_str(), nullptr, nullptr);

        // start by creating the vulkan context
        VulkanContext context;
        context.init(window);

        while (!glfwWindowShouldClose(window)) {
            glfwPollEvents();
            glfwGetFramebufferSize(window, &width, &height);
            while (width == 0 || height == 0) {
                glfwGetFramebufferSize(window, &width, &height);
                glfwWaitEvents();
            }
        }
    }
    catch (const std::exception& e) {
        std::cerr << ErrorUtils::toString(e);
    }

    return 0;
}











