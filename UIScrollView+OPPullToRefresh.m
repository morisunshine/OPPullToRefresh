//
//  UIScrollView+OPPullToRefresh.m
//  OPPullToRefreshDemo
//
//  Created by Sheldon on 13-10-29.
//  Copyright (c) 2013年 Sheldon. All rights reserved.
//

#import "UIScrollView+OPPullToRefresh.h"

static CGFloat const OPPullToRefreshViewHeight = 60;

@interface OPPullToRefreshView ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);

@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UILabel *subtitleLabel;
@property (nonatomic, assign) BOOL isObserving;

@end

#pragma mark - UIScrollView(OPPullToRefresh)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (OPPullToRefresh)

@dynamic pullToRefreshView, showsPullToResfresh;


- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler
{
    if (!self.pullToRefreshView) {
        CGFloat yOrigin = -OPPullToRefreshViewHeight;
        OPPullToRefreshView *view = [[OPPullToRefreshView alloc] initWithFrame:CGRectMake(0, yOrigin, self.bounds.size.width, OPPullToRefreshViewHeight)];
        view.pullToRefreshActionHandler = actionHandler;
        view.scrollView = self;
        [self addSubview:view];
        
        self.pullToRefreshView = view;
        self.showsPullToResfresh = YES;
    }
}

- (void)setPullToRefreshView:(OPPullToRefreshView *)pullToRefreshView
{
    [self willChangeValueForKey:@"OPPullToRefreshView"];
    objc_setAssociatedObject(self,
                             &UIScrollViewPullToRefreshView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"OPPullToRefreshView"];
}

- (OPPullToRefreshView *)pullToRefreshView
{
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)setShowsPullToResfresh:(BOOL)showsPullToResfresh
{
    self.pullToRefreshView.hidden = !showsPullToResfresh;
    
    if (!showsPullToResfresh) {
        if (self.pullToRefreshView.isObserving) {
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentSize"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"frame"];
            //todo:reset ScrollView
            self.pullToRefreshView.isObserving = NO;
        }
    } else {
        if (!self.pullToRefreshView.isObserving) {
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            self.pullToRefreshView.isObserving = YES;
            
            CGFloat yOrigin = 0;
            
            yOrigin = -OPPullToRefreshViewHeight;
            
            self.pullToRefreshView.frame = CGRectMake(0, yOrigin, self.bounds.size.width, OPPullToRefreshViewHeight);
        }
    }
}

- (BOOL)showsPullToResfresh
{
    return !self.pullToRefreshView;
}

@end
