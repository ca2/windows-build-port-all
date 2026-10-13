include(ExternalProject)

set(PORT_STORAGE_ROOT "${CMAKE_SOURCE_DIR}/../operating_system/storage-windows/Win32"
    CACHE PATH "Directory for the MinGW port libraries")
set(port_stage "${PORT_STORAGE_ROOT}/${CMAKE_BUILD_TYPE}")
set(port_build "${CMAKE_CURRENT_BINARY_DIR}/mingw/${CMAKE_BUILD_TYPE}")
set(port_common_args
    "-DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}"
    "-DCMAKE_MAKE_PROGRAM:FILEPATH=${CMAKE_MAKE_PROGRAM}"
    "-DCMAKE_BUILD_TYPE:STRING=$<CONFIG>"
    "-DCMAKE_INSTALL_PREFIX:PATH=${port_stage}")

ExternalProject_Add(port_zlib
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/mingw/zlib"
    BINARY_DIR "${port_build}/zlib"
    CMAKE_ARGS ${port_common_args}
        "-DPORT_SOURCE_DIR:PATH=${CMAKE_CURRENT_SOURCE_DIR}/base/zlib"
    BUILD_COMMAND "${CMAKE_COMMAND}" --build <BINARY_DIR> --parallel 4
    INSTALL_COMMAND "${CMAKE_COMMAND}" --install <BINARY_DIR> --config $<CONFIG>
    BUILD_ALWAYS TRUE
    EXCLUDE_FROM_ALL TRUE)

ExternalProject_Add(port_archive
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/mingw/archive"
    BINARY_DIR "${port_build}/archive"
    CMAKE_ARGS ${port_common_args}
        "-DPORT_SOURCE_DIR:PATH=${CMAKE_CURRENT_SOURCE_DIR}/base/archive/archive"
        "-DZLIB_INCLUDE_DIR:PATH=${port_stage}/include"
        "-DZLIB_LIBRARY:FILEPATH=${port_stage}/library/libzlib.dll.a"
    BUILD_COMMAND "${CMAKE_COMMAND}" --build <BINARY_DIR> --parallel 4
    INSTALL_COMMAND "${CMAKE_COMMAND}" --install <BINARY_DIR> --config $<CONFIG>
    DEPENDS port_zlib
    BUILD_ALWAYS TRUE
    EXCLUDE_FROM_ALL TRUE)

add_custom_target(port_all DEPENDS port_zlib port_archive)

# Applications consume staged libraries; building them does not invoke port_all.
foreach(port_library IN ITEMS zlib archive)
    add_library(${port_library} SHARED IMPORTED GLOBAL)
    foreach(port_config IN ITEMS Debug Release RelWithDebInfo MinSizeRel)
        string(TOUPPER "${port_config}" port_config_upper)
        set_property(TARGET ${port_library} APPEND PROPERTY IMPORTED_CONFIGURATIONS "${port_config}")
        set_target_properties(${port_library} PROPERTIES
            "IMPORTED_IMPLIB_${port_config_upper}" "${PORT_STORAGE_ROOT}/${port_config}/library/lib${port_library}.dll.a"
            "IMPORTED_LOCATION_${port_config_upper}" "${PORT_STORAGE_ROOT}/${port_config}/binary/${port_library}.dll")
    endforeach()
endforeach()
message(STATUS "Build port_all before application targets to stage MinGW zlib and libarchive")
