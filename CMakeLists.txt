cmake_minimum_required(VERSION 3.16)
project(port)

set(ZLIB_INCLUDE_DIR "")

include(port.cmake)

if(__REACTOS__ AND NOT MINGW)

   add_subdirectory(base/idn)

endif()


if(INCLUDE_AUDIO)

    add_subdirectory(base/id3lib)

endif()


if(INCLUDE_OPENGL)

    add_subdirectory(graphics3d/glad)

endif()



add_subdirectory(user-generation1/redshift)
