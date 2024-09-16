#import <Foundation/Foundation.h>
#import "Config.h"

@implementation Config

+ (NSString *)baseURL {
    #if DEBUG
    return @"https://api.releasebird.com/papi";
    #elif RELEASE
    return @"https://api.releasebird.com/papi";
    #else
    return @"https://api.releasebird.com/papi";
    #endif
}

+ (NSString *)contentUrl {
    #if DEBUG
    return @"https://wcontent.releasebird.com";
    #elif RELEASE
    return @"https://wcontent.releasebird.com";
    #else
    return @"https://wcontent.releasebird.com";
    #endif
}

@end
