#import <Foundation/Foundation.h>
#import "Config.h"

static NSString *rbBaseURL = nil;
static NSString *rbContentUrl = nil;

@implementation Config

+ (NSString *)baseURL {
    return rbBaseURL ?: @"https://api.releasebird.com/papi";
}

+ (NSString *)contentUrl {
    return rbContentUrl ?: @"https://wcontent.releasebird.com";
}

+ (void)setBaseURL:(NSString *)baseURL {
    rbBaseURL = [baseURL copy];
}

+ (void)setContentUrl:(NSString *)contentUrl {
    rbContentUrl = [contentUrl copy];
}

@end
