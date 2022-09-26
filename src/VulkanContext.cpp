#include "VulkanContext.hpp"
#define EXQUDENS_CPP_VULKAN_IMPLEMENTATION
#include "VulkanContext.hpp"
#include "exqudens/vulkan/SubpassDescription.hpp"
#include "exqudens/vulkan/GraphicsPipelineCreateInfo.hpp"
#include <GLFW/glfw3.h>
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
    // need to extract the width and height of the frame buffer 
    // from glfw for creating the swap chain
    int width, height;
    glfwGetFramebufferSize(window, &width, &height);
    createSwapChain(width, height);
    createDepthBuffer();
    createRenderPass();
    createFrameBuffer();
    createGraphicsPipeline();
}

void VulkanContext::createInstance() {
    try {
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
    } catch (...) {
        std::throw_with_nested(std::runtime_error(CALL_INFO()));
    }
}
 
void VulkanContext::createSurface(GLFWwindow* window) {
    // create surface for glfw. TODOMG In the future this will need to be done completely
    // differently. Just want to do this for now. In the future this will need to support 
    // different surfaces.
    try {
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
    catch (...) {
        std::throw_with_nested(std::runtime_error(CALL_INFO()));
    }
}

void VulkanContext::createPhysicalDevice() {
    try {
        physicalDevice_ = PhysicalDevice::builder()
            .setInstance(instance_.value)
            .setSurface(surface_.value)
            .addEnabledExtensionName(VK_KHR_SWAPCHAIN_EXTENSION_NAME)
            .setFeatures(vk::PhysicalDeviceFeatures().setSamplerAnisotropy(true))
            .addQueueRequirement(vk::QueueFlagBits::eCompute)
            .addQueueRequirement(vk::QueueFlagBits::eTransfer)
            .addQueueRequirement(vk::QueueFlagBits::eGraphics, true)
            .setQueuePriority(1.0f)
            .build();
        std::cout << std::format("physicalDevice: '{}'", (bool)physicalDevice_.value) << std::endl;
    }
    catch (...) {
        std::throw_with_nested(std::runtime_error(CALL_INFO()));
    }
}

void VulkanContext::createLogicalDevice() {
    try {
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
    catch (...) {
        std::throw_with_nested(std::runtime_error(CALL_INFO()));
    }
}

void VulkanContext::createSwapChain(uint32_t width, uint32_t height) {
    try {
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
        // set the swap chain image format that was determined during swap chain image 
        // creation
        swapChainImageFormat_ = swapChain_.createInfo.imageFormat;

        // create the VkImageViews for the swap chains
        for (const VkImage& vkImage : swapChain_.reference().getImages()) {
            // create swap chain image view using the 
            swapChainImageViews_.emplace_back(ImageView::builder()
                .setDevice(device_.value)
                .setCreateInfo(
                    vk::ImageViewCreateInfo()
                    .setFlags({})
                    .setImage(static_cast<vk::Image>(vkImage))
                    .setViewType(vk::ImageViewType::e2D)
                    .setFormat(swapChainImageFormat_)
                    .setComponents({})
                    .setSubresourceRange(
                        vk::ImageSubresourceRange()
                        .setAspectMask(vk::ImageAspectFlagBits::eColor)
                        .setBaseMipLevel(0)
                        .setLevelCount(1)
                        .setBaseArrayLayer(0)
                        .setLayerCount(1)
                    )
                )
                .build());
        }
        std::ranges::for_each(swapChainImageViews_, [](const auto& o1) {std::cout << std::format("swapchainImageViews: '{}'", (bool)o1.value) << std::endl; });
    }
    catch (...) {
        std::throw_with_nested(std::runtime_error(CALL_INFO()));
    }
}

void VulkanContext::createRenderPass() {
    try {
        renderPass_ = RenderPass::builder()
            .setDevice(device_.value)
            // add the color attachment 
            .addAttachment(
                vk::AttachmentDescription(
                    vk::AttachmentDescriptionFlags(),
                    swapChainImageFormat_,
                    vk::SampleCountFlagBits::e1,
                    vk::AttachmentLoadOp::eClear,
                    vk::AttachmentStoreOp::eStore,
                    vk::AttachmentLoadOp::eClear,
                    vk::AttachmentStoreOp::eDontCare,
                    vk::ImageLayout::eColorAttachmentOptimal,
                    vk::ImageLayout::eColorAttachmentOptimal
                )
            )
            // add the depth attachment
            .addAttachment(
                vk::AttachmentDescription(
                    vk::AttachmentDescriptionFlags(),
                    vk::Format::eD32Sfloat,
                    vk::SampleCountFlagBits::e1,
                    vk::AttachmentLoadOp::eClear,
                    vk::AttachmentStoreOp::eStore,
                    vk::AttachmentLoadOp::eDontCare,
                    vk::AttachmentStoreOp::eDontCare,
                    vk::ImageLayout::eDepthStencilAttachmentOptimal,
                    vk::ImageLayout::eDepthStencilAttachmentOptimal
                )
            )
            // might need this is the future but for now just put it here
            // for reference. 
            //.addDependency(vk::SubpassDependency())
            .addSubpass(
                SubpassDescription()
                .setPipelineBindPoint(vk::PipelineBindPoint::eGraphics)
                .addColorAttachment(
                    vk::AttachmentReference()
                    .setAttachment(0)
                    .setLayout(vk::ImageLayout::eColorAttachmentOptimal)
                )
                .setDepthStencilAttachment(
                    vk::AttachmentReference()
                    .setAttachment(1)
                    .setLayout(vk::ImageLayout::eDepthStencilAttachmentOptimal)
                )
            )
            .build();
        std::cout << std::format("RenderPass: '{}'", (bool)renderPass_.value) << std::endl;
    }
    catch (...) {
        std::throw_with_nested(std::runtime_error(CALL_INFO()));
    }
}

void VulkanContext::createDepthBuffer()
{
    try {
        depthBuffer_ = Image::builder()
            .setPhysicalDevice(physicalDevice_.value)
            .setDevice(device_.value)
            .setCreateInfo(
                vk::ImageCreateInfo()
                .setImageType(vk::ImageType::e2D)
                .setFormat(Utility::imageDepthFormat(physicalDevice_.reference()))
                .setExtent(
                    vk::Extent3D()
                    .setWidth(swapChain_.createInfo.imageExtent.width)
                    .setHeight(swapChain_.createInfo.imageExtent.height)
                    .setDepth(1)
                )
                .setMipLevels(1)
                .setArrayLayers(1)
                .setSamples(vk::SampleCountFlagBits::e1)
                .setTiling(vk::ImageTiling::eOptimal)
                .setUsage(vk::ImageUsageFlagBits::eDepthStencilAttachment)
                .setSharingMode(vk::SharingMode::eExclusive)
                .setQueueFamilyIndices({})
                .setInitialLayout(vk::ImageLayout::eUndefined)
            )
            .setMemoryCreateInfo(vk::MemoryPropertyFlagBits::eDeviceLocal)
            .build();
        std::cout << std::format("depthBuffer: '{}'", (bool)depthBuffer_.value) << std::endl;
        depthBufferImageView_ = ImageView::builder()
            .setDevice(device_.value)
            .setCreateInfo(
                vk::ImageViewCreateInfo()
                .setImage(*depthBuffer_.reference())
                .setFormat(depthBuffer_.createInfo.format)
                .setViewType(vk::ImageViewType::e2D)
                .setFlags({})
                .setComponents({})
                .setSubresourceRange(
                    vk::ImageSubresourceRange()
                    .setAspectMask(vk::ImageAspectFlagBits::eDepth)
                    .setBaseMipLevel(0)
                    .setLevelCount(1)
                    .setBaseArrayLayer(0)
                    .setLayerCount(1)
                )
            )
            .build();
        std::cout << std::format("depthBufferImageView: '{}'", (bool)depthBufferImageView_.value) << std::endl;
    }
    catch (...) {
        std::throw_with_nested(std::runtime_error(CALL_INFO()));
    }
}

void VulkanContext::createFrameBuffer()
{
    try {
        for (auto& swapChainImage : swapChainImageViews_)
        {
            framebuffers_.push_back(Framebuffer::builder()
                .setDevice(device_.value)
                .addAttachment(*swapChainImage.reference())
                .addAttachment(*depthBufferImageView_.reference())
                .setCreateInfo(
                    vk::FramebufferCreateInfo()
                    .setRenderPass(*renderPass_.reference())
                    .setWidth(swapChain_.createInfo.imageExtent.width)
                    .setHeight(swapChain_.createInfo.imageExtent.height)
                    .setLayers(1)
                )
                .build());
        }
        std::ranges::for_each(swapChainImageViews_, [](const auto& o1) {std::cout << std::format("framebuffers: '{}'", (bool)o1.value) << std::endl; });
    }
    catch (...) {
        std::throw_with_nested(std::runtime_error(CALL_INFO()));
    }
}

void VulkanContext::createGraphicsPipeline()
{
    try {
        pipeline_ = Pipeline::builder()
            .setDevice(device_.value)
            .addPath("shaders/triangle.vert.spv")
            .addPath("shaders/triangle.frag.spv")
            //.addSetLayout(*descriptorSetLayout_.reference())
            .setGraphicsCreateInfo(
                GraphicsPipelineCreateInfo()
                .setRenderPass(*renderPass_.reference())
                .setSubpass(0)
                .setVertexInputState(
                    PipelineVertexInputStateCreateInfo()
                    .setVertexBindingDescriptions({})
                    .setVertexAttributeDescriptions({})
                )
                .setInputAssemblyState(
                    vk::PipelineInputAssemblyStateCreateInfo()
                    .setTopology(vk::PrimitiveTopology::eTriangleList)
                    .setPrimitiveRestartEnable(false)
                )
                .setViewportState(
                    PipelineViewportStateCreateInfo()
                    .setViewports({
                        vk::Viewport()
                            .setWidth((float)swapChain_.createInfo.imageExtent.width)
                            .setHeight((float)swapChain_.createInfo.imageExtent.height)
                            .setMinDepth(0.0)
                            .setMaxDepth(1.0)
                            .setX(0.0)
                            .setY(0.0)
                        })
                    .setScissors({
                        vk::Rect2D()
                            .setOffset({0, 0})
                            .setExtent(swapChain_.createInfo.imageExtent)
                        })
                )
                .setRasterizationState(
                    vk::PipelineRasterizationStateCreateInfo()
                    .setDepthClampEnable(false)
                    .setRasterizerDiscardEnable(false)
                    .setPolygonMode(vk::PolygonMode::eFill)
                    .setCullMode(vk::CullModeFlagBits::eBack)
                    .setFrontFace(vk::FrontFace::eCounterClockwise)
                    .setLineWidth(1.0)
                    .setDepthBiasEnable(false)
                    .setDepthBiasConstantFactor(0.0)
                    .setDepthBiasClamp(0.0)
                    .setDepthBiasSlopeFactor(0.0)
                )
                .setMultisampleState(
                    vk::PipelineMultisampleStateCreateInfo()
                    .setRasterizationSamples(vk::SampleCountFlagBits::e1)
                    .setSampleShadingEnable(false)
                    .setMinSampleShading(1.0)
                    .setPSampleMask(nullptr)
                    .setAlphaToCoverageEnable(false)
                    .setAlphaToOneEnable(false)
                )
                .setDepthStencilState(
                    vk::PipelineDepthStencilStateCreateInfo()
                    .setDepthTestEnable(true)
                    .setDepthWriteEnable(true)
                    .setDepthCompareOp(vk::CompareOp::eLess)
                    .setDepthBoundsTestEnable(false)
                    .setStencilTestEnable(false)
                    .setFront({})
                    .setBack({})
                    .setMinDepthBounds(0.0)
                    .setMaxDepthBounds(1.0)
                )
                .setColorBlendState(
                    PipelineColorBlendStateCreateInfo()
                    .setLogicOpEnable(false)
                    .setLogicOp(vk::LogicOp::eCopy)
                    .setBlendConstants({ 0.0f, 0.0f, 0.0f, 0.0f })
                    .setAttachments({
                        vk::PipelineColorBlendAttachmentState()
                            .setBlendEnable(false)
                            .setColorBlendOp(vk::BlendOp::eAdd)
                            .setSrcColorBlendFactor(vk::BlendFactor::eOne)
                            .setDstColorBlendFactor(vk::BlendFactor::eZero)
                            .setAlphaBlendOp(vk::BlendOp::eAdd)
                            .setSrcAlphaBlendFactor(vk::BlendFactor::eOne)
                            .setDstAlphaBlendFactor(vk::BlendFactor::eZero)
                            .setColorWriteMask(vk::ColorComponentFlagBits::eR | vk::ColorComponentFlagBits::eG | vk::ColorComponentFlagBits::eB | vk::ColorComponentFlagBits::eA)
                        })
                )
            )
            .build();
        std::cout << std::format("pipeline: '{}'", (bool)pipeline_.value) << std::endl;
    }
    catch (...) {
        std::throw_with_nested(std::runtime_error(CALL_INFO()));
    }
}
