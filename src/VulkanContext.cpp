#include "VulkanContext.hpp"
#include <iostream>
#include <format>

using namespace exqudens::vulkan;

void VulkanContext::init(GLFWwindow* window) {
    // start by creating the vulkan instance. It is the
    // father of all other vulkan objects by proxy.
    // Once the logical device is created (VkDevice) then
    // it becomes the general daddy for all other vulkan
    // objects.
    createInstance();
    createSurface(window);
    createPhysicalDevice();
    createLogicalDevice();
}

void VulkanContext::createInstance() {
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
 
void VulkanContext::createSurface(GLFWwindow* window) {
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

void VulkanContext::createPhysicalDevice() {
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

void VulkanContext::createLogicalDevice() {
    device_ = Device::builder()
        .setPhysicalDevice(physicalDevice_.value)
        .setCreateInfo(
            vk::DeviceCreateInfo()
            .setQueueCreateInfos(physicalDevice_.uniqueQueueCreateInfos)
            .setPEnabledFeatures(&physicalDevice_.features)
            .setPEnabledExtensionNames(physicalDevice_.enabledExtensionNames)
            .setPEnabledLayerNames(instance_.enabledLayerNames)
        )
        .build();
    std::cout << std::format("device: '{}'", (bool)device_.value) << std::endl;
}

void VulkanContext::createSwapChain(uint32_t width, uint32_t height) {
    swapChain_ = Swapchain::builder()
        .setDevice(device_.value)
        .addGraphicsQueueFamilyIndex(physicalDevice_.graphicsQueueCreateInfos.front().queueFamilyIndex)
        .addPresentQueueFamilyIndex(physicalDevice_.presentQueueCreateInfos.front().queueFamilyIndex)
        .setCreateInfo(
            Utility::swapChainCreateInfo(
                physicalDevice_.reference(),
                surface_.reference(),
                width,
                height
            )
        )
        .build();
    std::cout << std::format("swapchain: '{}'", (bool)swapChain_.value) << std::endl;
}
