//#include "Instance.hpp"
#include "exqudens/vulkan/Instance.hpp"
#include "exqudens/vulkan/PhysicalDevice.hpp"
#include "exqudens/vulkan/Surface.hpp"
#include "ErrorUtils.hpp"
#include "utils.hpp"
#include <GLFW/glfw3.h>

#include <format>

using namespace exqudens::vulkan;

class VulkanContext : public NonCopyable
{
public:
    // publically accessible getter functions for all the 
    // vulkan objects created in the context

    // example for future me when I work on this again
    const Instance& instance() {
        return instance_;
    }

    void init(GLFWwindow* window) {
        // start by creating the vulkan instance. It is the
        // father of all other vulkan objects by proxy.
        // Once the logical device is created (VkDevice) then
        // it becomes the general daddy for all other vulkan
        // objects.
        createInstance();
        createSurface(window);
        createPhysicalDevice();
    }

private:
    // all required objects that need to be created for rendering with vulkan
    // this comprises the "Vulkan Context"
    Instance instance_;
    Surface surface_;
    PhysicalDevice physicalDevice_;




    void createInstance() {
        uint32_t glfwExtensionCount = 0;
        const char** glfwExtensions;
        glfwExtensions = glfwGetRequiredInstanceExtensions(&glfwExtensionCount);
        std::vector<const char*> glfwInstanceRequiredExtensions(glfwExtensions, glfwExtensions + glfwExtensionCount);
        std::vector<const char*> enabledExtensionNames = glfwInstanceRequiredExtensions;
        enabledExtensionNames.emplace_back(VK_EXT_DEBUG_UTILS_EXTENSION_NAME);

        instance_ = Instance::builder()
            .addEnabledLayerName("VK_LAYER_KHRONOS_validation")
            .setEnabledExtensionNames(enabledExtensionNames)
            .setApplicationInfo(
                vk::ApplicationInfo()
                .setPApplicationName("Exqudens Application")
                .setApplicationVersion(VK_MAKE_VERSION(1, 0, 0))
                .setPEngineName("Exqudens Engine")
                .setEngineVersion(VK_MAKE_VERSION(1, 0, 0))
                .setApiVersion(VK_MAKE_API_VERSION(0, 1, 3, 0))
            )
            .setMessengerCreateInfo(
                MessengerCreateInfo()
                .setExceptionSeverity(vk::DebugUtilsMessageSeverityFlagBitsEXT::eError)
                .setOutSeverity(vk::DebugUtilsMessageSeverityFlagBitsEXT::eVerbose)
                .setToStringFunction(&Utility::toString)
            )
            .setDebugUtilsMessengerCreateInfo(
                vk::DebugUtilsMessengerCreateInfoEXT()
                .setMessageSeverity(vk::DebugUtilsMessageSeverityFlagBitsEXT::eVerbose | vk::DebugUtilsMessageSeverityFlagBitsEXT::eInfo | vk::DebugUtilsMessageSeverityFlagBitsEXT::eWarning | vk::DebugUtilsMessageSeverityFlagBitsEXT::eError)
                .setMessageType(vk::DebugUtilsMessageTypeFlagBitsEXT::eGeneral | vk::DebugUtilsMessageTypeFlagBitsEXT::eValidation | vk::DebugUtilsMessageTypeFlagBitsEXT::ePerformance)
            )
            .build();
        std::cout << std::format("instance: '{}'", (bool)instance_.value) << std::endl;
    }
     
    void createSurface(GLFWwindow* window) {
        // create surface for glfw. TODOMG In the future this will need to be done completely
        // differently. Just want to do this for now. In the future this will need to support 
        // different surfaces.

        VkSurfaceKHR vkSurface = nullptr;
        auto vkInstance = static_cast<VkInstance>(*instance_.reference());
        if (glfwCreateWindowSurface(vkInstance, window, nullptr, &vkSurface) != VK_SUCCESS) {
            throw std::runtime_error(CALL_INFO() + ": failed to create surface!");
        }
        if (vkSurface == nullptr) {
            throw std::runtime_error(CALL_INFO() + ": surface is null!");
        }
        surface_ = Surface::builder()
            .setInstance(instance_.value)
            .setVkSurface(vkSurface)
            .build();
        std::cout << std::format("surface: '{}'", (bool)surface_.value) << std::endl;
    }

    void createPhysicalDevice() {
        physicalDevice_ = PhysicalDevice::builder()
            .setInstance(instance_.value)
            .setSurface(surface_.value)
            .addEnabledExtensionName(VK_KHR_SWAPCHAIN_EXTENSION_NAME)
            .setFeatures(vk::PhysicalDeviceFeatures().setSamplerAnisotropy(true))
            .addQueueType(vk::QueueFlagBits::eCompute)
            .addQueueType(vk::QueueFlagBits::eTransfer)
            .addQueueType(vk::QueueFlagBits::eGraphics)
            .setQueuePriority(1.0f)
            .build();
        std::cout << std::format("physicalDevice: '{}'", (bool)physicalDevice_.value) << std::endl;
    }
};




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
    }
    catch (const std::exception& e) {
        std::cerr << ErrorUtils::toString(e);
    }
}











