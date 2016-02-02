//
//  ExceptionCatcher.h
//  Mobile
//
//  Created by Logan Murray on 2016-02-01.
//  Copyright © 2016 The Little Software Company. All rights reserved.
//

#ifndef ExceptionCatcher_h
#define ExceptionCatcher_h

#import <Foundation/Foundation.h>

NS_INLINE NSException * _Nullable tryBlock(void(^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}

#endif /* ExceptionCatcher_h */
