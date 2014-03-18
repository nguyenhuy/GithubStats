//
//  GSCalendarViewController.h
//  GithubStats
//
//  Created by Huy Nguyen on 2/15/13.
//  Copyright (c) 2013 Huy Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TKCalendarMonthTableViewController.h"

@class UAGithubEngine;
@class Repo;

@interface GSCalendarViewController : TKCalendarMonthTableViewController

@property (strong, nonatomic) UAGithubEngine *engine;
@property (strong, nonatomic) Repo *repo;
@property (strong, nonatomic) FDStatusBarNotifierView *statusView;

+ (GSCalendarViewController *)newInstanceWithEngine:(UAGithubEngine *)engine andRepo:(Repo *)repo;

- (void)showStatusWithMessage:(NSString *)message andManuallyHide:(BOOL)manuallyHide;
- (void)hideStatusView;

- (void)fetchAllData;
- (void)fetchCommitsOfCurrentMonth;
- (void)fetchOpenPullRequests;
- (void)fetchClosedPullRequests;
- (void)fetchPullRequestsWithState:(NSString *)state;

@end
