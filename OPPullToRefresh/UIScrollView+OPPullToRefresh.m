//
//  UIScrollView+OPPullToRefresh.m
//  OPPullToRefreshDemo
//
//  Created by Sheldon on 13-10-29.
//  Copyright (c) 2013年 Sheldon. All rights reserved.
//

#import "UIScrollView+OPPullToRefresh.h"

static CGFloat const OPPullToRefreshViewHeight = 30;

@interface OPPullToRefreshView ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);

@property (nonatomic, strong) UIImageView *circle;
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


- (void)addOPPullToRefreshWithActionHandler:(void (^)(void))actionHandler
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

@synthesize pullToRefreshActionHandler;
@synthesize state = _state;
@synthesize scrollView = _scrollView;
@synthesize titleLabel = _titleLabel;
@synthesize textColor = _textColor;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.titles = [NSMutableArray arrayWithObjects:NSLocalizedString(@"Pull to refresh",), NSLocalizedString(@"Release to Refresh...", ), NSLocalizedString(@"Loading...",), nil];
        self.subtitles = [NSMutableArray arrayWithObjects:@"",@"",@"",@"", nil];
        self.textColor = [UIColor colorWithRed:0/255.0 green:203/255.0 blue:124/255.0 alpha:1];
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

- (void)layoutSubviews
{
    switch (self.state) {
        case OPPullToRefreshStateAll:
        case OPPullToRefreshStateStopped:
            self.circle.alpha = 1;
            [self rotateCircle:0 hide:NO];
            break;
        case OPPullToRefreshStateTriggered:
            [self rotateCircle:(float)M_PI hide:NO];
            break;
        case OPPullToRefreshStateLoading:
            [self rotateCircel];
            break;
    }
    
    self.titleLabel.text = self.titles[self.state];
}

#pragma mark - Observing -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    }
}

#pragma mark - Private Methods -

- (void)resetScrollViewContentInset
{
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.originalTopInset;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForLoading
{
    CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0);
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = MIN(offset, self.originalTopInset + self.bounds.size.height);
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset
{
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                        self.scrollView.contentInset = contentInset;
                     }
                     completion:nil];
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset
{
    if (self.state != OPPullToRefreshStateLoading) {
        CGFloat scrollOffsetThreshold = 0;
        scrollOffsetThreshold = self.frame.origin.y - self.originalTopInset;
        NSLog(@"ScollOffset:%f",contentOffset.y);
        NSLog(@"Threshold:%f", scrollOffsetThreshold);
        
        if(!self.scrollView.isDragging && self.state == OPPullToRefreshStateTriggered)
        {
            self.state = OPPullToRefreshStateLoading;
        }
        else if(contentOffset.y < scrollOffsetThreshold && self.scrollView.isDragging && self.state == OPPullToRefreshStateStopped)
        {
            self.state = OPPullToRefreshStateTriggered;
        }
        else if(contentOffset.y >= scrollOffsetThreshold && self.state != OPPullToRefreshStateStopped)
        {
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

#pragma mark - Setters -

- (void)setState:(OPPullToRefreshState)newState
{
    if (_state == newState) {
        return;
    }
    
    OPPullToRefreshState previousState = _state;
    _state = newState;
    
    [self layoutSubviews];
    
    switch (newState) {
        case OPPullToRefreshStateAll:
        case OPPullToRefreshStateStopped:
            [self resetScrollViewContentInset];
            break;
        case OPPullToRefreshStateTriggered:
            break;
        case OPPullToRefreshStateLoading:
            [self setScrollViewContentInsetForLoading];
            
            if (previousState == OPPullToRefreshStateTriggered && pullToRefreshActionHandler) {
                pullToRefreshActionHandler();
            }
            break;
    }
}

#pragma mark - Animates -

- (void)rotateCircle:(float)degress hide:(BOOL)hide
{
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        self.circle.layer.transform = CATransform3DMakeRotation(degress, 0, 0, 1);
        self.circle.layer.opacity = !hide;
    } completion:nil];
}

- (void)rotateCircel
{
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.circle.transform = CGAffineTransformRotate(self.circle.transform, M_PI_2);
    } completion:^(BOOL finished) {
        if (finished) {
            [self rotateCircel];
        }
    }];
}

- (void)stopAnimating
{
    self.state = OPPullToRefreshStateStopped;
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
}

#pragma mark - Getters -

- (UIImageView *)circle
{
    if (!_circle) {
        UIImage *image = [UIImage imageNamed:@"loading.png"];
        _circle = [[UIImageView alloc] initWithFrame:CGRectMake(100, self.bounds.size.height - image.size.height, image.size.width, image.size.height)];
        _circle.image = image;
        _circle.backgroundColor = [UIColor clearColor];
        [self addSubview:_circle];
    }
    
    return _circle;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        CGFloat xOrigin = self.circle.frame.origin.x + self.circle.frame.size.width + 10;
        CGFloat yOrigin = self.circle.frame.origin.y;
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(xOrigin, yOrigin, 210, 20)];
        _titleLabel.text = NSLocalizedString(@"pull to refresh", );
        _titleLabel.font = [UIFont systemFontOfSize:14];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = self.textColor;
        [self addSubview:_titleLabel];
    }
    
    return _titleLabel;
}

@end
