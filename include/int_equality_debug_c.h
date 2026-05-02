// Created by camilo on 2026-05-01 19:00 <3ThomasBorregaardSørensen!!
#ifndef INT_EQUALITY_DEBUG_C_H
#define INT_EQUALITY_DEBUG_C_H


#include "int_equality_debug_t.h"


#define INT_EQUALITY_DEBUG_CALL(name, size) \
         int name##_iaInner[size]; \
         int_equality_debug_t name; \
         name.m_piaInner = name##_iaInner; \
         name.m_iOuterCount = size



#define INT_EQUALITY_DEBUG_START() \
   pintequalitydebug->m_iInnerCount = 0; \
   pintequalitydebug->m_iInnerAdded = 0


#define INT_EQUALITY_DEBUG_INNER_INT(number) \
   if(pintequalitydebug->m_iInnerAdded < pintequalitydebug->m_iOuterCount) \
      pintequalitydebug->m_piaInner[pintequalitydebug->m_iInnerAdded++] = (int)(number); \
   pintequalitydebug->m_iInnerCount++


#define INT_EQUALITY_DEBUG_OFFSET(s, member)                   \
   INT_EQUALITY_DEBUG_INNER_INT(offsetof(s, member))



#endif // INT_EQUALITY_DEBUG_C_H



