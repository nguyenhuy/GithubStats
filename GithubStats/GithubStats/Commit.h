//
//  Commit.h
//  GithubStats
//
//  Created by Huy Nguyen on 3/7/13.
//  Copyright (c) 2013 Huy Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Commit : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * sha;
@property (nonatomic, retain) NSNumber * repoId;

@end
