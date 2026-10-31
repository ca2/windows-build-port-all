cmake_minimum_required(VERSION 3.16)
project(port)

set(ZLIB_INCLUDE_DIR "")

include(port.cmake)

if(__REACTOS__ AND NOT MINGW)

   add_subdirectory(base/idn)

endif()


if(INCLUDE_AUDIO)

    add_subdirectory(base/id3lib)

    if(NOT __REACTOS__)
        get_target_property(id3lib_zlib_binary zlib BINARY_DIR)
        foreach(id3lib_target id3lib static_id3lib)
            if(TARGET ${id3lib_target})
                target_include_directories(${id3lib_target} BEFORE PRIVATE
                    "${CMAKE_CURRENT_SOURCE_DIR}/base/zlib/include" "${id3lib_zlib_binary}")
                target_link_libraries(${id3lib_target} PRIVATE zlib)
            endif()
        endforeach()
    endif()

endif()


if(INCLUDE_OPENGL)

    add_subdirectory(graphics3d/glad)

endif()



add_subdirectory(user-generation1/redshift)
