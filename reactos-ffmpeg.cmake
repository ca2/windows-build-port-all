# Build only the FFmpeg libraries used by the audio resampler. All XP
# adaptations live outside the downloaded, checksum-pinned source tree.
include(ExternalProject)
find_program(ffmpeg_xp_bash bash.exe HINTS "C:/msys64/usr/bin" REQUIRED NO_DEFAULT_PATH)
set(ffmpeg_xp_root "${CMAKE_BINARY_DIR}/ffmpeg-xp")
set(ffmpeg_xp_install "${PORT_STORAGE_ROOT}/${CMAKE_BUILD_TYPE}/third/ffmpeg-xp")
file(MAKE_DIRECTORY "${ffmpeg_xp_install}/include")
ExternalProject_Add(ffmpeg_xp_build
    URL https://ffmpeg.org/releases/ffmpeg-6.1.4.tar.xz
    URL_HASH SHA256=a231e3d5742c44b1cdaebfb98ad7b6200d12763e0b6db9e1e2c5891f2c083a18
    DOWNLOAD_DIR "${ffmpeg_xp_root}"
    SOURCE_DIR "${ffmpeg_xp_root}/source"
    BINARY_DIR "${ffmpeg_xp_root}/build"
    CONFIGURE_COMMAND "${CMAKE_COMMAND}"
        "-DSOURCE_DIR=<SOURCE_DIR>" "-DBINARY_DIR=<BINARY_DIR>"
        "-DINSTALL_DIR=${ffmpeg_xp_install}" "-DBASH=${ffmpeg_xp_bash}"
        "-DCC=${CMAKE_C_COMPILER}" "-DAR=${CMAKE_AR}"
        "-DRANLIB=${CMAKE_RANLIB}" "-DNM=${CMAKE_NM}" "-DSTRIP=${CMAKE_STRIP}"
        -P "${CMAKE_CURRENT_LIST_DIR}/configure-ffmpeg-xp.cmake"
    BUILD_COMMAND "${ffmpeg_xp_bash}" -lc "cd '<BINARY_DIR>' && /usr/bin/make -j4 WINDRES='${CMAKE_RC_COMPILER}'"
    INSTALL_COMMAND "${ffmpeg_xp_bash}" -lc "cd '<BINARY_DIR>' && /usr/bin/make install-libs install-headers"
    BUILD_BYPRODUCTS
        "${ffmpeg_xp_install}/lib/libavutil.dll.a"
        "${ffmpeg_xp_install}/lib/libswresample.dll.a"
        "${ffmpeg_xp_install}/bin/avutil-58.dll"
        "${ffmpeg_xp_install}/bin/swresample-4.dll"
    LOG_DOWNLOAD ON LOG_CONFIGURE ON LOG_BUILD ON LOG_INSTALL ON)
ExternalProject_Add_StepDependencies(ffmpeg_xp_build configure
    "${CMAKE_CURRENT_LIST_DIR}/configure-ffmpeg-xp.cmake" "${CMAKE_CURRENT_LIST_DIR}/ffmpeg-xp-compat.h")
foreach(component IN ITEMS avutil swresample)
    if(component STREQUAL "avutil")
        set(major 58)
    else()
        set(major 4)
    endif()
    add_library(${component} SHARED IMPORTED GLOBAL)
    set_target_properties(${component} PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${ffmpeg_xp_install}/include"
        IMPORTED_IMPLIB "${ffmpeg_xp_install}/lib/lib${component}.dll.a"
        IMPORTED_LOCATION "${ffmpeg_xp_install}/bin/${component}-${major}.dll")
    add_dependencies(${component} ffmpeg_xp_build)
    add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/${component}-${major}.dll"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "$<TARGET_FILE:${component}>" "${EXECUTABLE_OUTPUT_PATH}/${component}-${major}.dll"
        COMMAND "${CMAKE_COMMAND}" "-DSOURCE_FILE=$<TARGET_FILE:${component}>"
            "-DDESTINATION=${CA2_REACTOS_DEPLOY_DIRECTORY}" "-DOBJCOPY=${CMAKE_OBJCOPY}"
            -P "${CMAKE_SOURCE_DIR}/tools/reactos-import-audit/deployment-copy.cmake"
        DEPENDS ffmpeg_xp_build "$<TARGET_FILE:${component}>" VERBATIM)
    add_custom_target(port_runtime_${component}
        DEPENDS "${EXECUTABLE_OUTPUT_PATH}/${component}-${major}.dll")
endforeach()
set_property(TARGET swresample PROPERTY INTERFACE_LINK_LIBRARIES avutil)

add_dependencies(port_all ffmpeg_xp_build port_runtime_avutil port_runtime_swresample)
