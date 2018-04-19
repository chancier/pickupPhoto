//
//  GMGridView+LongPress.h
//  LiaoBa
//
//  Created by apple on 9/1/14.
//  Copyright (c) 2014 User. All rights reserved.
//

#import "GMGridView.h"

@protocol GMGridViewLongPressDelegate;

@interface GMGridView (LongPress)

@property (nonatomic, weak) id<GMGridViewLongPressDelegate> longPressActionDelegate;
@end

@protocol GMGridViewLongPressDelegate
@optional
-(void) longPressActionAtPosition:(NSInteger) position;
-(void) longPressActionEnd;
@end