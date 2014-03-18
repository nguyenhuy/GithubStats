//
//  GSReposViewController.h
//  GithubStats
//
//  Created by Huy Nguyen on 2/15/13.
//  Copyright (c) 2013 Huy Nguyen. All rights reserved.
//

#define NIB_REPOS_VIEW_CONTROLLER @"GSReposViewController"

@class UAGithubEngine;

@interface GSReposViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) UAGithubEngine *engine;

+ (GSReposViewController *)newInstanceWithEngine:(UAGithubEngine *)engine;
- (void)refresh;

@end
