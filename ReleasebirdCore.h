#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReleasebirdCore : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, retain) NSString *apiKey;

@end
NS_ASSUME_NONNULL_END
