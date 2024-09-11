#import <UIKit/UIKit.h>
#import "ReleasebirdButton.h"
#import "ReleasebirdFrameViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReleasebirdUIOverlayViewController : NSObject

- (void)updateUI;
- (void)initializeUI;
- (void)updateUIPositions;
- (void)showWidget;

@property (nonatomic, retain) NSMutableArray *internalNotifications;
@property (nonatomic, retain) ReleasebirdButton *feedbackButton;
@property (nonatomic, retain, nullable) ReleasebirdFrameViewController *rbirdWidget;

@property (nonatomic, retain) NSMutableArray *notificationViews;

@end

NS_ASSUME_NONNULL_END
