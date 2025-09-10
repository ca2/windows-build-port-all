// Created by camilo 2025-07-09 22:10 <3ThomasBorregaardSorensen!!
#pragma once


#ifdef __cplusplus
extern "C" {
#endif

typedef struct _GUID {
    unsigned int Data1;
    unsigned short Data2;
    unsigned short Data3;
    unsigned char  Data4[8];
} GUID;

#ifdef INITGUID

#define DEFINE_GUID(name, l, w1, w2, b1,b2,b3,b4,b5,b6,b7,b8) \
    const GUID name = { l, w1, w2, { b1,b2,b3,b4,b5,b6,b7,b8 } }

#else

#define DEFINE_GUID(name, l, w1, w2, b1,b2,b3,b4,b5,b6,b7,b8) \
    extern const GUID name

#endif


static inline int IsEqualGUID(const GUID* a, const GUID* b)
{
   return (a->Data1 == b->Data1) &&
          (a->Data2 == b->Data2) &&
          (a->Data3 == b->Data3) &&
          (a->Data4[0] == b->Data4[0]) &&
          (a->Data4[1] == b->Data4[1]) &&
          (a->Data4[2] == b->Data4[2]) &&
          (a->Data4[3] == b->Data4[3]) &&
          (a->Data4[4] == b->Data4[4]) &&
          (a->Data4[5] == b->Data4[5]) &&
          (a->Data4[6] == b->Data4[6]) &&
          (a->Data4[7] == b->Data4[7]);
}




#ifdef __cplusplus
}
#endif


#ifdef __cplusplus
static inline int IsEqualGUID(const GUID & a, const GUID& b)
{
   return IsEqualGUID(&a, &b);
}

bool operator ==(const GUID & a, const GUID& b)
{
   return IsEqualGUID(a, b);
}

#endif