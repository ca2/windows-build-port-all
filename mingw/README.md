# MinGW port libraries

In CLion, select the 32-bit MinGW GCC profile and build `port_all` before
building application targets such as `release_all`. Ports are excluded from
the default build and applications do not build them automatically.

The profile's configuration selects the output directory:

```
../operating_system/storage-windows/Win32/Debug/
../operating_system/storage-windows/Win32/Release/
```

Each configuration contains `binary` (DLLs), `library` (MinGW `.dll.a` import
libraries), and `include` (public headers). `PORT_STORAGE_ROOT` can override
the directory above the configuration folders.

Currently `port_all` builds zlib and libarchive. Libarchive supports zlib
compression; optional compression, XML, iconv, and crypto dependencies are
disabled. Windows CNG is disabled to avoid requiring `bcrypt.dll` on XP.

Port compilation uses separate build directories and at most four compiler
jobs. Building `port_all` again performs incremental builds and reinstalls
changed outputs. Visual Studio's `port.sln` workflow remains separate.
