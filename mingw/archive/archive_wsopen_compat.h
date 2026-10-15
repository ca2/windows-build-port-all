#pragma once
#include <errno.h>
#include <io.h>
#include <share.h>
#include <wchar.h>

/* _wsopen is available in the legacy CRT; preserve sharing and errno. */
static int ca2_wsopen_s(int *descriptor, const wchar_t *path,
                      int flags, int sharing, int mode)
{
   if (!descriptor)
   {
      errno = EINVAL;
      return EINVAL;
   }
   *descriptor = -1;
   if (!path)
   {
      errno = EINVAL;
      return EINVAL;
   }
   *descriptor = _wsopen(path, flags, sharing, mode);
   return *descriptor < 0 ? errno : 0;
}
