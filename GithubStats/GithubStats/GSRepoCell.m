//
//  GSRepoCell.m
//  GithubStats
//
//  Created by Huy Nguyen on 2/15/13.
//  Copyright (c) 2013 Huy Nguyen. All rights reserved.
//

#import "GSRepoCell.h"
#import "Repo.h"

@implementation GSRepoCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)updateViewWithRepo:(Repo *)repo andIndexPath:(NSIndexPath *)indexPath {
    self.indexPath = indexPath;
    self.textLabel.text = repo.fullName;
    self.detailTextLabel.text = [Utils stringFromDate:repo.updatedDate];
}

@end
