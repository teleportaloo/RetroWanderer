/*  Copyright 2017 -   Andrew Wallace  */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef __DEBUG_H
#define __DEBUG_H 1

// Often it is useful to have lots of logging, but often not by default on
// the device - slows it down a lot.
#ifdef DEBUGLOGGING

#define DEBUG_PRINTF(format, args ...) printf(format, ## args)
#define DEBUG_LOG(s, ...)              NSLog(@"<%s:%d> %@", __func__, __LINE__, [NSString stringWithFormat:(s), ## __VA_ARGS__])
#define DEBUG_LOG_RAW(s, ...)          NSLog(s, ## __VA_ARGS__)

#define DEBUG      1
#define DEBUG_MODE @"debug on"

#define DEBUG_ONLY(X)                  X
#define DEBUG_ASSERT(X, s, ...)        if (!(X)) { DEBUG_LOG(@"Assertion failed"); DEBUG_LOG(s, ## __VA_ARGS__);  raise(SIGINT); }

#else

#define DEBUG_PRINTF(format, args ...)
#define DEBUG_LOG(format, args ...)
#define DEBUG_LOG_RAW(s, ...)

#undef DEBUG
#define DEBUG_MODE @""

#define DEBUG_ONLY(X)
#define DEBUG_ASSERT(X, s, ...)

#endif // ifdef DEBUGLOGGING

#define DEBUG_FUNC()       DEBUG_LOG(@"enter")
#define DEBUG_FUNCEX()     DEBUG_LOG(@"exit")
#define DEBUG_LOGC(x)      DEBUG_LOG(@"%s: %c", #x, (char)(x))
#define DEBUG_LOGF(x)      DEBUG_LOG(@"%s: %f", #x, (float)(x))
#define DEBUG_LOGLU(x)     DEBUG_LOG(@"%s: %lu",#x, (unsigned long)(x))
#define DEBUG_LOGLX(x)     DEBUG_LOG(@"%s: %lx",#x, (unsigned long)(x))
#define DEBUG_LOGL(x)      DEBUG_LOG(@"%s: %ld",#x, (long)(x))
#define DEBUG_LOGS(x)      DEBUG_LOG(@"%s: %@", #x, (x))
#define DEBUG_LOGB(x)      DEBUG_LOG(@"%s: %@", #x, ((x) ? @"TRUE" : @"FALSE"))
#define DEBUG_LOGO(x)      DEBUG_LOG(@"%s: %@", #x, (x).debugDescription);
#define DEBUG_LOGR(R)      DEBUG_LOG(@"%s: (%f,%f,%f,%f)", #R, (R).origin.x, (R).origin.y, (R).size.width, (R).size.height);
#define DEBUG_LOGRC(R)     DEBUG_LOG(@"%s: retainCount %lu)", #R, (unsigned long)(R).retainCount);
#define DEBUG_LOGIP(I)     DEBUG_LOG(@"%s: section %d row %d", #I, (int)((I).section), (int)((I).row));


#define ERROR_LOG(s, ...)  NSLog(@"**** ERROR **** <%s:%d> %@", __func__, __LINE__, [NSString stringWithFormat:(s), ## __VA_ARGS__])
#define LOG_NSERROR(error) if (error) ERROR_LOG(@"NSError: %@\n", error.description)

#endif // ifndef __DEBUG_H
