file(READ "${SOURCE_DIR}/configure" configure_source)
# Keep the upstream source read-only. Only the copied configure script changes.
string(REPLACE "source_path=$(cd $(dirname \"$0\"); pwd)"
    "source_path=$(cd '${SOURCE_DIR}'; pwd)" configure_source "${configure_source}")
string(REPLACE "_WIN32_WINNT < 0x0600" "_WIN32_WINNT < 0x0501" configure_source "${configure_source}")
string(REPLACE "add_\${pfx}cppflags -D_WIN32_WINNT=0x0600"
    "add_\${pfx}cppflags -D_WIN32_WINNT=0x0501" configure_source "${configure_source}")
# BCrypt is unavailable on XP; retain upstream's generic seed fallback.
string(REPLACE "check_lib bcrypt   \"windows.h bcrypt.h\"   BCryptGenRandom      -lbcrypt &&\n    check_cpp_condition bcrypt bcrypt.h \"defined BCRYPT_RNG_ALGORITHM\""
    "disable bcrypt" configure_source "${configure_source}")
file(WRITE "${BINARY_DIR}/configure-xp" "${configure_source}")
get_filename_component(compiler_directory "${CC}" DIRECTORY)
set(arguments
    "--prefix=${INSTALL_DIR}" --target-os=mingw32 --arch=x86 --cpu=i686
    --enable-cross-compile --disable-everything --disable-autodetect
    --disable-programs --disable-doc --disable-network --disable-debug
    --disable-avcodec --disable-avformat --disable-avdevice --disable-avfilter --disable-swscale
    --enable-avutil --enable-swresample --enable-shared --disable-static
    --enable-pthreads --disable-w32threads --disable-os2threads
    "--cc=${CC}" "--ar=${AR}" "--ranlib=${RANLIB}" "--nm=${NM}" "--strip=${STRIP}"
    "--x86asmexe=${compiler_directory}/nasm.exe"
    "--extra-cflags=-D__REACTOS__ -D_WIN32_WINNT=0x0501 -DWINVER=0x0501 -include ${CMAKE_CURRENT_LIST_DIR}/ffmpeg-xp-compat.h"
    --extra-ldflags=-static-libgcc)
set(shell_command "export PATH=\"$(/usr/bin/cygpath -u '${compiler_directory}'):/usr/bin:$PATH\"; cd '${BINARY_DIR}' && exec /usr/bin/bash '${BINARY_DIR}/configure-xp'")
foreach(argument IN LISTS arguments)
    string(APPEND shell_command " '${argument}'")
endforeach()
execute_process(COMMAND "${BASH}" -lc "${shell_command}" RESULT_VARIABLE result)
if(NOT result EQUAL 0)
    message(FATAL_ERROR "FFmpeg XP configuration failed: ${result}")
endif()
