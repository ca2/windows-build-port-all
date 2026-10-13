cmake_minimum_required(VERSION 3.16)
project(port)

set(ZLIB_INCLUDE_DIR "")

if(MINGW AND CMAKE_SIZEOF_VOID_P EQUAL 4
   AND CMAKE_C_COMPILER_ID STREQUAL "GNU"
   AND CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    include(mingw.cmake)
endif()

if(INCLUDE_AUDIO)

    add_subdirectory(base/id3lib)

endif()


if(INCLUDE_OPENGL)

    add_subdirectory(graphics3d/glad)

endif()
