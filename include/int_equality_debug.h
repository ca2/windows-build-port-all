// Created by camilo on 2026-05-01 19:10 <3ThomasBorregaardSørensen!!
#ifndef INT_EQUALITY_DEBUG_THOMAS_BORREGAARD_SØRENSEN_H
#define INT_EQUALITY_DEBUG_THOMAS_BORREGAARD_SØRENSEN_H

#include "int_equality_debug_t.h"

class int_equality_debug :
   public int_equality_debug_t
{
public:
   ::array_base < const_char_pointer > m_szaDescription;
   int_array m_iaOuter;
   int_array m_iaInner;

   void add_outer_item(int iOuter, const char * psz)
   {
      m_iaOuter.add(iOuter);
      m_szaDescription.add(psz);
      m_iaInner.add(0);
   }

   int_equality_debug_t * inner()
   {

      m_iInnerAdded = 0;
      m_piaInner = m_iaInner.data();
      m_iInnerCount = 0;
      m_iOuterCount = m_iaOuter.size();

      return this;

   }


   void trace()
   {

      information("outer inner status");
      const char * szOk =                "✅    ";
      const char * sznok =               "❌    ";
      ::string strLine;
      int iInspect = 0;
      if (m_iInnerCount != m_iaOuter.size())
      {
         strLine.formatf("outer count(%d) and inner count(%d) doesn't match", m_iaOuter.size(), m_iInnerCount);
         information(strLine);
         print_line(strLine);
      }

      for (; iInspect < m_iaOuter.size(); iInspect++)
      {
         auto szDescription = m_szaDescription[iInspect];
         if (!szDescription)
         {

            break;

         }
         auto iOuter = m_iaOuter[iInspect];
         auto iInner = m_iaInner[iInspect];
         auto iDiff = iInner - iOuter;
         auto bOk = iDiff == 0;
         auto status = bOk ? szOk : sznok;
         strLine.formatf("%4d %4d %4d %s %s", iOuter, iInner, iDiff, status, szDescription);
         information(strLine);
         print_line(strLine);
         //information("progressive_mode(offset)   {}, {}", offsetof(jpeg_compress_struct, progressive_mode), keyoffset[0]);
      }
      //m_iInspectCount = iInspect;

   }
};


#ifdef INT_EQUALITY_DEBUG_INNER
#undef INT_EQUALITY_DEBUG_INNER
#endif

#ifdef INT_EQUALITY_DEBUG_START
#undef INT_EQUALITY_DEBUG_START
#endif

#ifdef INT_EQUALITY_DEBUG_INNER_INT
#undef INT_EQUALITY_DEBUG_INNER_INT
#endif

#ifdef INT_EQUALITY_DEBUG_OFFSET
#undef INT_EQUALITY_DEBUG_OFFSET
#endif

#define INT_EQUALITY_DEBUG_INNER intequalitydebug.inner()

#define INT_EQUALITY_DEBUG_START() \
   int_equality_debug intequalitydebug;

#define INT_EQUALITY_DEBUG_INNER_INT(i) \
intequalitydebug.add_outer_item((int) (i), #i)

#define INT_EQUALITY_DEBUG_OFFSET(s, name) \
intequalitydebug.add_outer_item((int)offsetof(s, name), "offsetof(" #s ", " #name ")")

#define INT_EQUALITY_DEBUG_TRACE() intequalitydebug.trace()

#endif // INT_EQUALITY_DEBUG_THOMAS_BORREGAARD_SØRENSEN_H



