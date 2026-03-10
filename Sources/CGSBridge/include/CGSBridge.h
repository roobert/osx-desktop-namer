#ifndef CGSBridge_h
#define CGSBridge_h

#include <CoreGraphics/CoreGraphics.h>

// Private CoreGraphics/SkyLight types
typedef int CGSConnectionID;
typedef uint64_t CGSSpaceID;

typedef enum {
    CGSSpaceIncludesCurrent = 1 << 0,
    CGSSpaceIncludesOthers  = 1 << 1,
    CGSSpaceIncludesUser    = 1 << 2,
    kCGSAllSpacesMask       = CGSSpaceIncludesUser | CGSSpaceIncludesOthers | CGSSpaceIncludesCurrent,
} CGSSpaceMask;

// Private API declarations
extern CGSConnectionID CGSMainConnectionID(void);
extern CGSSpaceID CGSGetActiveSpace(CGSConnectionID cid);
extern CFArrayRef CGSCopySpaces(CGSConnectionID cid, int mask) CF_RETURNS_RETAINED;
extern CFArrayRef CGSCopyManagedDisplaySpaces(CGSConnectionID cid) CF_RETURNS_RETAINED;

#endif /* CGSBridge_h */
