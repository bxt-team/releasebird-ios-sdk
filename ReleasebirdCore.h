#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReleasebirdCore : NSObject

+ (instancetype)sharedInstance;

- (NSString *) getAIValue;

@property (nonatomic, retain) NSString *apiKey;

@property (nonatomic, retain) NSDictionary *widgetSettings;

@end
NS_ASSUME_NONNULL_END
