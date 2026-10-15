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
ca2_add_port(base/zlib)
ca2_add_port(base/archive)
ca2_add_port(base/unac)
ca2_add_port(base/sqlite)
ca2_add_port(base/pcre)
ca2_add_port(imaging/port_png)
ca2_add_port(graphics/freetype)
ca2_add_port(graphics/pixman)
ca2_add_port(graphics/cairo)

set(port_components iconv idn zlib archive unac sqlite pcre png freetype pixman cairo)
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
add_custom_target(port_all DEPENDS ${port_components} port_headers)
# Preserve convenient component target names used by CLion profiles/scripts.
foreach(component IN ITEMS pcre sqlite unac idn zlib archive)
    add_custom_target(port_${component} DEPENDS ${component} port_headers)
endforeach()
add_custom_target(port_graphics DEPENDS png freetype pixman cairo port_headers)

# Keep the ca2 library names while linking the MinGW OpenSSL import libraries.
foreach(openssl_component IN ITEMS crypto ssl)
    add_library(lib${openssl_component} SHARED IMPORTED GLOBAL)
    foreach(port_config IN ITEMS Debug Release RelWithDebInfo MinSizeRel)
        string(TOUPPER "${port_config}" port_config_upper)
        set_property(TARGET lib${openssl_component} APPEND PROPERTY IMPORTED_CONFIGURATIONS "${port_config}")
        set_target_properties(lib${openssl_component} PROPERTIES
            "IMPORTED_IMPLIB_${port_config_upper}" "${PORT_STORAGE_ROOT}/${port_config}/binary/lib/lib${openssl_component}.dll.a"
            "IMPORTED_LOCATION_${port_config_upper}" "${PORT_STORAGE_ROOT}/${port_config}/binary/bin/lib${openssl_component}-3.dll")
    endforeach()
endforeach()
set_property(TARGET libssl PROPERTY INTERFACE_LINK_LIBRARIES libcrypto)
