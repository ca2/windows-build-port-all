# ReactOS ports use the original cpp-port targets in this CMake build.
set(PORT_STORAGE_ROOT "${CMAKE_SOURCE_DIR}/../operating_system/storage-windows/Win32"
    CACHE PATH "Directory for ReactOS port libraries")
set(port_stage "${PORT_STORAGE_ROOT}/$<CONFIG>/third")
set(port_os_config "${WORKSPACE_FOLDER}/operating_system/operating_system-windows")
# Port sources must use their own headers, not ca2's broad/symlink include tree.
# This property is local to the port directory and its children.
set_property(DIRECTORY PROPERTY INCLUDE_DIRECTORIES
    "${port_os_config};${port_os_config}/configuration/common")

function(ca2_add_port directory)
    # Prevent source/include lists from leaking between sibling projects.
    set(library_source "")
    set(library_references "")
    set(library_include_directories "")
    set(this_system_libraries "")
    set(CMAKE_C_STANDARD 99)
    add_subdirectory("${directory}" "${CMAKE_CURRENT_BINARY_DIR}/${directory}" EXCLUDE_FROM_ALL)
endfunction()

ca2_add_port(base/iconv)
ca2_add_port(base/idn)
ca2_add_port(base/mpg123)
ca2_add_port(base/zlib)
ca2_add_port(base/archive)
ca2_add_port(base/unac)
ca2_add_port(base/sqlite)
ca2_add_port(base/pcre)
ca2_add_port(imaging/port_png)
ca2_add_port(graphics/freetype)
ca2_add_port(graphics/pixman)
ca2_add_port(graphics/cairo)

include("${CMAKE_CURRENT_LIST_DIR}/port-freeimage.cmake")

set(port_components port_jpeg port_webp port_jxr port_openexr port_openjpeg port_tiff4 port_rawlite port_freeimage iconv idn zlib archive unac sqlite pcre png freetype pixman cairo)
foreach(component IN LISTS port_components)
    set_target_properties(${component} PROPERTIES
        PREFIX "" DEBUG_POSTFIX ""
        RUNTIME_OUTPUT_DIRECTORY "${port_stage}/binary"
        ARCHIVE_OUTPUT_DIRECTORY "${port_stage}/library")
    target_compile_definitions(${component} PRIVATE __REACTOS__ _WIN32_WINNT=0x0501 WINVER=0x0501)
endforeach()

# Publish headers alongside the DLL/import-library outputs without rerunning a
# nested configure/build/install process or modifying the source headers.
get_target_property(freetype_binary freetype BINARY_DIR)
get_target_property(cairo_binary cairo BINARY_DIR)
get_target_property(pixman_binary pixman BINARY_DIR)
get_target_property(zlib_binary zlib BINARY_DIR)
get_target_property(pcre_binary pcre BINARY_DIR)
add_custom_target(port_headers
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${port_stage}/include"
    COMMAND "${CMAKE_COMMAND}" -E copy_directory_if_different "${CMAKE_CURRENT_SOURCE_DIR}/base/idn/include/idn" "${port_stage}/include/idn"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/base/iconv/include/iconv.h" "${CMAKE_CURRENT_SOURCE_DIR}/base/idn/lib/idn-free.h" "${CMAKE_CURRENT_SOURCE_DIR}/base/idn/lib/stringprep.h" "${CMAKE_CURRENT_SOURCE_DIR}/base/idn/lib/punycode.h" "${CMAKE_CURRENT_SOURCE_DIR}/base/unac/include/unac.h" "${CMAKE_CURRENT_SOURCE_DIR}/base/sqlite/include/sqlite3.h" "${CMAKE_CURRENT_SOURCE_DIR}/base/zlib/include/zlib.h" "${zlib_binary}/zconf.h" "${pcre_binary}/pcre2.h" "${CMAKE_CURRENT_SOURCE_DIR}/base/archive/archive/libarchive/archive.h" "${CMAKE_CURRENT_SOURCE_DIR}/base/archive/archive/libarchive/archive_entry.h" "${port_stage}/include"
    COMMAND "${CMAKE_COMMAND}" -E copy_directory_if_different "${CMAKE_CURRENT_SOURCE_DIR}/graphics/freetype/include" "${port_stage}/include"
    COMMAND "${CMAKE_COMMAND}" -E copy_directory_if_different "${cairo_binary}/generated/cairo" "${port_stage}/include/cairo"
    COMMAND "${CMAKE_COMMAND}" -E copy_directory_if_different "${CMAKE_CURRENT_SOURCE_DIR}/graphics/pixman/include/pixman" "${port_stage}/include/pixman"
    COMMAND "${CMAKE_COMMAND}" -E copy_directory_if_different "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_png/include" "${port_stage}/include"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${pixman_binary}/generated/pixman/pixman-version.h" "${port_stage}/include/pixman"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${port_os_config}/configuration/pngconf.h" "${port_os_config}/configuration/pnglibconf.h" "${port_stage}/include"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${freetype_binary}/include/freetype/config/ftconfig.h" "${freetype_binary}/include/freetype/config/ftoption.h" "${port_stage}/include/freetype/config"
    COMMENT "Staging port headers"
    VERBATIM)
# Track development-runtime copies as build outputs so a missing/stale DLL is
# restored even when its library target itself needs no rebuild.
set(port_runtime_outputs "")
foreach(component IN LISTS port_components)
    set(runtime_dll "${EXECUTABLE_OUTPUT_PATH}/${component}.dll")
    add_custom_command(OUTPUT "${runtime_dll}"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${EXECUTABLE_OUTPUT_PATH}"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "$<TARGET_FILE:${component}>" "${runtime_dll}"
        COMMAND "${CMAKE_COMMAND}"
            "-DSOURCE_FILE=$<TARGET_FILE:${component}>"
            "-DDESTINATION=${CA2_REACTOS_DEPLOY_DIRECTORY}"
            "-DOBJCOPY=${CMAKE_OBJCOPY}"
            -P "${CMAKE_SOURCE_DIR}/tools/reactos-import-audit/deployment-copy.cmake"
        DEPENDS ${component}
        COMMENT "Staging ${component}.dll beside the applications"
        VERBATIM)
    add_custom_target(port_runtime_${component} DEPENDS "${runtime_dll}")
    list(APPEND port_runtime_outputs "${runtime_dll}")
endforeach()
add_custom_target(port_runtime DEPENDS ${port_runtime_outputs})
add_custom_target(port_all DEPENDS ${port_components} port_headers port_runtime)
# Preserve convenient component target names used by CLion profiles/scripts.
foreach(component IN ITEMS pcre sqlite unac idn zlib archive)
    add_custom_target(port_${component} DEPENDS ${component} port_headers)
endforeach()
add_custom_target(port_graphics DEPENDS png freetype pixman cairo port_headers)

# Build the SDK and publish libcrypto/libssl instead of assuming prebuilt files exist.
include("${CMAKE_SOURCE_DIR}/tools/openssl/windows-build-all.cmake")

if(INCLUDE_AUDIO)
    include("${CMAKE_SOURCE_DIR}/tools/ffmpeg/windows-build-all.cmake")
    include(port-fluidsynth.cmake)
endif()
