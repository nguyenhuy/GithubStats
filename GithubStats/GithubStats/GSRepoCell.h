//
//  GSRepoCell.h
//  GithubStats
//
//  Created by Huy Nguyen on 2/15/13.
//  Copyright (c) 2013 Huy Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

#define IDENTIFIER_REPO_CELL @"RepoCell"

@class Repo;

@interface GSRepoCell : UITableViewCell

@property (strong, nonatomic) NSIndexPath *indexPath;

- (void)updateViewWithRepo:(Repo *)repo andIndexPath:(NSIndexPath *)indexPath;

@end
