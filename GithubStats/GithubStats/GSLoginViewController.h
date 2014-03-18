//
//  GSLoginViewController.h
//  GithubStats
//
//  Created by Huy Nguyen on 2/15/13.
//  Copyright (c) 2013 Huy Nguyen. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NIB_LOGIN_VIEW_CONTROLLER @"GSLoginViewController"

@interface GSLoginViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *lblUsername;
@property (strong, nonatomic) IBOutlet UITextField *lblPassword;

+ (GSLoginViewController *)newInstance;

- (void)login;

@end
