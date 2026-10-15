# Port builds

For the Debug-MinGW ReactOS profile, build `port_all` in CLion or run:

```
cmake --build cmake-build-debug-mingw-reactos --target port_all
```

The target uses the original cpp-port CMake projects directly. Component
targets include `iconv`, `idn`, `zlib`, `archive`, `unac`, `sqlite`, `pcre`,
`png`, `freetype`, `pixman`, and `cairo`. The existing `port_pcre`, `port_idn`,
`port_zlib`, `port_archive`, `port_unac`, `port_sqlite`, and `port_graphics`
convenience targets remain available.

DLLs and import libraries are built directly into
`../operating_system/storage-windows/Win32/<configuration>/third/binary`
and `third/library`. `port_all` also copies public/generated headers into
`third/include`. `PORT_STORAGE_ROOT` overrides the directory above the
configuration folders.

`port_all` also stages the port DLLs beside development executables in the
build's `output` directory. Individual `port_runtime_<component>` targets
restore missing or stale runtime copies without rebuilding unchanged libraries.
The PCRE2 wrapper depends on `port_runtime_pcre` because its DLL imports
`pcre.dll`, which must be discoverable by the native loader.

Applications link the real port targets, so CMake builds and updates their
required port libraries automatically. There are no separate ExternalProject
configure/build/install steps. Unrelated port libraries remain excluded from
the default build; `port_all` explicitly builds the complete set.

ReactOS/XP configuration is guarded by `__REACTOS__` in each original CMake
project. Compiler-specific flags use compiler guards. The existing regular
Windows/MSVC project paths remain separate. Archive compatibility sources
belong to its outer cpp-port wrapper; its inner third-party repository is
unchanged.

PCRE2 provides the 8-bit Unicode library as `pcre.dll` (JIT disabled). Cairo
supports image/PNG, PDF, PS, SVG, FreeType and Win32 rendering; ReactOS disables
GL/WGL and Pixman CPU-specific optimized paths. Archive uses zlib compression
and the legacy Windows cryptographic API instead of CNG.
