//
//  JJCollectionViewLayout.m
//  SpringCollectionView
//
//  Created by wjj on 2019/1/3.
//  Copyright © 2019 wjj. All rights reserved.
//

#import "JJCollectionViewLayout.h"

@implementation JJCollectionViewLayout {
    UIDynamicAnimator *_animator;
    NSMutableSet *_visibleIndexPaths;
    CGPoint _lastContentOffset;
    CGFloat _lastScrollDelta;
}

#define kScrollPaddingRect              1000.0f
#define kScrollRefreshThreshold         100.0f
#define kScrollResistanceCoefficient    1 / 1500.0f

- (void)setup {
    _animator = [[UIDynamicAnimator alloc] initWithCollectionViewLayout:self];
    _visibleIndexPaths = [NSMutableSet set];
}

- (id)init {
    self = [super init];
    if (self){
        [self setup];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self){
        [self setup];
    }
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];
    [self addAnimators];
}

- (void)addAnimators
{
    CGPoint contentOffset = self.collectionView.contentOffset;
    if (fabs(contentOffset.y - _lastContentOffset.y) < kScrollRefreshThreshold && _visibleIndexPaths.count > 0){
        return;
    }
    _lastContentOffset = contentOffset;
    CGFloat padding = kScrollPaddingRect;
    CGRect currentRect = CGRectMake(0, contentOffset.y - padding, self.collectionView.frame.size.width, self.collectionView.frame.size.height + 2 * padding);
    
    NSArray *itemsInCurrentRect = [super layoutAttributesForElementsInRect:currentRect];
    
    NSMutableSet *indexPathsInVisibleRect = [NSMutableSet set];
    for (UICollectionViewLayoutAttributes *layout in itemsInCurrentRect) {
        //如果有header的话，header的indexPath等于第一个cell的indexpath，所以加上kind区分
        NSString *string = [NSString stringWithFormat:@"%ld-%ld-%@",layout.indexPath.section,layout.indexPath.row,layout.representedElementKind?layout.representedElementKind:@"cell"];
        [indexPathsInVisibleRect addObject:string];
    }
    
    [_animator.behaviors enumerateObjectsUsingBlock:^(UIAttachmentBehavior *behaviour, NSUInteger idx, BOOL *stop) {
        UICollectionViewLayoutAttributes *layout = (UICollectionViewLayoutAttributes *)[[behaviour items] firstObject];
        NSIndexPath *indexPath = [layout indexPath];
        NSString *string = [NSString stringWithFormat:@"%ld-%ld-%@",indexPath.section,indexPath.row,layout.representedElementKind?layout.representedElementKind:@"cell"];
        
        BOOL isInVisibleIndexPaths = [indexPathsInVisibleRect member:string] != nil;
        if (!isInVisibleIndexPaths){
            [self->_animator removeBehavior:behaviour];
            [self->_visibleIndexPaths removeObject:string];
        }
    }];
    
    NSArray *newVisibleItems = [itemsInCurrentRect filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *item, NSDictionary *bindings) {
        NSString *string = [NSString stringWithFormat:@"%ld-%ld-%@",item.indexPath.section,item.indexPath.row,item.representedElementKind?item.representedElementKind:@"cell"];
        BOOL isInVisibleIndexPaths = [self->_visibleIndexPaths member:string] != nil;
        return !isInVisibleIndexPaths;
    }]];
    
    [newVisibleItems enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attribute, NSUInteger idx, BOOL *stop) {
        UIAttachmentBehavior *spring = [[UIAttachmentBehavior alloc] initWithItem:attribute attachedToAnchor:attribute.center];
        spring.length = 0;
        spring.frequency = 5;
        spring.damping = 0.8;
        __weak UIAttachmentBehavior *weakSpring = spring;
        spring.action = ^(void){
            CGFloat delta = fabs(attribute.center.y - weakSpring.anchorPoint.y);
            if (delta < 2){
                weakSpring.damping = 100;
            } else {
                weakSpring.damping = 2;
            }
        };
        [self->_animator addBehavior:spring];
        NSString *string = [NSString stringWithFormat:@"%ld-%ld-%@",attribute.indexPath.section,attribute.indexPath.row,attribute.representedElementKind?attribute.representedElementKind:@"cell"];
        [self->_visibleIndexPaths addObject:string];
    }];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    if (_visibleIndexPaths.count > 0) {
        CGFloat padding = kScrollPaddingRect;
        rect.size.height += 2 * padding;
        rect.origin.y -= padding;
        return [_animator itemsInRect:rect];
    }else{
        NSArray *array = [super layoutAttributesForElementsInRect:rect];
        return array;
    }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    id layoutAttributes = [_animator layoutAttributesForCellAtIndexPath:indexPath];
    if (!layoutAttributes)
        layoutAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    return layoutAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    _lastScrollDelta = newBounds.origin.y - self.collectionView.bounds.origin.y;
    return NO;
}

- (void)adjustSpring:(UIAttachmentBehavior *)spring scrollDelta:(CGFloat)scrollDelta location:(CGPoint)location
{
    CGFloat distanceFromTouch = 0;
    if (fabs(scrollDelta) > 200) {  //有些情况可能会提前加载更多或历史，导致contentOffset变化，要过滤这种情况
        return;
    }
    //如果手指没离开屏幕，则以手指所在点为锚点，否则则以collectionView的上或下 为锚点
    if (self.collectionView.isDragging && !self.collectionView.isDecelerating) {
        if (scrollDelta < 0) {
            if (spring.anchorPoint.y < location.y - 50) {
                distanceFromTouch = fabs(spring.anchorPoint.y - location.y);
            }
        } else {
            if (spring.anchorPoint.y > location.y + 50) {
                distanceFromTouch = fabs(location.y - spring.anchorPoint.y);
            }
        }
    }else{
        if (scrollDelta < 0) {
            if (spring.anchorPoint.y < self.collectionView.contentOffset.y) {
                distanceFromTouch = fabs(self.collectionView.contentOffset.y - spring.anchorPoint.y);
            }
        } else {
            if (spring.anchorPoint.y > self.collectionView.contentOffset.y + self.collectionView.frame.size.height) {
                distanceFromTouch = fabs(spring.anchorPoint.y - self.collectionView.contentOffset.y - self.collectionView.frame.size.height);
            }
        }
    }
    if (distanceFromTouch > 0) {
        CGFloat scrollResistance = distanceFromTouch * kScrollResistanceCoefficient;
        UICollectionViewLayoutAttributes *item = (UICollectionViewLayoutAttributes *)[spring.items firstObject];
        CGPoint center = item.center;
        if (scrollDelta < 0) {
            center.y += MAX(scrollDelta, scrollDelta * scrollResistance);
        } else {
            center.y += MIN(scrollDelta, scrollDelta * scrollResistance);
        }
        item.center = center;
        [self->_animator updateItemUsingCurrentState:item];
    }
}

- (void)executeAnimaiont
{
    if (self.collectionView.isDragging) {  //不是手指拖动的滑动 不执行动画
        UIScrollView *scrollView = self.collectionView;
        CGPoint touchLocation = [scrollView.panGestureRecognizer locationInView:scrollView];
        [_animator.behaviors enumerateObjectsUsingBlock:^(UIAttachmentBehavior *spring, NSUInteger idx, BOOL *stop) {
            [self adjustSpring:spring scrollDelta:self->_lastScrollDelta location:touchLocation];
        }];
    }
}

- (void)resetLayout{
    [_animator removeAllBehaviors];
    [_visibleIndexPaths removeAllObjects];
}

@end
