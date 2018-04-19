//
//  UserEditAlbumManager.m
//  Huihui
//
//  Created by Wudi_Mac on 2018/1/22.
//  Copyright © 2018年 User. All rights reserved.
//

#import "UserEditAlbumManager.h"
#import "PhotoAlbumBL.h"
#import "ThumbnailGridViewCell.h"
#import "GMGridView+LongPress.h"
#import "MSPhotoAlbumBigPictureController.h"
#import "MSSecretaryAlertView.h"
#import "HXPhotoViewController.h"
#import "NSString+UUID.h"

#define PhotoEditSheetActionTag 666666
#define PhotoActionSheetTag 55555

@interface UserEditAlbumManager () <GMGridViewDataSource, GMGridViewSortingDelegate, GMGridViewActionDelegate,GMGridViewLongPressDelegate,UIActionSheetDelegate,MSSecretaryAlertViewDelegate,HXPhotoViewControllerDelegate>{
    
    NSInteger _lastDeleteItemIndexAsked;
    NSInteger _lastTapItemIndexAsked;
    
    
    
    BOOL _haveMovedPhotoAlbum;
    NSInteger _longPressStartPoint;
    
    NSMutableArray *_currentData;//照片数组
    
    
    MSPhotoAlbumBigPictureController *_photoAlbumBigPictureController;
    MSSecretaryAlertView *_currentMSAlertView;
    
    NSInteger _repleaceIndex;
}

@property (nonatomic, strong) PhotoAlbumBL *photoAlbumBL;

@property (nonatomic, strong) HXPhotoManager *manager;

@end

@implementation UserEditAlbumManager


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)initUI
{
    CGFloat with = (UI_SCREEN_WIDTH - 25.0)/4.0;
    GMGridView *gmGridView = [[GMGridView alloc] initWithFrame:CGRectMake(0, 0, UI_SCREEN_WIDTH, with+10)];
    gmGridView.minimumPressDuration = 0.1;
    gmGridView.contentSize = CGSizeMake(UI_SCREEN_WIDTH, gmGridView.frame.size.height);
    gmGridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    gmGridView.backgroundColor = [UIColor whiteColor];
    gmGridView.scrollEnabled = NO;
    self.gridView = gmGridView;
    self.gridView.style = GMGridViewStyleSwap;
    self.gridView.itemSpacing = 4;
    self.gridView.centerGrid = NO;
    self.gridView.actionDelegate = self;  //点击
    
    self.gridView.sortingDelegate = self;
    self.gridView.longPressActionDelegate = self;
    self.gridView.dataSource = self;
    self.gridView.mainSuperView = self.contentView;
    self.gridView.contentInset = UIEdgeInsetsZero;
    _repleaceIndex = -1;
}

- (void)initData
{
    //获取相册数据
    WeakSelf(self);
    NSArray *tempArray = [self.photoAlbumBL getUserPhotoAlbumByUserId:self.userId limit:100 offset:0 block:^(NSMutableArray *data, NSError *error, NSInteger count) {
        if (error.code == 0 && data) {
            @synchronized(weakself.dataSource)
            {
                [weakself.dataSource removeAllObjects];
                [weakself.dataSource addObjectsFromArray:data];
                _currentData = weakself.dataSource;
                if (weakself.dataSource.count < 8) {
                    PhotoAlbumEntity *addBtn = [[PhotoAlbumEntity alloc]init];
                    addBtn.thumbnailUrl = @"my_add_img_icon";
                    addBtn.photoId = -1;
                    [self.dataSource addObject:addBtn];
                
                }
                
                if (self.dataSource.count > 4) {
                    CGFloat with = (UI_SCREEN_WIDTH - 25.0)/4.0;
                    weakself.gridView.frame = CGRectMake(0, 0, UI_SCREEN_WIDTH, with+10 + with+5);
                    weakself.gridView.contentSize = CGSizeMake(UI_SCREEN_WIDTH, weakself.gridView.frame.size.height);
                    [weakself.contentVC resetHeadView];
                }
            }
            [weakself.gridView reloadData];
        }
    }];
    
    if ([tempArray count]) {
        @synchronized(self.dataSource)
        {
            [self.dataSource removeAllObjects];
            [self.dataSource addObjectsFromArray:tempArray];
            
            if (self.dataSource.count < 8) {
                PhotoAlbumEntity *addBtn = [[PhotoAlbumEntity alloc]init];
                addBtn.thumbnailUrl = @"my_add_img_icon";
                addBtn.photoId = -1;
                [self.dataSource addObject:addBtn];
            }
            
            if (self.dataSource.count > 4) {
                CGFloat with = (UI_SCREEN_WIDTH - 25.0)/4.0;
                self.gridView.frame = CGRectMake(0, 0, UI_SCREEN_WIDTH, with+10 + with+5);
                self.gridView.contentSize = CGSizeMake(UI_SCREEN_WIDTH, weakself.gridView.frame.size.height);
                [self.contentVC resetHeadView];
            }
            _currentData = self.dataSource;
        }
        [self.gridView reloadData];
    }
}

#pragma mark GMGridViewDataSource
- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView {
    
    return [self.dataSource count];
}

- (CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation {
    
    CGFloat with = (UI_SCREEN_WIDTH - 25.0)/4.0;
    return CGSizeMake(with, with);
//    if (UI_SCREEN_WIDTH == 375) {
//        return CGSizeMake(82.0, 82.0);
//    }else if (UI_SCREEN_WIDTH == 414){
//        return CGSizeMake(92.0, 92.0);
//    }else{
//        return CGSizeMake(68.0, 68.0);
//    }
}

- (GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index {
    
    CGFloat with = (UI_SCREEN_WIDTH - 25.0)/4.0;
//    CGSize size = [self GMGridView:gridView sizeForItemsInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    CGSize size = CGSizeMake(with, with);
    static NSString *thumnailNormalIdentifier = @"thumnailNormalIdentifier";
    ThumbnailGridViewCell *cell = nil;
    cell = (ThumbnailGridViewCell *) [gridView dequeueReusableCellWithIdentifier:thumnailNormalIdentifier];
    
//    if (!cell)
    {
        cell = [[ThumbnailGridViewCell alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        cell.reuseIdentifier = thumnailNormalIdentifier;
    }
    
    PhotoAlbumEntity *entity = [self.dataSource objectAtIndex:index];
    if (entity.photoId == -1) {
        cell.disable = YES;
    }else{
        cell.disable = NO;
    }
    
    [cell setGridViewCellByEntity:entity isLoginUser:YES];
    
    return cell;
}


- (BOOL)GMGridView:(GMGridView *)gridView canDeleteItemAtIndex:(NSInteger)index {
    PhotoAlbumEntity *entity = [self.dataSource objectAtIndex:index];
    if (entity.photoId == -1) {
        return NO;
    }
    
    if ([self realEntity] < 1) {
        return NO;
    }
    
    return YES;
}

#pragma mark GMGridViewActionDelegate
- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position {
    _lastTapItemIndexAsked = position;
    
    [self didTapItemActionAlIndex:position];
    
}


- (void)GMGridViewDidTapOnEmptySpace:(GMGridView *)gridView {
    
}

- (void)GMGridView:(GMGridView *)gridView processDeleteActionForItemAtIndex:(NSInteger)index {
    
    _lastDeleteItemIndexAsked = index;
//    if (index == 0) {//第一张不能删除
//        return;
//    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"删除照片" message:@"您确定要删除这张照片" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"删除", nil];

    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        
        if(_lastDeleteItemIndexAsked >=_currentData.count)return;
        [SVProgressHUD showWithStatus:@"正在删除" maskType:SVProgressHUDMaskTypeBlack];
        PhotoAlbumEntity *entity = [_currentData objectAtIndex:_lastDeleteItemIndexAsked];
        WeakSelf(self);
        [_photoAlbumBL deletePhotoAlbumById:entity.photoId block:^(NSError *error) {
            [SVProgressHUD dismiss];
            if (error.code == 0) {
                
//                [SVProgressHUD showSuccessWithStatus:@"删除成功"];
                [_currentData removeObjectAtIndex:_lastDeleteItemIndexAsked];
                [weakself.gridView removeObjectAtIndex:_lastDeleteItemIndexAsked withAnimation:GMGridViewItemAnimationFade];

                _haveEditPhtoAlbum = YES;
                BOOL hasAdd = NO;
                for(PhotoAlbumEntity *myEntity  in _currentData){
                    if (myEntity.photoId == -1) {
                        hasAdd = YES;
                        break;
                    }
                }
                if (!hasAdd) {//没有+按钮就添加
                    PhotoAlbumEntity *addBtn = [[PhotoAlbumEntity alloc]init];
                    addBtn.thumbnailUrl = @"my_add_img_icon";
                    addBtn.photoId = -1;
                    [self.dataSource addObject:addBtn];
                }
                CGFloat with = (UI_SCREEN_WIDTH - 25.0)/4.0;
                if (weakself.dataSource.count > 4) {
                    weakself.gridView.frame = CGRectMake(0, 0, UI_SCREEN_WIDTH, with+10 + with+5);
                    weakself.gridView.contentSize = CGSizeMake(UI_SCREEN_WIDTH, self.gridView.frame.size.height);
                    [weakself.contentVC resetHeadView];
                }else{
                    weakself.gridView.frame = CGRectMake(0, 0, UI_SCREEN_WIDTH, with+10);
                    weakself.gridView.contentSize = CGSizeMake(UI_SCREEN_WIDTH, self.gridView.frame.size.height);
                    [weakself.contentVC resetHeadView];
                }
                [self.gridView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
                if([_currentData count] <=0) {
                    // self.navigationItem.rightBarButtonItem = nil;
                    //[self.navigationItem setRightBarButtonItems:nil animated:YES];
                    //[self.navigationItem setRightBarButtonItem:nil];
                    [weakself.gridView setEditing:NO];
                }
            } else {
                [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
            }
        }];
    }
}

#pragma mark GMGridViewSortingDelegate
- (void)GMGridView:(GMGridView *)gridView didStartMovingCell:(GMGridViewCell *)cell {
    self.contentVC.baseInfoTableView.scrollEnabled = NO;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         cell.contentView.layer.shadowOpacity = 0.7;
                         ThumbnailGridViewCell *thumbCell = (ThumbnailGridViewCell *) cell;
                         thumbCell.imageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                     }
                     completion:nil
     ];
}

- (void)GMGridView:(GMGridView *)gridView didEndMovingCell:(GMGridViewCell *)cell {
    self.contentVC.baseInfoTableView.scrollEnabled = YES;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         cell.contentView.layer.shadowOpacity = 0;
                         ThumbnailGridViewCell *thumbCell = (ThumbnailGridViewCell *) cell;
                         thumbCell.imageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                     }
                     completion:nil
     ];
}

- (BOOL)GMGridView:(GMGridView *)gridView shouldAllowShakingBehaviorWhenMovingCell:(GMGridViewCell *)cell atIndex:(NSInteger)index {
    PhotoAlbumEntity *entity = [self.dataSource objectAtIndex:index];
    if (entity.photoId == -1) {
        return NO;
    }
    return YES;
}

- (BOOL)GMGridView:(GMGridView *)gridView allowMoveAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex {
    if (newIndex == [self.dataSource count] - 1) {
        return NO;
    }
    PhotoAlbumEntity *entity = [self.dataSource objectAtIndex:oldIndex];
    if (entity.photoId == -1) {
        return NO;
    }
    return YES;
}


- (void)GMGridView:(GMGridView *)gridView moveItemAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex {
    NSObject *object = [_currentData objectAtIndex:oldIndex];
    [_currentData removeObject:object];
    [_currentData insertObject:object atIndex:newIndex];

    _haveEditPhtoAlbum = YES;
    _haveMovedPhotoAlbum = YES;
}

- (void)GMGridView:(GMGridView *)gridView exchangeItemAtIndex:(NSInteger)index1 withItemAtIndex:(NSInteger)index2 {
    [_currentData exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
    PhotoAlbumEntity *entityOne = [_currentData objectAtIndex:index1];
    PhotoAlbumEntity *entityTwo = [_currentData objectAtIndex:index2];
    NSInteger tempSortId = entityOne.sortId;
    entityOne.sortId = entityTwo.sortId;
    entityTwo.sortId = tempSortId;

    _haveEditPhtoAlbum = YES;
    _haveMovedPhotoAlbum = YES;
}

#pragma mark GMGridViewLongPressDelegate

- (void)longPressActionAtPosition:(NSInteger)position {
    
    _longPressStartPoint = position;
}

- (void)longPressActionEnd {
    
    //不响应长按事件
    return ;
    //长安事件结束
//    _haveMovedPhotoAlbum = NO;
//
//    _lastTapItemIndexAsked = _longPressStartPoint;
//
//    PhotoAlbumEntity *entity = [self.dataSource objectAtIndex:_lastTapItemIndexAsked];
//    if (entity.photoId == -1) {
//        return ;
//    }
//
//    if ([self realEntity] < 1) {
////        [SVProgressHUD showImage:nil status:[NSString stringWithFormat:@"最少保留%@张照片",@"1"]];
//        return ;
//    }
//
//    [self userLookUpSelfPhoto];
}

- (void)userLookUpSelfPhoto {
    
    UIActionSheet *actionSheet = nil;
    //    if(self.gender == GenderFemale)
    //    {
    //        PhotoAlbumEntity * entity =[_currentData objectAtIndex:_lastTapItemIndexAsked];
    //        if(entity.photoState == PhotoStateLocked || entity.photoState == PhotoStateCheck)
    //        {
    //            actionSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"取消私照",@"查看大图", @"删除照片",nil] autorelease];
    //        }else if(entity.photoState == PhotoStateNormal){
    //            actionSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"设为私照",@"查看大图", @"删除照片",nil] autorelease];
    //        }
    //    }else if(self.gender == GenderMale)
    //    {
    
    NSString *deletString = @"删除照片";
    if (_lastTapItemIndexAsked == 0) {
//        deletString = nil;
    }
    
    if ([self realEntity] < 1) {
        deletString = nil;
    }
    
    actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"查看大图", deletString,nil];
    //    }
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
//    if (deletString) {
//        actionSheet.destructiveButtonIndex = 2;
//    }else{
//        actionSheet.destructiveButtonIndex = 1;
//    }
    actionSheet.destructiveButtonIndex = 1;
    actionSheet.tag = PhotoEditSheetActionTag;
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString * title =[actionSheet buttonTitleAtIndex:buttonIndex];
    if (actionSheet.tag == PhotoActionSheetTag) {
        [self photoActionSheet:title];
    } else if (actionSheet.tag == PhotoEditSheetActionTag) {
        
        [self photoEditActionSheet:title];
    }
}
- (void)photoActionSheet:(NSString * )buttonTitle{
    
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet{
    
}

- (void)photoEditActionSheet:(NSString * )title {
    if ([title isEqualToString:@"查看大图"]) {
        [self showBigPictureAction];//查看大图
    } else if ([title isEqualToString:@"删除照片"]) {
        //删除照片
        [self GMGridView:self.gridView processDeleteActionForItemAtIndex:_lastTapItemIndexAsked];
    }else if([title isEqualToString:@"设为私照"]||[title isEqualToString:@"取消私照"])
    {
        PhotoAlbumEntity * entity =[_currentData objectAtIndex:_lastTapItemIndexAsked];
        NSInteger privateKey = -1;
        NSString * tipTittle = nil;
        if(entity.photoState == PhotoStateCheck || entity.photoState == PhotoStateLocked)
        {
            privateKey = 0;
            tipTittle = @"正在取消私照...";
        }else if(entity.photoState == PhotoStateNormal)
        {
            privateKey = 1;
            tipTittle = @"正在设为私照...";
        }
        
        [SVProgressHUD showWithStatus:tipTittle];
        [_photoAlbumBL editPhotoAlbumSetPrivate:privateKey photoId:entity.photoId block:^(NSError *error, PhotoState photostate, NSString *price) {
            if(error.code == 0)
            {
                [SVProgressHUD dismiss];
                entity.photoState = photostate;
                entity.unlockGold = price;
                [self.gridView reloadData];
            }else
            {
                [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
            }
        }];
    }else if ([title isEqualToString:@"替换"]) {
        _repleaceIndex = _lastTapItemIndexAsked;
        [self selectPhoto];
    }
}


- (void)didTapItemActionAlIndex:(NSInteger)position {
    
    _haveMovedPhotoAlbum = NO;
    
    PhotoAlbumEntity *entity = [self.dataSource objectAtIndex:_lastTapItemIndexAsked];
    if (entity.photoId == -1) {
        [self selectPhoto];
        return ;
    }
    
    if ([self realEntity] < 1) {
        return ;
    }
    
    [self userLookUpSelfPhoto];
    
//    PhotoAlbumEntity *entity = [self.dataSource objectAtIndex:position];
//    [self showBigPictureAction];//显示大图
}

- (void)showBigPictureAction {
    
    NSMutableArray *tempDataArray = [NSMutableArray array];
    for(PhotoAlbumEntity *entity in  _currentData){//过滤虚拟相册
        if (entity.photoId > 0) {
            [tempDataArray addObject:entity];
        }
    }
    
    NSInteger clickIndex = _lastTapItemIndexAsked;
    if (_photoAlbumBigPictureController == nil) {
        _photoAlbumBigPictureController = [[MSPhotoAlbumBigPictureController alloc] init];
    }
    _photoAlbumBigPictureController.isFromThumnail = YES;
    _photoAlbumBigPictureController.showRightThumAction = YES;

    [_photoAlbumBigPictureController setPhotoDataArray:tempDataArray userId:_userId];
    _photoAlbumBigPictureController.selectedPhotoIndex = clickIndex;
    _photoAlbumBigPictureController.orginalClickIndex = clickIndex;

    ThumbnailGridViewCell * cell = (ThumbnailGridViewCell *)[self.gridView cellForItemAtIndex:clickIndex];
    UIImageView * tempImageView = [[UIImageView alloc] initWithImage:cell.imageView.image];
    tempImageView.contentMode = cell.imageView.contentMode;
    tempImageView.contentScaleFactor = cell.imageView.contentScaleFactor;
    tempImageView.layer.masksToBounds = cell.imageView.layer.masksToBounds;
    tempImageView.layer.cornerRadius = cell.imageView.layer.cornerRadius;
    tempImageView.clipsToBounds = cell.imageView.clipsToBounds;
    tempImageView.frame = [cell.contentView convertRect:cell.imageView.frame toView:getCurrentViewController().view];
    _photoAlbumBigPictureController.presentingFromImageView = tempImageView;
    [_photoAlbumBigPictureController presentMHGalleryControllerByController:getCurrentViewController() animated:YES completion:nil];
}

#pragma mark---
#pragma mark----选照片
- (void)selectPhoto{
    if (![AppDelegate g_isNetWorkAvailable]) {
        [SVProgressHUD showErrorWithStatus:@"网络异常，请检查网络"];
        return;
    }
    
    [self showAlertViewForUpLoadCommonPhoto];//显示涉黄提示框
}

- (void)showAlertViewForUpLoadCommonPhoto{
//    if (![[UserInfoManager sharedInstance] getCommonPhotoUpLoadNotShowAlert]) {
//        UserBaseInfoEntity *baseinfo = [[UserInfoList sharedInstance] getUserBaseInfoByUserId:@"8000"];//获取小陌头像
//        UIImage * imgOne =[UIImage imageNamed:@"ms_hint_options_n.png"];
//        NSString *msg = @"注意：照片请勿作假、涉黄，如被举报并核实，系统会自动禁用图片功能，严重者冻结账号。";
//        NSRange range;
//        range.location = 0;
//        range.length = 0;
//        NSString *otherTitle = [NSString stringWithFormat:@"下次不再提醒"];
//
//        MSSecretaryAlertView * alertView =[[MSSecretaryAlertView alloc] initWithTitle:TEXT_SECRETARY message:msg delegate:self cancelButtonTitle:@"我知道啦" otherButtonTitles:@[otherTitle] otherButtonImages:@[imgOne]];
//        [alertView setLabelText:msg keyWordRange:range];
//        [alertView setBigHeadImageUrl:baseinfo.avatar];
//        _currentMSAlertView = alertView;//这行必须保持
//        [alertView show];
//
//    }else{
        //上传头像
        [self uploadAvartar];
//    }
}

#pragma mark - MSSecretaryAlertViewDelegate

- (void)msSecretaryAlertView:(MSSecretaryAlertView *)alertView checkBoxIsSelected:(BOOL)isSelected clickedButtonAtIndex:(NSInteger)buttonIndex{
    _currentMSAlertView = nil;
    NSString *msg = alertView.message;
    if ([msg hasPrefix:@"注意：照片请勿作假"]){
        [[UserInfoManager sharedInstance] setCommonPhotoUpLoadNotShowAlert:isSelected];
        
        //上传头像
        [self uploadAvartar];
    }
}

- (void)uploadAvartar
{
    
    WeakSelf(self);
    [MSDeviceAuthority requestPhotoAuthorization:^{
        HXPhotoViewController *vc = [[HXPhotoViewController alloc] init];
        vc.manager = weakself.manager;
        vc.delegate = weakself;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [getCurrentViewController() presentViewController:nav animated:YES completion:nil];
    }];
}

#pragma mark HXPhotoViewControllerDelegate
- (void)photoViewControllerDidNext:(NSArray<HXPhotoModel *> *)allList Photos:(NSArray<HXPhotoModel *> *)photos Videos:(NSArray<HXPhotoModel *> *)videos Original:(BOOL)original {
    
    HXPhotoModel *model = [photos firstObject];
    UIImage *editImage = model.thumbPhoto;
    [SVProgressHUD showWithStatus:@"正在上传" maskType:SVProgressHUDMaskTypeBlack];

    
    NSData *_upLoadData = nil;
    NSData *tmpImageData = UIImagePNGRepresentation(editImage);
    NSData * StoreToFileData = nil;
    if (editImage.size.width > 960) {
        StoreToFileData = createRectImage(tmpImageData, CGSizeMake(960, 960), 0.85);
        _upLoadData = StoreToFileData;
    }else {
        _upLoadData = createRectImage(tmpImageData, editImage.size, 0.85);
        //            _upLoadData = tmpImageData;
    }
    
    NSString *   _uploadUniqueKey = [NSString UUID];
    
    NSInteger privateKey = 0;
    
    WeakSelf(self);
    [_photoAlbumBL uploadPhotoData:_upLoadData description:nil uploadUniqueKey:_uploadUniqueKey privateKey:privateKey  block:^(PhotoAlbumEntity *entity, NSError *error) {
        if (error.code == 0) {
            if (_repleaceIndex == -1) {
                [weakself addAlbumEntity:entity];
            }else{
                [weakself replaceWithEntity:entity];
            }
            
            [SVProgressHUD dismiss];
        } else if (error.code == 941) {
            [SVProgressHUD dismiss];
        
        }
        else {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        }
    }];

}

-(void)photoViewControllerDidCancel{
    _repleaceIndex = -1;
}

- (void)replaceWithEntity:(PhotoAlbumEntity*)entity{
    self.haveEditPhtoAlbum = YES;
    
    //先删除
    WeakSelf(self);
    PhotoAlbumEntity *deleteEntity = [self.dataSource objectAtIndex:_repleaceIndex];
    [_photoAlbumBL deletePhotoAlbumById:deleteEntity.photoId block:^(NSError *error) {
        
        if (error.code == 0) {
            
            [weakself.dataSource replaceObjectAtIndex:_repleaceIndex withObject:entity];
            [weakself.gridView reloadData];
            _repleaceIndex = -1;//重置
            
        } else {
            [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
        }
    }];
    
    
}

- (void)addAlbumEntity:(PhotoAlbumEntity*)entity{
    self.haveEditPhtoAlbum = YES;
    [self.dataSource insertObject:entity atIndex:self.dataSource.count-1];
    if (self.dataSource.count >= 9) {
        [self.dataSource removeLastObject];
    }
    if (self.dataSource.count > 4) {
        CGFloat with = (UI_SCREEN_WIDTH - 25.0)/4.0;
        self.gridView.frame = CGRectMake(0, 0, UI_SCREEN_WIDTH, with+10 + with+5);
        self.gridView.contentSize = CGSizeMake(UI_SCREEN_WIDTH, self.gridView.frame.size.height);
        [self.contentVC resetHeadView];
    }
    [self.gridView reloadData];
}

- (NSInteger)realEntity{
    
    NSInteger total = 0;
    for(PhotoAlbumEntity *entity in self.dataSource){
        if (entity.photoId > 0) {
            total++;
        }
    }
    return total;
}

#pragma mark -
- (PhotoAlbumBL *)photoAlbumBL
{
    if (!_photoAlbumBL) {
        _photoAlbumBL = [[PhotoAlbumBL alloc] init];
    }
    return _photoAlbumBL;
}

- (NSMutableArray *)dataSource
{
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (HXPhotoManager *)manager {
    if (!_manager) {
        /**  注意!!! 如果是先选照片拍摄的话, 不支持将拍摄的照片或者视频保存到系统相册  **/
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhoto];
        _manager.openCamera = YES;
        _manager.cameraType = HXPhotoManagerCameraTypeSystem;
        _manager.saveSystemAblum = YES;
        _manager.singleSelected = YES;
    }
    return _manager;
}
-(void)dealloc{
    [_currentMSAlertView dismissWithAnimated:NO];
}
@end
