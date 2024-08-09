#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReleasebirdUtils : NSObject

+ (NSString *)getTopMostViewControllerName;
+ (UIViewController *)getTopMostViewController;
+ (UIViewController *)topViewControllerWith:(UIViewController *)rootViewController;
+ (UIColor *)colorFromHexString:(NSString *)hexString;
+ (NSString *)getJSStringForNSDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
