//
//  GMGridView+LongPress.m
//  LiaoBa
//
//  Created by apple on 9/1/14.
//  Copyright (c) 2014 User. All rights reserved.
//

#import <objc/runtime.h>
#import "GMGridView+LongPress.h"

static void * longPressActionDelegateKey = (void *)@"longPressActionDelegateKey";
@implementation GMGridView (LongPress)

- (id <GMGridViewLongPressDelegate>)longPressActionDelegate {
    return objc_getAssociatedObject(self, longPressActionDelegateKey);
}

- (void)setLongPressActionDelegate:(id <GMGridViewLongPressDelegate>)longPressActionDelegate {
    objc_setAssociatedObject(self, longPressActionDelegateKey, longPressActionDelegate, OBJC_ASSOCIATION_ASSIGN);
}

@end
