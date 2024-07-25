#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ReleasebirdFrameViewController.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Releasebird : UIView

+ (instancetype)sharedInstance;

- (void)showButton:(NSString *)key;

- (void)identify:(NSObject *)identifyJson;

@property (strong, nonatomic) NSLayoutConstraint *edgeConstraint;
@property (strong, nonatomic) NSLayoutConstraint *safeAreaConstraint;

@end
NS_ASSUME_NONNULL_END
