//
//  JJCollectionViewLayout.h
//  SpringCollectionView
//
//  Created by 王俊杰 on 2019/1/3.
//  Copyright © 2019 wjj. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface JJCollectionViewLayout : UICollectionViewFlowLayout

- (void)resetLayout;  //reset animaion. 在增加删除cell的时候需要先执行reset。在有动画的时候，需要跳转到某个cell，也需要执行reset

- (void)executeAnimaiont;

@end

NS_ASSUME_NONNULL_END
