#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReleasebirdCore : NSObject

+ (instancetype)sharedInstance;

- (nullable NSString *) getAIValue;

- (nullable NSString *) getUnreadMessages;

- (nullable NSDictionary *) getIdentifyState;

- (void)getUnreadCount;

/// A string from the widget settings, or nil if it is missing or not a string (the server may send null).
- (nullable NSString *)stringSetting:(NSString *)key;

/// A number from the widget settings, or the fallback.
- (float)floatSetting:(NSString *)key fallback:(float)fallback;

@property (nonatomic, retain, nullable) NSString *apiKey;

@property (nonatomic, assign) BOOL noButton;

@property (nonatomic, retain, nullable) NSDictionary *widgetSettings;

@end

NS_ASSUME_NONNULL_END
