/* XP-compatible replacement for libarchive's Windows random-number helper. */
#define __LIBARCHIVE_BUILD 1
#include <windows.h>
#include <wincrypt.h>
#include <errno.h>
#include <archive.h>
#include "archive_random_private.h"

int archive_random(void *buffer, size_t count)
{
    HCRYPTPROV provider = 0;
    unsigned char *bytes = buffer;
    if (!CryptAcquireContextW(&provider, NULL, NULL, PROV_RSA_FULL,
            CRYPT_VERIFYCONTEXT | CRYPT_SILENT))
    {
        errno = EIO;
        return ARCHIVE_FAILED;
    }
    while (count)
    {
        DWORD chunk = count > 0x01000000UL ? 0x01000000UL : (DWORD)count;
        if (!CryptGenRandom(provider, chunk, bytes))
        {
            CryptReleaseContext(provider, 0);
            errno = EIO;
            return ARCHIVE_FAILED;
        }
        bytes += chunk;
        count -= chunk;
    }
    CryptReleaseContext(provider, 0);
    return ARCHIVE_OK;
}
