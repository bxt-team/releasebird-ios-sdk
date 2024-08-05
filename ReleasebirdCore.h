#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReleasebirdCore : NSObject

+ (instancetype)sharedInstance;

- (NSString *) getAIValue;

- (NSString *) getUnreadMessages;

- (NSDictionary *) getIdentifyState;

- (void)getUnreadCount;

@property (nonatomic, retain) NSString *apiKey;

@property (nonatomic, retain) NSDictionary *widgetSettings;

@end
NS_ASSUME_NONNULL_END
