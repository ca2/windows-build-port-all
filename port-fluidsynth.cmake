# Keep FluidSynth's vendored build untouched; configure it through the outer wrapper.
set(USE_PORT_LIBFLUIDSYNTH ON CACHE BOOL "Use the bundled FluidSynth library")
set(windows-version 0x0501)
ca2_add_port(audio/fluidsynth)
unset(windows-version)

set_target_properties(libfluidsynth PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${port_stage}/binary"
    ARCHIVE_OUTPUT_DIRECTORY "${port_stage}/library")
target_compile_definitions(libfluidsynth-OBJ PRIVATE
    __REACTOS__)

add_custom_target(port_runtime_fluidsynth
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${EXECUTABLE_OUTPUT_PATH}"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
        "$<TARGET_FILE:libfluidsynth>" "${EXECUTABLE_OUTPUT_PATH}/$<TARGET_FILE_NAME:libfluidsynth>"
    COMMAND "${CMAKE_COMMAND}"
        "-DSOURCE_FILE=$<TARGET_FILE:libfluidsynth>"
        "-DDESTINATION=${CA2_REACTOS_DEPLOY_DIRECTORY}"
        "-DOBJCOPY=${CMAKE_OBJCOPY}"
        -P "${CMAKE_SOURCE_DIR}/operating_system/operating_system-windows/tools/reactos-import-audit/deployment-copy.cmake"
    DEPENDS libfluidsynth
    COMMENT "Staging FluidSynth beside the applications"
    VERBATIM)
add_dependencies(port_all libfluidsynth port_runtime_fluidsynth)