//#include "Instance.hpp"
#include "exqudens/vulkan/Instance.hpp"
#include "ErrorUtils.hpp"

using namespace exqudens::vulkan;
int main() {
    try {
        std::vector<const char*> glfwInstanceRequiredExtensions;
        std::vector<const char*> enabledExtensionNames = glfwInstanceRequiredExtensions;
        enabledExtensionNames.emplace_back(VK_EXT_DEBUG_UTILS_EXTENSION_NAME);

        Instance instance = Instance::builder()
            .addEnabledLayerName("VK_LAYER_KHRONOS_validation")
            .setEnabledExtensionNames(enabledExtensionNames)
            .setApplicationInfo(
                vk::ApplicationInfo()
                .setPApplicationName("Exqudens Application")
                .setApplicationVersion(VK_MAKE_VERSION(1, 0, 0))
                .setPEngineName("Exqudens Engine")
                .setEngineVersion(VK_MAKE_VERSION(1, 0, 0))
                .setApiVersion(VK_API_VERSION_1_0)
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
        std::cout << std::format("instance: '{}'", (bool)instance.value) << std::endl;
    }
    catch (const std::exception& e) {
        std::cerr << ErrorUtils::toString(e);
    }
}











