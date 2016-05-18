//
//  HorizontalScrollView.h
//  testa
//
//  Created by Ishay Weinstock on 12/16/14.
//  Copyright (c) 2014 Ishay Weinstock. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HorizontalTableView;

@protocol HorizontalTableViewDataSource <NSObject>

- (UIView*)horizontalScrollView:(HorizontalTableView*)view cellForIndex:(NSInteger)index;
- (NSInteger)horizontalScrollViewNumberOfCells:(HorizontalTableView*)scrollView;

@end

@interface HorizontalTableView : UIView
{
}

@property (nonatomic, weak)   id<HorizontalTableViewDataSource>    dataSource;
@property (assign) CGFloat                              cellWidth;

- (UIView*)dequeueCell;


@end
