//
//  PullRequest.h
//  GithubStats
//
//  Created by Huy Nguyen on 3/7/13.
//  Copyright (c) 2013 Huy Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PullRequest : NSManagedObject

@property (nonatomic, retain) NSString * authorLogin;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * mergedByLogin;
@property (nonatomic, retain) NSDate * mergedDate;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSNumber * repoId;

@end
