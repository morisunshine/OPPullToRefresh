//
//  UIScrollView+OPPullToRefresh.h
//  OPPullToRefreshDemo
//
//  Created by Sheldon on 13-10-29.
//  Copyright (c) 2013年 Sheldon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OPPullToRefreshView;

@interface UIScrollView (OPPullToRefresh)

- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler;

@property (nonatomic, strong) OPPullToRefreshView *pullToRefreshView;
@property (nonatomic, assign) BOOL showsPullToResfresh;

@end

typedef NS_ENUM(NSUInteger, OPPullToRefreshState)
{
    OPPullToRefreshStateStopped = 0,
    OPPullToRefreshStateTriggered,
    OPPullToRefreshStateLoading,
    OPPullToRefreshStateAll = 10
};

@interface OPPullToRefreshView : UIView

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@property (nonatomic, readonly) OPPullToRefreshState state;

- (void)stopAnimating;

@end
