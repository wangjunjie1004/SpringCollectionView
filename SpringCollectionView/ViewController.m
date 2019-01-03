//
//  TestViewController.m
//  SpringCollectionView
//
//  Created by wjj on 2019/1/3.
//  Copyright © 2019 wjj. All rights reserved.
//

#import "ViewController.h"
#import "JJCollectionViewLayout.h"

@interface ViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong)UICollectionView *collectionView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    JJCollectionViewLayout *layout = [[JJCollectionViewLayout alloc] init];
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 0;
    // NOTE:动画需要每个cell(包括header和footer)的宽高都为偶数，因为header的宽度就是UICollectionView的宽度
    // 所以设置UICollectionView的宽度为偶数
    NSInteger width = [[NSNumber numberWithFloat:[UIScreen mainScreen].bounds.size.width] integerValue];
    if (width % 2 != 0) {
        width -= 1;
    }
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, width, self.view.bounds.size.height) collectionViewLayout:layout];
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.scrollsToTop = NO;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"JJCollectionViewCell"];
    [self.view addSubview:self.collectionView];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 500;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"JJCollectionViewCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor redColor];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //高度设为偶数
    return CGSizeMake(collectionView.bounds.size.width, 44.0);
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    //高度设为偶数
    return CGSizeMake(collectionView.bounds.size.width, 34);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if ([scrollView isKindOfClass:UICollectionView.class]) {
        UICollectionView *collectionView = (UICollectionView *)scrollView;
        //执行动画
        [(JJCollectionViewLayout *)collectionView.collectionViewLayout executeAnimaiont];
    }
}

@end
