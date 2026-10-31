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

set(port_components port_jpeg port_webp port_jxr port_openexr port_openjpeg port_tiff4 port_rawlite port_freeimage iconv idn zlib archive unac sqlite pcre port_png freetype pixman cairo)
foreach(component IN LISTS port_components)
    set_target_properties(${component} PROPERTIES
        PREFIX "" DEBUG_POSTFIX ""
        RUNTIME_OUTPUT_DIRECTORY "${port_stage}/binary"
        ARCHIVE_OUTPUT_DIRECTORY "${port_stage}/library")
    if(__REACTOS__)
        target_compile_definitions(${component} PRIVATE __REACTOS__ _WIN32_WINNT=0x0501 WINVER=0x0501)
    endif()
endforeach()

if(NOT __REACTOS__)
    get_target_property(pixman_config_directory pixman BINARY_DIR)
    set(PIXMAN_VERSION_MAJOR 0)
    set(PIXMAN_VERSION_MINOR 40)
    set(PIXMAN_VERSION_MICRO 0)
    file(MAKE_DIRECTORY "${pixman_config_directory}/generated/pixman")
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/graphics/pixman/pixman/pixman-version.h.in"
                   "${pixman_config_directory}/generated/pixman/pixman-version.h" @ONLY)
    foreach(pixman_target pixman static_pixman)
        if(TARGET ${pixman_target})
            target_include_directories(${pixman_target} BEFORE PRIVATE
                "${pixman_config_directory}/generated" "${CMAKE_CURRENT_SOURCE_DIR}/graphics/pixman/include")
        endif()
    endforeach()
    get_target_property(zlib_config_directory zlib BINARY_DIR)
    get_target_property(cairo_config_directory cairo BINARY_DIR)
    file(GLOB cairo_headers CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/graphics/cairo/include/cairo/*.h")
    foreach(cairo_header IN LISTS cairo_headers)
        get_filename_component(cairo_header_name "${cairo_header}" NAME)
        configure_file("${cairo_header}" "${cairo_config_directory}/generated/cairo/${cairo_header_name}" COPYONLY)
    endforeach()
    foreach(cairo_target cairo static_cairo)
        if(TARGET ${cairo_target})
            target_include_directories(${cairo_target} BEFORE PRIVATE
                "${cairo_config_directory}/generated"
                "${CMAKE_CURRENT_SOURCE_DIR}/graphics/cairo/include"
                "${CMAKE_CURRENT_SOURCE_DIR}/graphics/pixman/include"
                "${CMAKE_CURRENT_SOURCE_DIR}/graphics/pixman/include/pixman"
                "${pixman_config_directory}/generated"
                "${CMAKE_CURRENT_SOURCE_DIR}/base/zlib/include" "${zlib_config_directory}"
                "${port_os_config}/configuration"
                "${CMAKE_CURRENT_SOURCE_DIR}/graphics/freetype/include"
                "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_png/include"
                "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_png/include/port_png")
            target_link_libraries(${cairo_target} PRIVATE zlib pixman freetype port_png)
        endif()
    endforeach()
    get_target_property(zlib_config_directory zlib BINARY_DIR)
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/base/zlib/zconf.h.cmakein"
                   "${zlib_config_directory}/zconf.h")
    foreach(zlib_target zlib static_zlib)
        if(TARGET ${zlib_target})
            target_include_directories(${zlib_target} BEFORE PRIVATE
                "${CMAKE_CURRENT_SOURCE_DIR}/base/zlib/include" "${zlib_config_directory}")
        endif()
    endforeach()
    foreach(png_target port_png static_port_png)
        if(TARGET ${png_target})
            target_include_directories(${png_target} BEFORE PRIVATE
                "${port_os_config}/configuration"
                "${CMAKE_CURRENT_SOURCE_DIR}/base/zlib/include" "${zlib_config_directory}")
            target_link_libraries(${png_target} zlib)
        endif()
    endforeach()
    foreach(iconv_target iconv static_iconv)
        if(TARGET ${iconv_target})
            target_include_directories(${iconv_target} BEFORE PRIVATE
                "${CMAKE_CURRENT_SOURCE_DIR}/base/iconv/include")
        endif()
    endforeach()
    if(MSVC)
        # The upstream project hard-codes an import-library location. Let CMake
        # use the target's configured ARCHIVE_OUTPUT_DIRECTORY instead.
        get_target_property(iconv_link_options iconv LINK_OPTIONS)
        if(iconv_link_options)
            list(FILTER iconv_link_options EXCLUDE REGEX "^/IMPLIB:")
            set_property(TARGET iconv PROPERTY LINK_OPTIONS "${iconv_link_options}")
        endif()
    endif()
    foreach(unac_target unac static_unac)
        if(TARGET ${unac_target})
            target_include_directories(${unac_target} BEFORE PRIVATE
                "${CMAKE_CURRENT_SOURCE_DIR}/base/iconv/include"
                "${CMAKE_CURRENT_SOURCE_DIR}/base/unac/include")
            target_link_libraries(${unac_target} PRIVATE iconv)
        endif()
    endforeach()
    target_link_libraries(archive PRIVATE iconv)
    if(WIN32)
        target_sources(archive PRIVATE
            "${CMAKE_CURRENT_SOURCE_DIR}/base/archive/archive/libarchive/archive_crc32.c"
            "${CMAKE_CURRENT_SOURCE_DIR}/base/archive/archive/libarchive/archive_umask.c")
        target_compile_definitions(archive PRIVATE ARCHIVE_CRYPTO_WIN)
        target_link_libraries(archive PRIVATE bcrypt zlib)
    endif()
endif()

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
    set(reactos_deploy_command)
    if(__REACTOS__)
        list(APPEND reactos_deploy_command COMMAND "${CMAKE_COMMAND}"
            "-DSOURCE_FILE=$<TARGET_FILE:${component}>"
            "-DDESTINATION=${CA2_REACTOS_DEPLOY_DIRECTORY}"
            "-DOBJCOPY=${CMAKE_OBJCOPY}"
            -P "${CMAKE_SOURCE_DIR}/operating_system/operating_system-windows/tools/reactos-import-audit/deployment-copy.cmake")
    endif()
    add_custom_command(OUTPUT "${runtime_dll}"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${EXECUTABLE_OUTPUT_PATH}"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "$<TARGET_FILE:${component}>" "${runtime_dll}"
        ${reactos_deploy_command}
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
include("${CMAKE_SOURCE_DIR}/operating_system/operating_system-windows/tools/openssl/windows-build-all.cmake")

if(INCLUDE_AUDIO)
    include("${CMAKE_SOURCE_DIR}/operating_system/operating_system-windows/tools/ffmpeg/windows-build-all.cmake")
    include(port-fluidsynth.cmake)
endif()
