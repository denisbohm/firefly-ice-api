//
//  FDWeak.h
//  FireflyDevice
//
//  Created by Denis Bohm on 1/17/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#if defined(MAC_OS_X_VERSION_MIN_REQUIRED) && (MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_7)

#define FDWeak unsafe_unretained
#define __FDWeak __unsafe_unretained

#else

#define FDWeak weak
#define __FDWeak __weak

#endif
