/***************************************************************************
 *  Copyright 2017 -   Andrew Wallace                                       *
 *                                                                          *
 *  This program is free software; you can redistribute it and/or modify    *
 *  it under the terms of the GNU General Public License as published by    *
 *  the Free Software Foundation; either version 2 of the License, or       *
 *  (at your option) any later version.                                     *
 *                                                                          *
 *  This program is distributed in the hope that it will be useful,         *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of          *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *
 *  GNU General Public License for more details.                            *
 *                                                                          *
 *  You should have received a copy of the GNU General Public License       *
 *  along with this program; if not, write to the Free Software             *
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA               *
 *  02111-1307, USA.                                                        *
 ***************************************************************************/

#ifndef __DEBUG_H
#define __DEBUG_H 1

// Often it is useful to have lots of logging, but often not by default on
// the device - slows it down a lot.
#ifdef DEBUGLOGGING

#define DEBUG_PRINTF(format, args...) printf(format, ##args)
#define DEBUG_LOG(s, ...)       NSLog(@"<%s:%d> %@", __func__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])
#define DEBUG_LOG_RAW(s, ...)   NSLog(s, ##__VA_ARGS__)

#define DEBUG 1
#define DEBUG_MODE @"debug on"

#define DEBUG_ONLY(X) X

#else

#define DEBUG_PRINTF(format, args...)
#define DEBUG_LOG(format, args...)
#define DEBUG_LOG_RAW(s, ...)

#undef DEBUG
#define DEBUG_MODE @""

#define DEBUG_ONLY(X)

#endif

#define DEBUG_FUNC()   DEBUG_LOG(@"enter")
#define DEBUG_FUNCEX() DEBUG_LOG(@"exit")
#define DEBUG_LOGC(x)  DEBUG_LOG(@"%s: %c", #x, (char)(x))
#define DEBUG_LOGF(x)  DEBUG_LOG(@"%s: %f", #x, (float)(x))
#define DEBUG_LOGLU(x) DEBUG_LOG(@"%s: %lu",#x, (unsigned long)(x))
#define DEBUG_LOGLX(x) DEBUG_LOG(@"%s: %lx",#x, (unsigned long)(x))
#define DEBUG_LOGL(x)  DEBUG_LOG(@"%s: %ld",#x, (long)(x))
#define DEBUG_LOGS(x)  DEBUG_LOG(@"%s: %@", #x, (x))
#define DEBUG_LOGB(x)  DEBUG_LOG(@"%s: %@", #x, ((x)? @"TRUE" : @"FALSE"))
#define DEBUG_LOGO(x)  DEBUG_LOG(@"%s: %@", #x, (x).debugDescription);
#define DEBUG_LOGR(R)  DEBUG_LOG(@"%s: (%f,%f,%f,%f)", #R, (R).origin.x, (R).origin.y, (R).size.width, (R).size.height);
#define DEBUG_LOGRC(R) DEBUG_LOG(@"%s: retainCount %lu)", #R, (unsigned long)(R).retainCount);
#define DEBUG_LOGIP(I) DEBUG_LOG(@"%s: section %d row %d", #I, (int)((I).section), (int)((I).row));


#define ERROR_LOG(s, ...) NSLog(@"**** ERROR **** <%s:%d> %@", __func__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])
#define LOG_NSERROR(error) if (error) ERROR_LOG(@"NSError: %@\n", error.description)

#endif
