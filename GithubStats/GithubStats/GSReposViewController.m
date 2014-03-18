//
//  GSReposViewController.m
//  GithubStats
//
//  Created by Huy Nguyen on 2/15/13.
//  Copyright (c) 2013 Huy Nguyen. All rights reserved.
//

#import "GSReposViewController.h"
#import "Repo.h"
#import "Commit.h"
#import "GSRepoCell.h"
#import "UAGithubEngine.h"
#import "NSString+UAGithubEngineUtilities.h"
#import "GSCalendarViewController.h"

@interface GSReposViewController ()
- (void)updateCell:(GSRepoCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)fetchUserRepos;
- (void)fetchOrgsRepos;
- (void)fetchReposForOrg:(NSString *)org;
- (void)saveReposFromResponse:(id)response;
- (void)onFinishedFetchingReposWithSuccess:(BOOL)success andError:(NSError *)error;
@end

@implementation GSReposViewController

+ (GSReposViewController *)newInstanceWithEngine:(UAGithubEngine *)engine {
    GSReposViewController *instance = [[GSReposViewController alloc] initWithNibName:NIB_REPOS_VIEW_CONTROLLER bundle:nil];
    instance.engine = engine;
    return instance;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Fetch Repos from CoreData
    NSError *error;
    if (![[self fetchedResultsController] performFetch:&error]) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }
    
    [self.tableView registerClass:[GSRepoCell class] forCellReuseIdentifier:IDENTIFIER_REPO_CELL];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    // For now, always refresh repos
    //@TODO should have a better way to determine whether to refresh here or not
    [self.refreshControl beginRefreshing];
    [self refresh];
}

- (void)dealloc {
    self.fetchedResultsController.delegate = nil;
    self.fetchedResultsController = nil;
}

#pragma mark - Setters

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [Repo MR_requestAllSortedBy:@"fullName" ascending:NO];
    [fetchRequest setFetchBatchSize:20];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[NSManagedObjectContext MR_contextForCurrentThread] sectionNameKeyPath:nil cacheName:@"Root"];
    _fetchedResultsController.delegate = self;
    return _fetchedResultsController;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GSRepoCell *cell = [tableView dequeueReusableCellWithIdentifier:IDENTIFIER_REPO_CELL forIndexPath:indexPath];
    [self updateCell:cell atIndexPath:indexPath];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Repo *repo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    GSCalendarViewController *controller = [GSCalendarViewController newInstanceWithEngine:self.engine andRepo:repo];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Fetched results controller delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self updateCell:(GSRepoCell *)[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:sectionIndex];
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:sections withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:sections withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - Instance methods

- (void)updateCell:(GSRepoCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Repo *repo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [cell updateViewWithRepo:repo andIndexPath:indexPath];
}

- (void)refresh {
    // Getting and parsing repos block, so do it in background thread.
    // Then get back to main thread and update view (handled by onFinishedRefreshingWithSuccess:andError).
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^() {
        // Clear existing objects first.
        [Repo MR_truncateAll];
        [Commit MR_truncateAll];

        [self fetchUserRepos];
        [self fetchOrgsRepos];
        
        [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error){
            [self onFinishedFetchingReposWithSuccess:success andError:error];
        }];
    });
}

- (void)fetchUserRepos {
    [self.engine repositoriesWithSuccess:^(id response) {
        [self saveReposFromResponse:response];
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            [SVProgressHUD showErrorWithStatus:@"Failed to get user repositories."];
        });
    }];
}

- (void)fetchOrgsRepos {
    // Fetch user orgs first
    [self.engine organizationsForUser:self.engine.username success:^(id response){
        for (NSDictionary *dict in response) {
            [self fetchReposForOrg:[dict objectForKey:@"login"]];
        }
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            [SVProgressHUD showErrorWithStatus:@"Failed to get organizations"];
        });
    }];
}

- (void)fetchReposForOrg:(NSString *)org {
    [self.engine repositoriesForOrganization:org withSuccess:^(id response){
        [self saveReposFromResponse:response];
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Failed to get repositories of %@", org]];
        });
    }];
}

- (void)saveReposFromResponse:(id)response {
    // Got repos, let's save them to CoreData.
    // Response is an array dicts. Each dict has infor of a Repo.
    //@TODO handle 0 repo
    for (NSDictionary *dict in response) {
        Repo *repo = [Repo MR_createEntity];
        repo.repoId = [dict objectForKey:@"id"];
        repo.fullName = [dict objectForKey:@"full_name"];
        repo.updatedDate = [[dict objectForKey:@"updated_at"] dateFromGithubDateString];
        repo.createdDate = [[dict objectForKey:@"created_at"] dateFromGithubDateString];
    }
}

// This method can be called from backgorund thread, so make sure it dispatches to main thread.
// It's unnecessary to reload table view, since fetchedResultsController observer data changes and call the delegate.
- (void)onFinishedFetchingReposWithSuccess:(BOOL)success andError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^() {
        if (!success && error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        }
        
        [self.refreshControl endRefreshing];
    });
}

@end
