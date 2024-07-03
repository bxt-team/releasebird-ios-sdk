#import <UIKit/UIKit.h>
#import "ReleasebirdButton.h"
#import "ReleasebirdFrameViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReleasebirdUIOverlayViewController : NSObject

- (void)setNotifications:(NSMutableArray *)notifications;
- (void)updateNotificationCount:(int)notificationCount;
- (void)updateUI;
- (void)initializeUI;
- (void)showBanner:(NSDictionary *)bannerData;
- (void)updateUIPositions;

@property (nonatomic, retain) NSMutableArray *internalNotifications;
@property (nonatomic, retain) ReleasebirdButton *feedbackButton;
@property (nonatomic, retain) UIView *notificationsContainerView;
@property (nonatomic, retain, nullable) ReleasebirdFrameViewController *rbirdWidget;

@property (nonatomic, retain) NSMutableArray *notificationViews;

@end

NS_ASSUME_NONNULL_END
