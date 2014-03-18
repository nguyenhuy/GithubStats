//
//  Utils.m
//  GithubStats
//
//  Created by Huy Nguyen on 2/15/13.
//  Copyright (c) 2013 Huy Nguyen. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (BOOL)isStringEmpty:(id)string {
    return !string
    || ![string isKindOfClass:[NSString class]]
    || ((NSString *)string).length == 0;
}

+ (NSDateFormatter *)defaultDateFormatter {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setTimeStyle:NSDateFormatterMediumStyle];
    });
    return formatter;
}

+ (NSString *)stringFromDate:(NSDate *)date {
    return [[Utils defaultDateFormatter] stringFromDate:date];
}

+ (int)numberOfDaysBetween:(NSDate *)startDate and:(NSDate *)endDate {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps = [calendar components:NSDayCalendarUnit fromDate:startDate toDate:endDate options:0];
    return comps.day;
}

+ (NSDateFormatter *)githubDateFormatter {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    });
    return formatter;
}

+ (NSString *)githubDateStringFromDate:(NSDate *)date {
    return [[Utils githubDateFormatter] stringFromDate:date];
}

+ (NSDate *)dateFromGithubDateString:(NSString *)dateString {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    
    if (![[dateString substringWithRange:NSMakeRange([dateString length] - 1, 1)] isEqualToString:@"Z"])
    {
        NSMutableString *newDate = [self mutableCopy];
        [newDate deleteCharactersInRange:NSMakeRange(19, 1)];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];
        dateString = newDate;
    }
    else
    {
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    }
    
    return [df dateFromString:dateString];
}

+ (NSDate *)startOfDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
    return [calendar dateFromComponents:comps];
}

+ (NSDate *)dateByAddingDays:(int)days toDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
    comps.day += days; // no worries: even if it is the end of the month it will wrap to the next month, see doc
    return [calendar dateFromComponents:comps];
}

+ (NSDate *)startOfOneDayAfter:(NSDate *)date {
    return [Utils dateByAddingDays:1 toDate:date];
}

+ (NSDate *)startOfMonth:(NSDate *)date {
    date = [Utils startOfDate:date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:date];
    return [calendar dateFromComponents:comps];
}

+ (NSDate *)endOfMonth:(NSDate *)date {
    // Steps:
    // Get start of month
    // Get start of next month
    // Substract 1 second to get end of month

    date = [Utils startOfDate:date];
    NSDate *startOfMonth = [Utils startOfMonth:date];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *addOneMonth = [[NSDateComponents alloc] init];
    [addOneMonth setMonth:1];
    NSDate *startOfNextMonth = [calendar dateByAddingComponents:addOneMonth toDate:startOfMonth options:0];
    
    NSDate *endOfMonth = [startOfNextMonth dateByAddingTimeInterval:-1];
    return endOfMonth;
}

@end
