//
//  HMAlbumViewController.m
//  photosFramework
//
//  Created by HuminiOS on 15/11/11.
//  Copyright © 2015年 HuminiOS. All rights reserved.
//

#import "JMUIAlbumViewController.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "JMUIAlbumTableViewCell.h"
#import "JMUIAlbumModel.h"
#import "JMUIPhotoPickerConstants.h"

@interface JMUIAlbumViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *albumTable;
@property (strong, nonatomic) NSMutableArray * assetsGroups; //iOS 8以前 的数据 的
@property (strong, nonatomic)NSMutableArray *albumArr;

@property (assign, nonatomic)NSInteger getDataschedule;// iOS 8 以前用来标识 所有的数据 已经获取完成
@end

@implementation JMUIAlbumViewController


- (void)viewDidLoad {// add model
  [super viewDidLoad];

  [self setupNavigationBar];
  _albumArr = @[].mutableCopy;

  if ([[[UIDevice currentDevice]systemVersion] floatValue]>= 8) {
    [self prepareAlbumArrWithPhotosFramework];
  } else {
    [self prepareAlbumArrWithAssert];
  }

  [_albumTable registerNib:[UINib nibWithNibName:@"JMUIAlbumTableViewCell" bundle:[NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"JMUIMultiSelectPhotosKitResource" withExtension:@"bundle"]]]
    forCellReuseIdentifier:@"JMUIAlbumTableViewCell"];
  _albumTable.delegate = self;
  _albumTable.dataSource = self;

  if ([[[UIDevice currentDevice]systemVersion] floatValue]>= 8) {
    [self pushToSelectPhotoVCWithIndex:0];
  } else {
    [self performSelector:@selector(pushToSelectPhotoVCWithIndex:) withObject:0 afterDelay:0.1];
  }
}

- (void)setupNavigationBar {
  self.title = @"相簿";
  self.navigationController.navigationBar.translucent = NO;
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"取消"
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(cancel)];
}

- (void)prepareAlbumArrWithPhotosFramework {//ios 8 系统以后使用 photos.framework
//  all photoAlbumdel
  PHFetchOptions *allPhotosOptions = [[PHFetchOptions alloc] init];
  allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
  PHFetchResult *allPhotos = [PHAsset fetchAssetsWithOptions:allPhotosOptions];
  JMUIAlbumModel *albumModel = [JMUIAlbumModel new];
  [albumModel setDataWithAlbumResult:allPhotos];
  [_albumArr addObject:albumModel];
  
//  smartAlbums
  PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];

  for (PHAssetCollection *enumCollection in smartAlbums) {
    PHFetchResult *albumImagaAssert = [PHAsset fetchAssetsInAssetCollection:enumCollection options:nil];
    if (albumImagaAssert.count == 0) {
      continue;
    }
    JMUIAlbumModel *model = [JMUIAlbumModel new];
    [model setDataWithAlbumCollection:enumCollection];
    [_albumArr addObject:model];
  }
  
  PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
  for (PHAssetCollection *enumCollection in topLevelUserCollections) {
    PHFetchResult *albumImagaAssert = [PHAsset fetchAssetsInAssetCollection:enumCollection options:nil];
    if (albumImagaAssert.count == 0) {
      continue;
    }
    JMUIAlbumModel *model = [JMUIAlbumModel new];
    [model setDataWithAlbumCollection:enumCollection];
    [_albumArr addObject:model];
  }
}

- (void)prepareAlbumArrWithAssert {//ios 8 以前使用 AssetsLibrary
  ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
  void (^assetsGroupsEnumerationBlock)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *assetsGroup, BOOL *stop) {
    if(assetsGroup) {
      _getDataschedule --;
      [assetsGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
      if(assetsGroup.numberOfAssets > 0) {
        JMUIAlbumModel *model = [JMUIAlbumModel new];
        [model setDataWithAssets:assetsGroup];
        [_albumArr addObject:model];
      }
      if (_getDataschedule == 0) {
        [self.albumTable reloadData];//移出去
      }
    }
  };
  
  void (^assetsGroupsFailureBlock)(NSError *) = ^(NSError *error) {
    _getDataschedule --;
    if (_getDataschedule == 0) {
      [self.albumTable reloadData];
    }
    NSLog(@"Error: %@", [error localizedDescription]);
  };
  
  _getDataschedule = 4;
  // Enumerate Camera Roll
  [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:assetsGroupsEnumerationBlock failureBlock:assetsGroupsFailureBlock];
  
  // Album
  [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:assetsGroupsEnumerationBlock failureBlock:assetsGroupsFailureBlock];
  
  // Event
  [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupEvent usingBlock:assetsGroupsEnumerationBlock failureBlock:assetsGroupsFailureBlock];
  
  // Faces
  [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupFaces usingBlock:assetsGroupsEnumerationBlock failureBlock:assetsGroupsFailureBlock];
}

- (void)cancel{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return _albumArr.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section != 0) { //如果相册没有图片 则不显示，
    PHFetchResult *albumResult = _albumArr[indexPath.section];
    PHFetchResult *allPhotoInCollection  = [PHAsset fetchAssetsInAssetCollection:(PHAssetCollection *)albumResult[indexPath.row] options:nil];
    if (allPhotoInCollection.count == 0) {
      return 0;
    }
  }
  return 55;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  static NSString *albumCellIdentify = @"JMUIAlbumTableViewCell";
  JMUIAlbumTableViewCell *cell = (JMUIAlbumTableViewCell *)[_albumTable dequeueReusableCellWithIdentifier:albumCellIdentify];
  [cell layoutWithAlbumModel:_albumArr[indexPath.row]];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self pushToSelectPhotoVCWithIndex:indexPath.row];
}

- (void)pushToSelectPhotoVCWithIndex:(NSInteger)index {


    JMUIPhotoSelectViewController *selectPhotoVC = [[JMUIPhotoSelectViewController alloc] initWithNibName:@"JMUIPhotoSelectViewController" bundle:[NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"JMUIMultiSelectPhotosKitResource" withExtension:@"bundle"]]];
  
  JMUIAlbumModel *model = _albumArr[index];
  
  if ([[[UIDevice currentDevice]systemVersion] floatValue] >= 8) {
    if (index == 0) {
      selectPhotoVC.allFetchResult = model.albumFetchResult;
    } else {
      selectPhotoVC.photoCollection = model.albumCollection;
    }
    
  } else {
    selectPhotoVC.assetsGroup  = model.assetsGroup;
  }
  
  selectPhotoVC.photoDelegate = _photoDelegate;
  [self.navigationController pushViewController:selectPhotoVC animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
