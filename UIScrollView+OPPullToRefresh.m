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
@property (nonatomic, readwrite) OPPullToRefreshState state;
@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableArray *subtitles;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;

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
        
        view.originalTopInset = self.contentInset.top;
        
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

#pragma mark - OPPullToRefresh

@implementation OPPullToRefreshView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.titles = [NSMutableArray arrayWithObjects:NSLocalizedString(@"Pull to refresh",), NSLocalizedString(@"Release to Refresh...", ), NSLocalizedString(@"Loading...",), nil];
        self.subtitles = [NSMutableArray arrayWithObjects:@"",@"",@"",@"", nil];
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (self.superview && newSuperview == nil) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsPullToResfresh) {
            if (self.isObserving) {
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                self.isObserving = NO;
            }
        }
    }
}

#pragma mark - Observing -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset
{
    if (self.state != OPPullToRefreshStateLoading) {
        CGFloat scrollOffsetThreshold = 0;
        scrollOffsetThreshold = self.frame.origin.y - self.originalTopInset;
        
        if (!self.scrollView.isDragging && self.state == OPPullToRefreshStateTriggered) {
            self.state = OPPullToRefreshStateLoading;
        } else if (contentOffset.y < scrollOffsetThreshold && self.scrollView.isDragging && self.state == OPPullToRefreshStateStopped) {
            self.state = OPPullToRefreshStateTriggered;
        } else if (contentOffset.y >= scrollOffsetThreshold && self.state != OPPullToRefreshStateStopped) {
            self.state = OPPullToRefreshStateStopped;
        }
    } else {
        CGFloat offset;
        UIEdgeInsets contentInset;
        offset = MAX(self.scrollView.contentOffset.y * -1, 0.0);
        offset = MIN(offset, self.originalTopInset + self.bounds.size.height);
        contentInset = self.scrollView.contentInset;
        self.scrollView.contentInset = UIEdgeInsetsMake(offset, contentInset.left, contentInset.bottom, contentInset.right);
    }
}

- (void)setState:(OPPullToRefreshState)newState
{
    
}

@end
