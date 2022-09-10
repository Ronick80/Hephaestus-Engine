#pragma once

#include "exqudens/vulkan/Instance.hpp"
#include "exqudens/vulkan/Device.hpp"
#include "exqudens/vulkan/PhysicalDevice.hpp"
#include "exqudens/vulkan/Surface.hpp"
#include "exqudens/vulkan/SwapChain.hpp"
#include "utils.hpp"
#include <GLFW/glfw3.h>

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

    void init(GLFWwindow* window);

private:
    // all required objects that need to be created for rendering with vulkan
    // this comprises the "Vulkan Context"
    Instance instance_;
    Surface surface_;
    PhysicalDevice physicalDevice_;
    Device device_;
    Swapchain swapChain_;

    void createInstance();
     
    void createSurface(GLFWwindow* window);

    void createPhysicalDevice();

    void createLogicalDevice();

    void createSwapChain(uint32_t width, uint32_t height);

};
