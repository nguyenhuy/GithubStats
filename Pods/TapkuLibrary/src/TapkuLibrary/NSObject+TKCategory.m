//
//  NSObject+TKCategory.m
//  Created by Devin Ross on 12/29/12.
//
/*
 
 tapku.com || http://github.com/devinross/tapkulibrary
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "NSObject+TKCategory.h"


#define VALID_OBJECT(_OBJ) _OBJ &&	(id)_OBJ != [NSNull null] && ((![_OBJ isKindOfClass:[NSString class]]) || [(NSString*)_OBJ length] > 0)


@implementation NSObject (TKCategory)


+ (NSDictionary*) dataKeys{
	return [NSDictionary dictionary];
}


+ (id) createObject:(NSDictionary*)data{
	return [[[self class] alloc] initWithDataDictionary:data];
}
- (id) initWithDataDictionary:(NSDictionary*)dictionary{
	if(!(self=[self init])) return nil;
	[self importDataWithDictionary:dictionary];
	return self;
}
- (void) importDataWithDictionary:(NSDictionary*)dictionary{
	
	
	NSDateFormatter *formatter = nil;
	NSDictionary *dataKeys = [[self class] dataKeys];
	
	for(NSString *dataKey in [dataKeys allKeys]){
		
		id value = [dataKeys objectForKey:dataKey];
		
		if([value isKindOfClass:[NSString class]]){
			
			id obj = [dictionary objectForKey:[dataKeys objectForKey:dataKey]];
			if(VALID_OBJECT(obj)) [self setValue:obj forKey:dataKey];
			
		}else if([value isKindOfClass:[NSArray class]]){
			
			NSString *format = [value lastObject];
			NSString *key = [value firstObject];
			
			if(VALID_OBJECT(format) && VALID_OBJECT(key)){
				if(!formatter) formatter = [[NSDateFormatter alloc] init];
				[formatter setDateFormat:format];
				NSDate *date = [formatter dateFromString:[dictionary objectForKey:key]];
				[self setValue:date forKey:dataKey];
			}
			
		}
		
	}
	
}



#pragma mark - PROCESS JSON IN THE BACKGROUND

- (void) processJSONDataInBackground:(NSData *)data withCallbackSelector:(SEL)callback{
	
	[self processJSONDataInBackground:data
				 withCallbackSelector:callback
				   backgroundSelector:nil
						errorSelector:nil
					   readingOptions:0];
	
}

- (void) processJSONDataInBackground:(NSData *)data withCallbackSelector:(SEL)callback readingOptions:(NSJSONReadingOptions)options{
	
	[self processJSONDataInBackground:data
				 withCallbackSelector:callback
				   backgroundSelector:nil
						errorSelector:nil
					   readingOptions:options];
	
}

- (void) processJSONDataInBackground:(NSData *)data withCallbackSelector:(SEL)callback backgroundSelector:(SEL)backgroundProcessor readingOptions:(NSJSONReadingOptions)options{
	
	[self processJSONDataInBackground:data
				 withCallbackSelector:callback
				   backgroundSelector:backgroundProcessor
						errorSelector:nil
					   readingOptions:options];
	
}

- (void) processJSONDataInBackground:(NSData *)data withCallbackSelector:(SEL)callback backgroundSelector:(SEL)backgroundProcessor errorSelector:(SEL)errroSelector{
	
	[self processJSONDataInBackground:data
				 withCallbackSelector:callback
				   backgroundSelector:backgroundProcessor
						errorSelector:errroSelector
					   readingOptions:0];
	
}


- (void) processJSONDataInBackground:(NSData *)data
				withCallbackSelector:(SEL)callback
				  backgroundSelector:(SEL)backgroundProcessor
					   errorSelector:(SEL)errroSelector
					  readingOptions:(NSJSONReadingOptions)options{
	
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[dict setObject:data forKey:@"data"];
	[dict setObject:[NSNumber numberWithUnsignedInt:options] forKey:@"flags"];
	
	if(callback) [dict setObject:NSStringFromSelector(callback) forKey:@"callback"];
	if(backgroundProcessor) [dict setObject:NSStringFromSelector(backgroundProcessor) forKey:@"backgroundProcessor"];
	if(errroSelector) [dict setObject:NSStringFromSelector(errroSelector) forKey:@"errroSelector"];
	
	
	[self performSelectorInBackground:@selector(_processJSONData:) withObject:dict];
	
	
}


- (void) _processJSONData:(NSDictionary*)dict{
	@autoreleasepool {
		NSError *error = nil;
		
		NSData *data = [dict objectForKey:@"data"];
		NSUInteger options = [[dict objectForKey:@"flags"] unsignedIntValue];
		
		NSString *callback = [dict objectForKey:@"callback"];
		NSString *background = [dict objectForKey:@"backgroundProcessor"];
		NSString *eSelector = [dict objectForKey:@"errroSelector"];
		
		id object = [NSJSONSerialization JSONObjectWithData:data options:options error:&error];
		
		
		
		if(error){
			if(eSelector) [self performSelector:NSSelectorFromString(eSelector) withObject:error];
		}else{
			if(background) object = [self performSelector:NSSelectorFromString(background) withObject:object];
			[self performSelectorOnMainThread:NSSelectorFromString(callback) withObject:object waitUntilDone:NO];
		}
		
		
	}
}




@end
