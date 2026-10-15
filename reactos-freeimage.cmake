# Outer adapter: never patch the codec sources or their inner repositories.
# All consumers must use the same in-tree JPEG headers and DLL ABI.
set(USE_SYSTEM_JPEG OFF)
ca2_add_port(imaging/port_jpeg)
ca2_add_port(imaging/port_webp)
set_target_properties(port_jpeg PROPERTIES DEBUG_POSTFIX "")
target_compile_definitions(port_jpeg PRIVATE JPEG_EXPORTS)
if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(port_jpeg PRIVATE -include stddef.h)
endif()
target_include_directories(port_jpeg PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/common/include")
target_include_directories(port_webp PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_webp/include")

set(fi_root "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_freeimage")
file(GLOB fi_sources CONFIGURE_DEPENDS
    "${fi_root}/Source/FreeImage/*.cpp" "${fi_root}/Source/FreeImage/*.c"
    "${fi_root}/Source/FreeImageToolkit/*.cpp" "${fi_root}/Source/Metadata/*.cpp"
    "${fi_root}/Source/DeprecationManager/*.cpp")
# Build every codec dependency through its existing outer port project.
foreach(codec IN ITEMS port_jxr port_openexr port_openjpeg port_tiff4 port_rawlite)
    ca2_add_port(imaging/${codec})
endforeach()
get_target_property(fi_zlib_binary zlib BINARY_DIR)
foreach(codec IN ITEMS port_openexr port_tiff4 port_rawlite)
    target_include_directories(${codec} PRIVATE "${fi_zlib_binary}" "${CMAKE_CURRENT_SOURCE_DIR}/base/zlib/include" "${CMAKE_CURRENT_SOURCE_DIR}/common/include" "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_jpeg/include")
endforeach()
target_compile_definitions(port_jxr PRIVATE __MINGW64_TOOLCHAIN__)
target_link_libraries(port_openexr PRIVATE zlib)
add_library(port_freeimage SHARED ${fi_sources})
target_compile_definitions(port_freeimage PRIVATE __REACTOS__ FREEIMAGE_EXPORTS
    FREEIMAGE_USE_SYSTEM_JPEG=0 _WIN32_WINNT=0x0501 WINVER=0x0501)
target_include_directories(port_freeimage PRIVATE
    "${fi_root}/include" "${fi_root}/Source" "${fi_zlib_binary}" "${CMAKE_CURRENT_SOURCE_DIR}/common/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_png/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_jpeg/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_webp/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_jxr/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_openexr/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_openjpeg/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_tiff4/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_rawlite/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/base/zlib/include"
    "${port_os_config}/configuration")
target_link_libraries(port_freeimage PRIVATE port_jpeg port_webp png zlib port_jxr port_openexr port_openjpeg port_tiff4 port_rawlite)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    # The port only defines its deprecation diagnostic for MSVC. Preserve the
    # diagnostic on GCC/Clang using their return-address intrinsic.
    set(fi_compiler_header "${CMAKE_CURRENT_BINARY_DIR}/freeimage-compiler-compat.h")
    file(CONFIGURE OUTPUT "${fi_compiler_header}" CONTENT "#if defined(__REACTOS__) && defined(__GNUC__)\n#define DEPRECATE(a,b) { DeprecationMgr::GetInstance()->AddDeprecatedFunction(a,b,__builtin_return_address(0)); }\n#endif\n")
    target_compile_options(port_freeimage PRIVATE "$<$<COMPILE_LANGUAGE:CXX>:-include${fi_compiler_header}>")
endif()
file(GLOB fi_exr_win32_sources "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_openexr/IlmThread/*Win32.cpp")
set_source_files_properties(${fi_exr_win32_sources}
    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_openexr"
    PROPERTIES INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_openexr/include/port_openexr")
# This generated fax table includes the MSVC-configured TIFF types without
# a CRT header; MinGW supplies their __int64 spelling through _mingw.h.
set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_tiff4/tif_fax3sm.c"
    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_tiff4"
    PROPERTIES COMPILE_OPTIONS "-include;_mingw.h")
target_include_directories(port_rawlite PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_rawlite/include")
set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_tiff4/tif_win32.c"
    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_tiff4"
    PROPERTIES INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_tiff4/include/port_tiff4")
# TIFF's Win32 diagnostic backend uses ANSI CRT strings explicitly.
set_property(SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_tiff4/tif_win32.c"
    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/imaging/port_tiff4"
    APPEND PROPERTY COMPILE_OPTIONS -UUNICODE -U_UNICODE)
target_compile_definitions(port_rawlite PRIVATE LIBRAW_BUILDLIB)
# LibRaw uses Winsock's byte-order helpers; these APIs are available on XP.
target_link_libraries(port_rawlite PRIVATE ws2_32)

# The plugin registry uses WINDOWS (rather than _WIN32) for JPEG XR.
set_source_files_properties("${fi_root}/Source/FreeImage/Plugin.cpp"
    PROPERTIES COMPILE_DEFINITIONS WINDOWS)