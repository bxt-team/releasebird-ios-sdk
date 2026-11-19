#import <Foundation/Foundation.h>

@interface Config : NSObject

+ (NSString *)baseURL;
+ (NSString *)contentUrl;

/// For testing against another environment (e.g. a local backend). Pass nil to reset.
+ (void)setBaseURL:(NSString *)baseURL;
+ (void)setContentUrl:(NSString *)contentUrl;

@end
