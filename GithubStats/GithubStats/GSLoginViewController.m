//
//  GSLoginViewController.m
//  GithubStats
//
//  Created by Huy Nguyen on 2/15/13.
//  Copyright (c) 2013 Huy Nguyen. All rights reserved.
//

#import "GSLoginViewController.h"
#import "SVProgressHUD.h"
#import "UAGithubEngine.h"
#import "GSReposViewController.h"

@interface GSLoginViewController ()

@end

@implementation GSLoginViewController

+ (GSLoginViewController *)newInstance {
    return [[GSLoginViewController alloc] initWithNibName:NIB_LOGIN_VIEW_CONTROLLER bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup bar button item
    UIBarButtonItem *loginItem = [[UIBarButtonItem alloc] initWithTitle:@"Login" style:UIBarButtonItemStylePlain target:self action:@selector(login)];
    self.navigationItem.rightBarButtonItem = loginItem;
    
    [self.lblUsername becomeFirstResponder];
}

#pragma mark - Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.lblUsername) {
        [self.lblPassword becomeFirstResponder];
    } else if (textField == self.lblPassword) {
        [self login];
    }
    return YES;
}

#pragma mark - Instance methods

- (void)login {
    [SVProgressHUD show];
    
    NSString *username = self.lblUsername.text;
    NSString *password = self.lblPassword.text;
    
    if ([Utils isStringEmpty:username] || [Utils isStringEmpty:password]) {
        [SVProgressHUD showErrorWithStatus:@"Incorrect username or password."];
        return;
    }
    
    // Hide keyboard
    [self.view endEditing:YES];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^(){
        UAGithubEngine *engine = [[UAGithubEngine alloc] initWithUsername:username password:password withReachability:YES];
        
        [engine userWithSuccess:^(id response) {
            NSDictionary *dict = [(NSArray *)response objectAtIndex:0];
            NSString *name = [dict objectForKey:@"name"];
            NSString *displayName = [Utils isStringEmpty:name] ? username : name;
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"Hello %@", displayName]];
                
                UIViewController *controller = [GSReposViewController newInstanceWithEngine:engine];
                [self.navigationController pushViewController:controller animated:YES];
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(){
                [SVProgressHUD showErrorWithStatus:error.localizedDescription];
            });
        }];
    });
}

@end
