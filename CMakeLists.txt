cmake_minimum_required(VERSION 3.14)

project(ImGuiColorTextEdit LANGUAGES CXX VERSION 1.0.0)

if (NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE Release)
endif ()

include(GNUInstallDirs)
include(CheckLanguage)
include(CMakePackageConfigHelpers)

list (APPEND CMAKE_PREFIX_PATH "${CMAKE_INSTALL_PREFIX}")

set(CMAKE_INSTALL_LIBEXECDIR lib)

#######################################
# SET FILES AND DIRECTORIES TO BE BUILT
#######################################

include_directories("${CMAKE_CURRENT_LIST_DIR}")

#######################################
# SET FILES AND DIRECTORIES TO BE BUILT
#######################################

file(GLOB CORE_HEADERS "*.h")
file(GLOB CORE_SRC "*.cpp")

add_library(${PROJECT_NAME} SHARED ${CORE_SRC})
set_target_properties(${PROJECT_NAME} PROPERTIES VERSION 1.0.0)
set_target_properties(${PROJECT_NAME} PROPERTIES SOVERSION 1)

#######################################
# FIND REQUIRES
#######################################

find_package(imgui REQUIRED)
if(imgui_FOUND)
   target_link_libraries(${PROJECT_NAME} PUBLIC ${imgui_LIBRARIES})
   target_include_directories(${PROJECT_NAME} PRIVATE ${imgui_INCLUDE_DIRS})
endif()

#####################
# CONFIGURATION FILES
#####################

file(WRITE ${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
"include(\${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}-targets.cmake)
set(${PROJECT_NAME}_INCLUDE_DIRS ${CMAKE_INSTALL_PREFIX}/include/${PROJECT_NAME})
set(${PROJECT_NAME}_LINK_DIRS ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR})
set(${PROJECT_NAME}_LIBRARIES ${PROJECT_NAME} ${AIO_LIBRARIES})
set(${PROJECT_NAME}_FOUND TRUE)
")
write_basic_package_version_file(
   "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
   VERSION ${PROJECT_VERSION}
   COMPATIBILITY SameMajorVersion)

####################
# INSTALLATION RULES
####################

install(FILES
   "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
   "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
   DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
   COMPONENT Development)

install(FILES ${CORE_HEADERS}
   DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
   COMPONENT headers)

install(TARGETS ${PROJECT_NAME}
   EXPORT ${PROJECT_NAME}-targets
   ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT Development
   LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT Runtime
   RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT Runtime)

install(EXPORT ${PROJECT_NAME}-targets
    NAMESPACE ${PROJECT_NAME}::
    FILE ${PROJECT_NAME}-targets.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})

##################################
# PRINT OPERATIONS TO BE CONDUCTED
##################################

message("-- Build mode            : " ${CMAKE_BUILD_TYPE})
message("-- Install directory     : " ${CMAKE_INSTALL_PREFIX})
