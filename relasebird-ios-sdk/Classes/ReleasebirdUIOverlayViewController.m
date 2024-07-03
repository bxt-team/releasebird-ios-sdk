#import "ReleasebirdUIOverlayViewController.h"
#import "ReleasebirdOverlayUtils.h"
#import "ReleasebirdFrameViewController.h"
#import "ReleasebirdUtils.h"

@interface ReleasebirdUIOverlayViewController ()

@end

@implementation ReleasebirdUIOverlayViewController

- (UIWindow *)getKeyWindow {
    UIWindow *keyWindow = nil;
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (window.isKeyWindow) {
            keyWindow = window;
            break;
        }
    }
    return keyWindow;
}

- (void)initializeUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [self getKeyWindow];
        if (keyWindow != nil) {
            self.internalNotifications = [[NSMutableArray alloc] init];
            self.notificationViews = [[NSMutableArray alloc] init];
            
            // Render feedback button.
            self.feedbackButton = [[ReleasebirdButton alloc] initWithFrame: CGRectMake(0, 0, 54.0, 54.0)];
            [keyWindow addSubview: self.feedbackButton];
            self.feedbackButton.layer.zPosition = INT_MAX;
            [self.feedbackButton configure];
            [self.feedbackButton setUserInteractionEnabled: YES];
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
            [self.feedbackButton addGestureRecognizer:tapGestureRecognizer];
        
        }
    });
}

- (void)imageTapped:(UITapGestureRecognizer *)gestureRecognizer {
    [self showWidget];
}

- (void)bringViewToFront:(UIView *)view {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (view != nil && view.superview != nil) {
            [view.superview bringSubviewToFront: view];
        }
    });
}

- (void)showWidget {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Pre widget open hook.
      
        self.rbirdWidget = [[ReleasebirdFrameViewController alloc] initWithFormat: @""];
        self.rbirdWidget.view.hidden = false;
        self.rbirdWidget.modalPresentationStyle = UIModalPresentationFullScreen;
    
    
        // Show on top of all viewcontrollers.
        UIViewController *topMostViewController = [ReleasebirdUtils getTopMostViewController];
        if (topMostViewController != nil) {
            [topMostViewController presentViewController:self.rbirdWidget animated:true completion:^{
                NSLog(@"callback");
            }];
        }
    });
}

- (void)updateUIPositions {
    [self bringViewToFront: self.feedbackButton];
}


- (void)updateUI {
    [self.feedbackButton refreshVisibility];
}


@end
