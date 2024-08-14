#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ReleasebirdFrameViewController.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Releasebird : UIView

+ (instancetype)sharedInstance;

- (void)showButton;

- (void)hideButton;

- (void)initialize:(NSString *)key showButton:(BOOL *)show;;

- (void)identify:(NSObject *)identifyJson;

@property (strong, nonatomic) NSLayoutConstraint *edgeConstraint;
@property (strong, nonatomic) NSLayoutConstraint *safeAreaConstraint;

@property (nonatomic, weak) NSTimer *repeatingTimer;
@property (nonatomic, retain, nullable) NSTimer* timeoutTimer;

@end
NS_ASSUME_NONNULL_END
