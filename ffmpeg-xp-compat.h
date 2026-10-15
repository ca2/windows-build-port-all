#pragma once

#if defined(__REACTOS__)
#include <windows.h>

#ifndef WC_ERR_INVALID_CHARS
#define WC_ERR_INVALID_CHARS 0x80
#endif

/* XP lacks WC_ERR_INVALID_CHARS. Preserve strict UTF-16 validation before
 * calling the legacy API with the unsupported flag removed. */
static inline int ca2_ffmpeg_WideCharToMultiByte(UINT code_page, DWORD flags,
    LPCWCH text, int length, LPSTR output, int output_size,
    LPCCH default_char, LPBOOL used_default)
{
    if (code_page == CP_UTF8 && (flags & WC_ERR_INVALID_CHARS))
    {
        if (text && (length > 0 || length == -1))
        {
            int i;
            for (i = 0; length == -1 ? text[i] != 0 : i < length; ++i)
            {
                unsigned int ch = text[i];
                if (ch >= 0xd800 && ch <= 0xdbff)
                {
                    if ((length != -1 && i + 1 >= length)
                        || text[i + 1] < 0xdc00 || text[i + 1] > 0xdfff)
                    {
                        SetLastError(ERROR_NO_UNICODE_TRANSLATION);
                        return 0;
                    }
                    ++i;
                }
                else if (ch >= 0xdc00 && ch <= 0xdfff)
                {
                    SetLastError(ERROR_NO_UNICODE_TRANSLATION);
                    return 0;
                }
            }
        }
        flags &= ~WC_ERR_INVALID_CHARS;
    }
    return WideCharToMultiByte(code_page, flags, text, length, output,
        output_size, default_char, used_default);
}
#define WideCharToMultiByte ca2_ffmpeg_WideCharToMultiByte
#endif
