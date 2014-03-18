//
//  GSCalendarViewController.m
//  GithubStats
//
//  Created by Huy Nguyen on 2/15/13.
//  Copyright (c) 2013 Huy Nguyen. All rights reserved.
//

#import "GSCalendarViewController.h"

#import "UAGithubEngine.h"
#import "UAGithubEngineConstants.h"
#import "SVProgressHUD.h"
#import "CoreData+MagicalRecord.h"

#import "Repo.h"
#import "Commit.h"
#import "PullRequest.h"

@interface GSCalendarViewController ()

- (NSArray *)commitsFromDate:(NSDate *)startDate toDate:(NSDate *)lastDate;
- (NSArray *)commitsForSelectedDate;
- (NSArray *)pullRequestsOpenedByUserFromDate:(NSDate *)startDate toDate:(NSDate *)lastDate;
- (NSArray *)pullRequestsOpenedByUserForSelectedDate;

@end

@implementation GSCalendarViewController

+ (GSCalendarViewController *)newInstanceWithEngine:(UAGithubEngine *)engine andRepo:(Repo *)repo {
    GSCalendarViewController *instance = [[GSCalendarViewController alloc] init];
    instance.engine = engine;
    instance.repo = repo;
    return instance;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.repo.fullName;
    
    // Add right "Refresh" bar button item
    UIBarButtonItem *refreshBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(fetchAllData)];
    self.navigationItem.rightBarButtonItem = refreshBtn;
    
    [self.monthView selectDate:self.repo.updatedDate];
}

- (void)viewDidAppear:(BOOL)animated {
    [self fetchAllData];
}

#pragma mark - TK Calendar Month View Datasource

- (NSArray *)calendarMonthView:(TKCalendarMonthView *)monthView marksFromDate:(NSDate *)startDate toDate:(NSDate *)lastDate {
    
    // Remove time in startDate and lastDate, just to be sure
    startDate = [Utils startOfDate:startDate];
    lastDate = [Utils startOfOneDayAfter:lastDate];
    
    NSMutableArray *result = [NSMutableArray array];
    
    for (NSDate *since = startDate, *until = [Utils startOfOneDayAfter:since];
         [since compare:lastDate] != NSOrderedDescending;
         since = until, until = [Utils startOfOneDayAfter:since]) {
        
        NSArray *commits = [self commitsFromDate:since toDate:until];
        
        // Calculate num of dots based on commits.
        // Result is rounded up. 1 -> 9 commits: 1 dot, 10 -> 19: 2 dots, etc
        int numOfDots = 0;
        if (commits.count > 0) {
            numOfDots = (commits.count + 10) / 10;
        }
        
        [result addObject:[NSNumber numberWithInt:numOfDots]];
    }
    
    return result;
}

#pragma mark - TK Calendar Month View Delegate

- (BOOL)calendarMonthView:(TKCalendarMonthView *)monthView monthShouldChange:(NSDate *)month animated:(BOOL)animated {
    // Only show the month if it's between created and updated months of the repo.
    return ([month compare:[Utils startOfMonth:self.repo.createdDate]] != NSOrderedAscending)
    && ([month compare:[Utils endOfMonth:self.repo.updatedDate]] != NSOrderedDescending);
}

- (void)calendarMonthView:(TKCalendarMonthView *)monthView monthDidChange:(NSDate *)month animated:(BOOL)animated {
    [super calendarMonthView:monthView monthDidChange:month animated:animated];
    //@TODO do we need to fetch commits here???
    //    [self fetchCommits];
}

- (void)calendarMonthView:(TKCalendarMonthView *)monthView didSelectDate:(NSDate *)date {
    [self.tableView reloadData];
}

#pragma mark - Table View Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    NSString *text;
    switch (indexPath.row) {
        case 0:
            text = [NSString stringWithFormat:@"Made %d commits", [[self commitsForSelectedDate] count]];
            break;
            
        case 1:
            text = [NSString stringWithFormat:@"Opened %d pull requests", [[self pullRequestsOpenedByUserForSelectedDate] count]];
            break;
            
        default:
            break;
    }
    
    cell.textLabel.text = text;
    
    return cell;
}

#pragma mark - Instance methods

#pragma mark Status View

- (void)showStatusWithMessage:(NSString *)message andManuallyHide:(BOOL)manuallyHide {
    dispatch_async(dispatch_get_main_queue(), ^() {
        if (!self.statusView) {
            self.statusView = [[FDStatusBarNotifierView alloc] init];
        }
        self.statusView.message = message;
        self.statusView.manuallyHide = manuallyHide;
        [self.statusView showInWindow:self.view.window];
    });
}

- (void)hideStatusView {
    dispatch_async(dispatch_get_main_queue(), ^() {
        [self.statusView hide];
    });
}

- (void)fetchAllData {
    //@TODO should determine whether to refresh or not
    [self showStatusWithMessage:@"Loading..." andManuallyHide:YES];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^() {
        [self fetchCommitsOfCurrentMonth];
        [self fetchOpenPullRequests];
        //@TODO don't fetch closed PRs for now, it's very slow
//        [self fetchClosedPullRequests];
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            [self.monthView reload];
            [self hideStatusView];
        });
    });
}

#pragma mark Commits

- (void)fetchCommitsOfCurrentMonth {
    //@TODO may check and only fetch commits if the month contains today (because people may put more commits)
    // or can't find any commit in CoreDate for the month.
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    [self showStatusWithMessage:@"Loading commits of this month..." andManuallyHide:YES];
    
    //@TODO test. Remove later.
    NSArray *commits = [Commit MR_findByAttribute:@"repoId" withValue:self.repo.repoId inContext:context];
    NSLog(@"--------------Total %d of commits in repo %@", commits.count, self.repo.fullName);
    
    static int step = 30;
    NSDate *monthDate = self.monthView.monthDate;
    NSDate *firstDate = [Utils startOfMonth:monthDate];
    NSDate *lastDate = [Utils endOfMonth:monthDate];
    
    // Start from last date and end at first date
    int counter = 0;
    for (NSDate *since = firstDate, *until = [Utils dateByAddingDays:step toDate:since];
         [since compare:lastDate] != NSOrderedDescending;
         since = until, until = [Utils dateByAddingDays:step toDate:since]) {
        NSLog(@"---------------Fetch commits since %@ until %@", since, until);
        
        NSDictionary *params = @{@"author": self.engine.username,
                                 @"since": [Utils githubDateStringFromDate:since],
                                 @"until": [Utils githubDateStringFromDate:until]
                                 };
        [self.engine commitsForRepository:self.repo.fullName withParameters:params success:^(id response) {
            // Delete commits between the time frame in this repo
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(repoId = %d) AND (createdDate >= %@) AND (createdDate <= %@)", [self.repo.repoId intValue], since, until];
            
            //@TODO test. Remove later
            NSArray *commits = [Commit MR_findAllWithPredicate:predicate inContext:context];
            NSLog(@"Before deleting, there are %d commits", commits.count);
            
            [Commit MR_deleteAllMatchingPredicate:predicate inContext:context];
            
            //@TODO test. Remove later
            commits = [Commit MR_findAllWithPredicate:predicate inContext:context];
            NSLog(@"After deleting, there is %d commit left", commits.count);
            
            NSMutableArray *shaArray = [NSMutableArray array];
            for (NSDictionary *dict in response) {
                NSString *sha = [dict valueForKey:@"sha"];
                
                // Check the sha and only add the commit if it's unique.
                //@TODO somehow the number of commits in response is doubled
                // everytime fetchCommits: is called. Check it out.
                if (sha
                    && ! [sha isKindOfClass:[NSNull class]]
                    && [sha length] > 0
                    && ! [shaArray containsObject:sha]) {
                    [shaArray addObject:sha];
                    
                    Commit *commit = [Commit MR_createInContext:context];
                    commit.repoId = self.repo.repoId;
                    commit.sha = sha;
                    
                    NSDictionary *commitDict = [dict valueForKey:@"commit"];
                    NSDictionary *authorDict = [commitDict valueForKey:@"author"];
                    NSString *createdDateString = [authorDict valueForKey:@"date"];
                    commit.createdDate = [Utils dateFromGithubDateString:createdDateString];
                } else {
                    NSLog(@"See, there are duplicated commits. SHA: %@", sha);
                }
            }
            
            [context MR_saveToPersistentStoreAndWait];
            
            //@TODO test. Remove later
            commits = [Commit MR_findAllWithPredicate:predicate inContext:context];
            NSLog(@"After inseting, there is %d commit left", commits.count);
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^() {
                [SVProgressHUD showErrorWithStatus:@"Failed to get some commits."];
            });
        }];
        
        //@TODO test. Remove later.
        counter ++;
    }
    
    //@TODO test. Remove later.
    NSLog(@"Fetch commits %d times", counter);
    commits = [Commit MR_findByAttribute:@"repoId" withValue:self.repo.repoId inContext:context];
    NSLog(@"--------------Total %d of commits in repo %@", commits.count, self.repo.fullName);
}

- (NSArray *)commitsFromDate:(NSDate *)startDate toDate:(NSDate *)lastDate {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(repoId = %d) AND (createdDate >= %@) AND (createdDate <= %@)", [self.repo.repoId intValue], startDate, lastDate];
    NSArray *commits = [Commit MR_findAllWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
    return commits;
}

- (NSArray *)commitsForSelectedDate {
    NSDate *selectedDate = self.monthView.dateSelected;
    if (!selectedDate) {
        return nil;
    }
    
    NSDate *startOfSelectedDate = [Utils startOfDate:selectedDate];
    NSDate *endOfSelectedDate = [Utils startOfOneDayAfter:selectedDate];
    
    NSArray *commits = [self commitsFromDate:startOfSelectedDate toDate:endOfSelectedDate];
    return commits;
}

#pragma mark Pull requests

- (void)fetchOpenPullRequests {
    [self showStatusWithMessage:@"Loading open pull requests..." andManuallyHide:YES];
    [self fetchPullRequestsWithState:UAGithubIssueOpenState];
}

- (void)fetchClosedPullRequests {
    [self showStatusWithMessage:@"Loading closed pull requests..." andManuallyHide:YES];
    [self fetchPullRequestsWithState:UAGithubIssueClosedState];
}

- (void)fetchPullRequestsWithState:(NSString *)state {
    NSDictionary *params = @{@"state": state};
    
    [self.engine pullRequestsForRepository:self.repo.fullName withParameters:params success:^(id response) {
        NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
        // For now, just delete all PRs first
        [PullRequest MR_truncateAll];
        
        for (NSDictionary *prDict in response) {
            //@TODO may check and ignore if either authorLogin or mergedBylogin is this user.
            
            //@TODO sometimes there is a commit infor in pull requests list???
            NSString *createdDate = [prDict valueForKey:@"created_at"];
            if (!createdDate
                || [createdDate isKindOfClass:[NSNull class]]
                || [createdDate length] == 0) {
                continue;
            }

            PullRequest *pr = [PullRequest MR_createInContext:context];
            pr.repoId = self.repo.repoId;
            pr.state = [prDict valueForKey:@"state"];
            
            pr.createdDate = [Utils dateFromGithubDateString:createdDate];
            
            NSDictionary *userDict = [prDict valueForKey:@"user"];
            pr.authorLogin = [userDict valueForKey:@"login"];
            
            if ([UAGithubIssueClosedState isEqualToString:pr.state]) {
                NSString *mergedAt = [prDict valueForKey:@"merged_at"];
                //@TODO what to do when PRs are closed but not merged? still wanna log?
                //@TODO move to Utils that check empty NSString
                if (mergedAt
                    && ![mergedAt isKindOfClass:[NSNull class]]
                    && [mergedAt length] > 0) {
                    pr.mergedDate = [Utils dateFromGithubDateString:mergedAt];
                }
                //@TODO: send request to get a single pull request for merged_by infor.
            }
        }
        
        [context MR_saveToPersistentStoreAndWait];
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            [SVProgressHUD showErrorWithStatus:@"Failed to load open pull requests."];
        });
    }];
}

- (NSArray *)pullRequestsOpenedByUserFromDate:(NSDate *)startDate toDate:(NSDate *)lastDate {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(repoId = %d) AND (authorLogin = %@) AND (createdDate >= %@) AND (createdDate <= %@)", [self.repo.repoId intValue], self.engine.username, startDate, lastDate];
    NSArray *prs = [PullRequest MR_findAllWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
    return prs;
}

- (NSArray *)pullRequestsOpenedByUserForSelectedDate {
    NSDate *selectedDate = self.monthView.dateSelected;
    if (!selectedDate) {
        return nil;
    }
    
    NSDate *startOfSelectedDate = [Utils startOfDate:selectedDate];
    NSDate *endOfSelectedDate = [Utils startOfOneDayAfter:selectedDate];
    
    NSArray *prs = [self pullRequestsOpenedByUserFromDate:startOfSelectedDate toDate:endOfSelectedDate];
    return prs;
}

@end
