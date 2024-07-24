#import <Foundation/Foundation.h>
#import "Config.h"

@implementation Config

+ (NSString *)baseURL {
    #if DEBUG
    return @"http://localhost:8040/papi";
    #elif RELEASE
    return @"https://api.releasebird.com/papi";
    #else
    return @"https://api.releasebird.com/papi";
    #endif
}

+ (NSString *)contentUrl {
    #if DEBUG
    return @"http://localhost:4001";
    #elif RELEASE
    return @"https://wcontent.releasebird.com";
    #else
    return @"https://wcontent.releasebird.com";
    #endif
}

@end
