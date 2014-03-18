//
//  Utils.h
//  GithubStats
//
//  Created by Huy Nguyen on 2/15/13.
//  Copyright (c) 2013 Huy Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

+ (BOOL)isStringEmpty:(id)string;

+ (NSDateFormatter *)defaultDateFormatter;
+ (NSString *)stringFromDate:(NSDate *)date;
+ (int)numberOfDaysBetween:(NSDate *)startDate and:(NSDate *)endDate;

+ (NSDateFormatter *)githubDateFormatter;
+ (NSString *)githubDateStringFromDate:(NSDate *)date;
+ (NSDate *)dateFromGithubDateString:(NSString *)dateString;

// Returns the start of the date which is x days after the given date
// Input: next 7 days since Jan 11 2013, 3:45:25PM
// Output: Jan 18 2013, 0:00:00AM.
+ (NSDate *)dateByAddingDays:(int)days toDate:(NSDate *)date;
+ (NSDate *)startOfDate:(NSDate *)date;
+ (NSDate *)startOfOneDayAfter:(NSDate *)date;

+ (NSDate *)startOfMonth:(NSDate *)date;
+ (NSDate *)endOfMonth:(NSDate *)date;

@end
