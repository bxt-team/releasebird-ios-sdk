#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReleasebirdButton : UIView

@property (nonatomic, retain) UIImageView *logoView;

- (void)configure;
- (void)refreshVisibility;

- (void)showBadge;
- (void)hideBadge;
- (void) setBadgeText:(NSString *)value;

@property (nonatomic, assign) bool initialized;
@property (nonatomic, assign) bool showButton;
@property (nonatomic, retain) NSString *currentButtonUrl;
@property (strong, nonatomic) NSLayoutConstraint *safeAreaConstraint;
@property (strong, nonatomic) NSLayoutConstraint *edgeConstraint;
@property (strong, nonatomic) NSString *feedbackButtonPosition;


@property (nonatomic, retain) UIView *notificationBadgeView;
@property (nonatomic, retain) UILabel *notificationBadgeLabel;


@end

NS_ASSUME_NONNULL_END
