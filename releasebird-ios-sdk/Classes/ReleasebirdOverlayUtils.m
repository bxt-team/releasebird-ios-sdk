#import "ReleasebirdOverlayUtils.h"
#import "ReleasebirdWindowUtils.h"
#import <UIKit/UIKit.h>
#import "ReleasebirdCore.h"

@implementation ReleasebirdOverlayUtils

/*
 Returns a shared instance (singleton).
 */
+ (instancetype)sharedInstance
{
    static ReleasebirdOverlayUtils *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ReleasebirdOverlayUtils alloc] init];
        [sharedInstance initializeUI];
    });
    return sharedInstance;
}

+ (void)updateUI {
    ReleasebirdWindowUtils *windowChecker = [[ReleasebirdWindowUtils alloc] init];
    [windowChecker waitForKeyWindowToBeReadyWithCompletion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ReleasebirdOverlayUtils sharedInstance].uiOverlayViewController updateUI];
        });
    }];
}

+ (void)clear {
    dispatch_async(dispatch_get_main_queue(), ^{
        ReleasebirdOverlayUtils *instance = [ReleasebirdOverlayUtils sharedInstance];
        if (instance.uiOverlayViewController != nil) {
            [instance.uiOverlayViewController updateUI];
        }
    });
}

+ (void)showFeedbackButton:(bool)show {
    if (show && [ReleasebirdOverlayUtils sharedInstance].hiddenByApp) {
        show = false;
    }
    if (show && ![ReleasebirdCore sharedInstance].noButton) {
        [ReleasebirdOverlayUtils sharedInstance].showButtonExternalOverwrite = YES;
        [ReleasebirdOverlayUtils sharedInstance].showButton = show;
    } else {
        [ReleasebirdOverlayUtils sharedInstance].showButtonExternalOverwrite = NO;
        [ReleasebirdOverlayUtils sharedInstance].showButton = show;
    }
  
    [ReleasebirdOverlayUtils updateUI];
}

+ (void)showWidget {
    // The overlay is created once the app's window is ready – wait for it instead of silently doing nothing
    ReleasebirdWindowUtils *windowChecker = [[ReleasebirdWindowUtils alloc] init];
    [windowChecker waitForKeyWindowToBeReadyWithCompletion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ReleasebirdOverlayUtils sharedInstance].uiOverlayViewController showWidget];
        });
    }];
}

- (void)initializeUI {
    self.showButton = NO;
    self.showButtonExternalOverwrite = NO;
    
    ReleasebirdWindowUtils *windowChecker = [[ReleasebirdWindowUtils alloc] init];
    [windowChecker waitForKeyWindowToBeReadyWithCompletion:^{
       dispatch_async(dispatch_get_main_queue(), ^{
           self.uiOverlayViewController = [[ReleasebirdUIOverlayViewController alloc] init];
           [self.uiOverlayViewController initializeUI];
       });
    }];
}

@end
