//
//  HorizontalScrollView.m
//  testa
//
//  Created by Ishay Weinstock on 12/16/14.
//  Copyright (c) 2014 Ishay Weinstock. All rights reserved.
//

#import "HorizontalTableView.h"

#define SEPARATOR_WIDTH 1
#define DEFAULT_CELL_WIDTH 100

#define WIDTH_SCREEN ([UIScreen mainScreen].bounds.size.width)

#define NUMBER_OF_PADDING_CELLS 2 //extra cells for beyond visible ones

@interface HorizontalTableView() <UIScrollViewDelegate>

//The scroll view of the table
@property (nonatomic, strong) UIScrollView *horizontalScrollView;

//Total number of cells that should be shown
@property (nonatomic, assign) NSUInteger numberOfCells;

//Number of cells that will be loaded
@property (nonatomic, assign) NSUInteger numberOfVisibleCells;

//Array that contains the last cell that was removed
@property (nonatomic, strong) NSMutableArray *arrDequeueCell;

//This is saved to calculate scroll direction
@property (nonatomic, assign) CGFloat lastContentOffset;

//saves the cells that were created
@property (nonatomic, strong) NSMutableDictionary *visibleCells;

//The first and last index that is currently loaded
@property (nonatomic, assign) NSUInteger firstVisibleIndex;
@property (nonatomic, assign) NSUInteger lastVisibleIndex;

//to check if the table was loaded
@property (nonatomic, assign) BOOL didLoadTable;

@end

@implementation HorizontalTableView

#pragma mark - init

-(void)layoutSubviews
{
    if (_didLoadTable == NO)
    {
        //checking if the tables frame was set and if the data source was set
        if (CGRectIsEmpty(self.frame) == NO && _dataSource != nil)
        {
            _didLoadTable = YES;
            [self setupView];
        }
    }
}

-(void) setDataSource:(id<HorizontalTableViewDataSource>)dataSource
{
    _dataSource = dataSource;
    if (_didLoadTable == NO)
    {
        //checking if the tables frame was set
        if (CGRectIsEmpty(self.frame) == NO)
        {
            [self setupView];
        }
    }
}

- (void) setupView
{
    _arrDequeueCell = [NSMutableArray array];
    _visibleCells = [NSMutableDictionary dictionary];
    
    //get number of cells from viewController
    _numberOfCells = [_dataSource horizontalScrollViewNumberOfCells:self];
    
    [self addSubview:self.horizontalScrollView];
    
    //calculate how many cells to save/create
    _numberOfVisibleCells = MIN(_numberOfCells, (NSInteger)WIDTH_SCREEN/DEFAULT_CELL_WIDTH + NUMBER_OF_PADDING_CELLS*2);
    
    _firstVisibleIndex = 0;
    _lastVisibleIndex = _numberOfVisibleCells -1;
    
    //load the table
    for (NSInteger i=0; i<_numberOfVisibleCells; i++)
    {
        [self loadCellAtIndex:i];
    }
}

//init scroll view
- (UIScrollView*) horizontalScrollView
{
    if(_horizontalScrollView)
    {
        return _horizontalScrollView;
    }
    
    _horizontalScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, WIDTH_SCREEN, self.frame.size.height)];
    _horizontalScrollView.delegate = self;
    _horizontalScrollView.contentSize = CGSizeMake(DEFAULT_CELL_WIDTH*_numberOfCells, self.frame.size.height);
    _horizontalScrollView.showsHorizontalScrollIndicator = NO;
    _horizontalScrollView.bounces = NO;
    return _horizontalScrollView;
}

#pragma mark - dequeue
- (UIView*)dequeueCell
{
    if(_arrDequeueCell.count<1)
    {
        return nil;
    }
    
    UILabel *lblCell = [_arrDequeueCell lastObject];
    [_arrDequeueCell removeLastObject];
    lblCell.text = @"";
    
    return lblCell;
}

#pragma mark - UIScroll view delegate and methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger mostLeftCellIndex = scrollView.contentOffset.x/DEFAULT_CELL_WIDTH;
    
    if (self.lastContentOffset > scrollView.contentOffset.x)//scrolling right
    {
        [self addCellToTheLeftWithleftestVisibleIndex:mostLeftCellIndex];
    }
    else if (self.lastContentOffset < scrollView.contentOffset.x) // scrolling left
    {
        [self addCellToTheRightWithleftestVisibleIndex:mostLeftCellIndex];
    }
    
    self.lastContentOffset = scrollView.contentOffset.x;
}

-(void) addCellToTheLeftWithleftestVisibleIndex:(NSInteger)mostLeftCellIndex
{
    NSInteger numberOfCellToLoad = mostLeftCellIndex - NUMBER_OF_PADDING_CELLS ;
    
    BOOL didUpdate = NO;
    if (numberOfCellToLoad >=0 && [_visibleCells objectForKey:@(numberOfCellToLoad)] == nil)
    {
        didUpdate = YES;
        
        //in case scrolling was to fast and we need to load more than 1 cell
        for (NSInteger indexToLoad=_firstVisibleIndex-1; indexToLoad>=numberOfCellToLoad; indexToLoad--)
        {
            
            NSInteger indexOfCellToRemove = indexToLoad + _numberOfVisibleCells;
            
            if (indexOfCellToRemove <= _numberOfCells)
            {
                UIView *lastCell = [_visibleCells objectForKey:@(indexOfCellToRemove)];
                //if the cell to remove exist - save it and remove from superview
                if (lastCell)
                {
                    [_arrDequeueCell addObject:lastCell];
                    [lastCell removeFromSuperview];
                    [_visibleCells removeObjectForKey:@(indexOfCellToRemove)];
                }
            }
            
            [self loadCellAtIndex:indexToLoad];
        }
    }
    if (didUpdate)
    {
        _lastVisibleIndex = numberOfCellToLoad +_numberOfVisibleCells-1;;
        _firstVisibleIndex = numberOfCellToLoad;
    }
}

-(void) addCellToTheRightWithleftestVisibleIndex:(NSInteger)mostLeftCellIndex
{
    NSInteger numberOfCellToLoad = mostLeftCellIndex+_numberOfVisibleCells  - NUMBER_OF_PADDING_CELLS;
    
    BOOL didUpdate = NO;
    if (numberOfCellToLoad < _numberOfCells && [_visibleCells objectForKey:@(numberOfCellToLoad)] == nil)
    {
        didUpdate = YES;
        //in case scrolling was to fast and we need to load more than 1 cell
        for (NSInteger indexToLoad = _lastVisibleIndex+1; indexToLoad <= numberOfCellToLoad; indexToLoad++)
        {
            NSInteger indexOfCellToRemove = indexToLoad - _numberOfVisibleCells;
            if (indexOfCellToRemove >= 0)
            {
                UIView *lastCell = [_visibleCells objectForKey:@(indexOfCellToRemove)];
                //if the cell to remove exist - save it and remove from superview
                if (lastCell)
                {
                    [_arrDequeueCell addObject:lastCell];
                    [lastCell removeFromSuperview];
                    [_visibleCells removeObjectForKey:@(indexOfCellToRemove)];
                }
                
            }
            [self loadCellAtIndex:indexToLoad];
        }
    }
    if (didUpdate)
    {
        _firstVisibleIndex = numberOfCellToLoad - _numberOfVisibleCells +1;
        _lastVisibleIndex = numberOfCellToLoad;
    }
}

#pragma mark - load cell to scroll view
-(void) loadCellAtIndex:(NSInteger)index
{
    
    UILabel *lblCell = (UILabel*)[_dataSource horizontalScrollView:self cellForIndex:index];
    //if label has no frame - create frame
    if (CGRectIsEmpty(lblCell.frame))
    {
        lblCell.frame = CGRectMake(index*DEFAULT_CELL_WIDTH, 0, DEFAULT_CELL_WIDTH, self.frame.size.height);
    }
    else //frame exists - change x value
    {
        CGRect r = lblCell.frame;
        r.origin.x = index*DEFAULT_CELL_WIDTH;
        lblCell.frame = r;
    }
    
    //add cell to dictionary
    [_visibleCells setObject:lblCell forKey:@(index)];
    
    //add cell to scroll view
    [self.horizontalScrollView addSubview:lblCell];
}





@end
