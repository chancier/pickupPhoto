//
//  UserEditAlbumManager.h
//  Huihui
//
//  Created by Wudi_Mac on 2018/1/22.
//  Copyright © 2018年 User. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GMGridView.h"
#import "UserAuthenDetaiEditViewController.h"

@interface UserAuthenEditAlbumManager : NSObject

@property (nonatomic, strong) GMGridView *gridView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, assign)BOOL haveEditPhtoAlbum;
@property (nonatomic, strong) UserAuthenDetaiEditViewController *contentVC;

- (void)initData;

@end
