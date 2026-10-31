# Keep FluidSynth's vendored build untouched; configure it through the outer wrapper.
set(USE_PORT_LIBFLUIDSYNTH ON CACHE BOOL "Use the bundled FluidSynth library")
if(__REACTOS__)
    set(windows-version 0x0501)
endif()
ca2_add_port(audio/fluidsynth)
if(__REACTOS__)
    unset(windows-version)
endif()

set_target_properties(libfluidsynth PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${port_stage}/binary"
    ARCHIVE_OUTPUT_DIRECTORY "${port_stage}/library")
set(fluidsynth_deploy_command)
if(__REACTOS__)
    target_compile_definitions(libfluidsynth-OBJ PRIVATE __REACTOS__)
    list(APPEND fluidsynth_deploy_command COMMAND "${CMAKE_COMMAND}"
        "-DSOURCE_FILE=$<TARGET_FILE:libfluidsynth>"
        "-DDESTINATION=${CA2_REACTOS_DEPLOY_DIRECTORY}"
        "-DOBJCOPY=${CMAKE_OBJCOPY}"
        -P "${CMAKE_SOURCE_DIR}/operating_system/operating_system-windows/tools/reactos-import-audit/deployment-copy.cmake")
endif()

add_custom_target(port_runtime_fluidsynth
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${EXECUTABLE_OUTPUT_PATH}"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
        "$<TARGET_FILE:libfluidsynth>" "${EXECUTABLE_OUTPUT_PATH}/$<TARGET_FILE_NAME:libfluidsynth>"
    ${fluidsynth_deploy_command}
    DEPENDS libfluidsynth
    COMMENT "Staging FluidSynth beside the applications"
    VERBATIM)
add_dependencies(port_all libfluidsynth port_runtime_fluidsynth)
